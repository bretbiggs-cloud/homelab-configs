# Apply explicitly reviewed title/year overrides, never fuzzy matches.
# Input is a private JSON array of Id, Title, Year, Reason; optional Tmdb selects a
# specifically reviewed same-title adaptation. Optional FinalYear/PremiereDate
# preserves an independently sourced premiere date after provider identification.
# Snapshots/results are private. No media filesystem changes or credentials in repo.
param([Parameter(Mandatory=$true)][string]$OverrideFile)
. "$PSScriptRoot/Repair-JellyfinMovieMetadata.ps1" -FunctionsOnly
$all=Get-Content "$private/movie-metadata-audit-before.json" -Raw|ConvertFrom-Json
$overrides=Get-Content $OverrideFile -Raw|ConvertFrom-Json
foreach($entry in $overrides){
 $item=$all.Items|Where-Object Id -eq $entry.Id
 $r=[ordered]@{Id=$entry.Id;OriginalName=$item.Name;Title=$entry.Title;Year=$entry.Year;Tmdb=$null;Status=''}
 try{
  if(!$item -or !$entry.Reason -or !$entry.Year){throw 'Incomplete reviewed override'}
  $live=Api "/Items/$($entry.Id)"
  if($live.ProviderIds.Tmdb -and (!$entry.ExpectedOldTmdb -or $live.ProviderIds.Tmdb -ne $entry.ExpectedOldTmdb)){continue}
  $found=Api '/Items/RemoteSearch/Movie' 'Post' @{ItemId=$entry.Id;SearchProviderName='TheMovieDb';SearchInfo=@{Name=$entry.Title;Year=$entry.Year;MetadataLanguage='en';MetadataCountryCode='US'}}
  $exact=@($found|Where-Object {$_.ProductionYear -eq $entry.Year -and (Normalize $_.Name) -eq (Normalize $entry.Title) -and (!$entry.Tmdb -or $_.ProviderIds.Tmdb -eq $entry.Tmdb)}|Sort-Object {$_.ProviderIds.Tmdb} -Unique)
  if($exact.Count -ne 1 -or !$exact[0].ProviderIds.Tmdb){$r.Status='Review-Override-unconfirmed'}
  else{
   $r.Tmdb=$exact[0].ProviderIds.Tmdb
   $live|ConvertTo-Json -Depth 50|Set-Content "$work/$($entry.Id)-before.json"
   Api "/Items/RemoteSearch/Apply/$($entry.Id)?replaceAllImages=true" 'Post' $exact[0]|Out-Null
   $after=Api "/Items/$($entry.Id)"
   if($after.ProviderIds.Tmdb -ne $r.Tmdb -or $after.Path -ne $item.Path){throw 'Post-apply verification failed'}
   if($entry.FinalYear -or $entry.NameSuffix){
    if($entry.FinalYear){$after.ProductionYear=[int]$entry.FinalYear}
    if($entry.NameSuffix){$after.Name=$after.Name+$entry.NameSuffix;$after.SortName=$after.Name;$r.Title=$after.Name}
    if($entry.PremiereDate){$after.PremiereDate=$entry.PremiereDate}
    Api "/Items/$($entry.Id)" 'Post' $after|Out-Null
    $check=Api "/Items/$($entry.Id)"
    if(($entry.FinalYear -and $check.ProductionYear -ne $entry.FinalYear) -or $check.Path -ne $item.Path -or ($entry.NameSuffix -and $check.Name -ne $after.Name)){throw 'Reviewed release-year update failed'}
    if($entry.FinalYear){$r.Year=$entry.FinalYear}
   }
   $r.Status='Identified'
  }
 }catch{$r.Status='Error';$r.Error=$_.Exception.Message}
 $r|ConvertTo-Json -Compress|Add-Content "$work/results-reviewed.jsonl"
 $r|ConvertTo-Json -Compress|Write-Output
}
