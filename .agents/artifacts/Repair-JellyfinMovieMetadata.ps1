# Repair clearly identifiable Jellyfin movie metadata without renaming media.
# Usage: ./Repair-JellyfinMovieMetadata.ps1 [-Limit 0] [-Apply] [-Shard 0|1 -ShardCount 2]
# Requires the private baseline audit/session and reachable new Jellyfin. FunctionsOnly
# loads helper functions without processing items; reviewed repair uses this mode.
# Private snapshots/results live outside Git. Existing provider matches are retained;
# unmatched movies require one exact normalized title + exact year result from TMDb.
# Episode-like files, locked items and ambiguous searches are recorded for review.
param([int]$Limit=0,[switch]$Apply,[ValidateRange(0,1)][int]$Shard=0,[ValidateRange(1,2)][int]$ShardCount=1,[switch]$FunctionsOnly)
$ErrorActionPreference='Stop'
$private=Join-Path $env:USERPROFILE '.codex/private/homelab'
$work=Join-Path $private 'metadata-repair';New-Item -ItemType Directory -Path $work -Force|Out-Null
$secret=(Get-Content "$private/jellyfin-session.dpapi" -Raw).Trim()|ConvertTo-SecureString
$token=[Net.NetworkCredential]::new('',$secret).Password
$headers=@{Authorization=('MediaBrowser Token="'+$token+'", Client="Codex setup", Device="Windows", DeviceId="homelab-new-setup", Version="1.0"')}
$base='http://192.168.1.220:8097'
# Calls the configured Jellyfin API using the private session token. Path is a
# relative API route, Method defaults to GET, Body is serialized as JSON if given.
# GET reads server state; POST performs only the operation specified by its caller.
# Returns the decoded response and throws on HTTP failure or the45-second timeout.
function Api([string]$Path,[string]$Method='Get',$Body=$null){
 $httpParams=@{Uri="$base$Path";Headers=$headers;Method=$Method;TimeoutSec=45}
 if($null -ne $Body){$httpParams.ContentType='application/json';$httpParams.Body=$Body|ConvertTo-Json -Depth 40}
 Invoke-RestMethod @httpParams
}
# Normalize only punctuation, accents and ampersands; do not use fuzzy matching.
function Normalize([string]$Name){
 $n=$Name.ToLowerInvariant().Replace('&','and').Normalize([Text.NormalizationForm]::FormKD)
 $n=[regex]::Replace($n,'\p{Mn}','');[regex]::Replace($n,'[^a-z0-9]','')
}
# Derive title/year from explicit filename/folder text, ignoring release suffixes.
function Candidate($Item){
 $name=$Item.Name; $year=$Item.ProductionYear
 $name=$name -replace '^www\.\S+\s*-\s*',''
 $name=$name.Replace('_',' ')
 if($name -match '^((?:19|20)\d{2})\s*[-.]\s*(.+)$'){$year=[int]$Matches[1];$name=$Matches[2]}
 $name=$name -replace '^\d{1,2}[. ]+',''
 $name=$name -replace '\.(?=\D)',' '
 if($name -match '^(.*?)\s*[\(\[]((?:19|20)\d{2})[\)\]]'){$name=$Matches[1];$year=[int]$Matches[2]}
 $name=$name -replace '(?i)\s+(?:DVD\s*Rip|DVDRip|BluRay|BRRip|BDRip|WEB[ .-]?DL|WEBRip|HDRip|HDTV|1080p|720p|2160p|XviD|x264|x265|HEVC)\b.*$',''
 $name=$name -replace '(?i)\s*-\s*(?:Sci-Fi|Horror|Action|Family Comedy|Comedy Horror|Fantasy|IMAX)\b.*$',''
 $name=$name -replace '(?i)\s+(?:Directors Cut|Director.s Cut|Special Extended|Extended|Uncut|Unrated|DVD Rip)\s*$',''
 if($year){$name=$name -replace ('\s+\(?'+[regex]::Escape([string]$year)+'\)?\s*$'),''}
 if(!$year -or $year -gt (Get-Date).Year+1){
  $years=[regex]::Matches($Item.Path,'(?<!\d)(?:19\d{2}|20[0-2]\d)(?!\d)')|ForEach-Object {[int]$_.Value}|Select-Object -Unique
  if(@($years).Count -eq 1){$year=$years[0]}else{$year=$null}
 }
 @{Name=$name.Trim(' ','.','-','_');Year=$year}
}
if($FunctionsOnly){return}
$all=Get-Content "$private/movie-metadata-audit-before.json" -Raw|ConvertFrom-Json
$resultsPath=if($ShardCount -eq 1){"$work/results.jsonl"}else{"$work/results-$Shard.jsonl"};$done=@{}
Get-ChildItem "$work/results*.jsonl" -ErrorAction SilentlyContinue|ForEach-Object {Get-Content $_.FullName}|ForEach-Object {$r=$_|ConvertFrom-Json;if($r.Status -ne 'Error'){$done[$r.Id]=$true}}
$count=0
foreach($item in $all.Items){
 if(([Convert]::ToInt32($item.Id.Substring(0,2),16) % $ShardCount) -ne $Shard){continue}
 if($done.ContainsKey($item.Id)){continue}
 if($Limit -gt 0 -and $count -ge $Limit){break}
 $r=[ordered]@{Id=$item.Id;OriginalName=$item.Name;Status='';Title=$null;Year=$null;Tmdb=$null}
 try{
  if($item.Path -match '(?i)(s\d{1,2}[ ._-]*e\d{1,3}|season[ ._-]*\d|\d{1,2}x\d{2})'){$r.Status='Review-TV-in-movies'}
  elseif($item.LockData -or $item.LockedFields.Count){$r.Status='Review-Locked'}
  elseif($item.ProviderIds.Tmdb){
   $r.Tmdb=$item.ProviderIds.Tmdb
   if(!$item.Overview -or !$item.ImageTags.Primary -or !$item.ProductionYear){
    if($Apply){Api "/Items/$($item.Id)/Refresh?metadataRefreshMode=FullRefresh&imageRefreshMode=FullRefresh&replaceAllMetadata=false&replaceAllImages=false" 'Post'|Out-Null;$r.Status='Fill-missing-queued'}else{$r.Status='Would-fill-missing'}
   }else{$r.Status='Existing-match-retained'}
  }else{
   $candidate=Candidate $item;$r.Title=$candidate.Name;$r.Year=$candidate.Year
   if(!$candidate.Year -or !$candidate.Name){$r.Status='Review-No-reliable-year'}
   else{
    $query=@{SearchInfo=@{Name=$candidate.Name;Year=$candidate.Year;MetadataLanguage='en';MetadataCountryCode='US'};ItemId=$item.Id;SearchProviderName='TheMovieDb'}
    $found=Api '/Items/RemoteSearch/Movie' 'Post' $query
    $exact=@($found|Where-Object {$_.ProductionYear -eq $candidate.Year -and (Normalize $_.Name) -eq (Normalize $candidate.Name)}|Sort-Object {$_.ProviderIds.Tmdb} -Unique)
    if($exact.Count -eq 1 -and $exact[0].ProviderIds.Tmdb){
     $r.Tmdb=$exact[0].ProviderIds.Tmdb;$r.Title=$exact[0].Name
     if($Apply){
      $before=Api "/Items/$($item.Id)";$before|ConvertTo-Json -Depth 50|Set-Content "$work/$($item.Id)-before.json"
      Api "/Items/RemoteSearch/Apply/$($item.Id)?replaceAllImages=true" 'Post' $exact[0]|Out-Null
      $after=Api "/Items/$($item.Id)"
      if($after.ProviderIds.Tmdb -ne $r.Tmdb -or $after.Path -ne $item.Path){throw 'Post-apply ID or media path verification failed'}
      $r.Status='Identified'
     }else{$r.Status='Would-identify'}
    }else{$r.Status='Review-No-exact-match';$found|ConvertTo-Json -Depth 20|Set-Content "$work/$($item.Id)-candidates.json"}
    $count++;Start-Sleep -Milliseconds 300
   }
  }
 }catch{$r.Status='Error';$r.Error=$_.Exception.Message}
 if($Apply){$r|ConvertTo-Json -Compress|Add-Content $resultsPath}
 if($r.Status -in @('Identified','Would-identify','Error')){$r|ConvertTo-Json -Compress|Write-Output}
}
if(Test-Path $resultsPath){Get-Content $resultsPath|ForEach-Object {$_|ConvertFrom-Json}|Group-Object Status|Select-Object Name,Count|Format-Table -AutoSize}
