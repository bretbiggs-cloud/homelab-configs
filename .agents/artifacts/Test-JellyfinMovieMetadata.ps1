# Read-only verification of the movie metadata repair and unchanged media paths.
# Usage: ./Test-JellyfinMovieMetadata.ps1
$ErrorActionPreference='Stop'
$p=Join-Path $env:USERPROFILE '.codex/private/homelab'
$secret=(Get-Content "$p/jellyfin-session.dpapi" -Raw).Trim()|ConvertTo-SecureString
$token=[Net.NetworkCredential]::new('',$secret).Password
$h=@{Authorization=('MediaBrowser Token="'+$token+'", Client="Codex setup", Device="Windows", DeviceId="homelab-new-setup", Version="1.0"')}
$before=Get-Content "$p/movie-metadata-audit-before.json" -Raw|ConvertFrom-Json
$after=Invoke-RestMethod 'http://192.168.1.220:8097/Items?Recursive=true&IncludeItemTypes=Movie&Fields=Path,ProviderIds,Overview&Limit=5000' -Headers $h -TimeoutSec 45
$after|ConvertTo-Json -Depth 30|Set-Content "$p/movie-metadata-audit-after.json"
$lookup=@{};foreach($i in $after.Items){$lookup[$i.Id]=$i}
foreach($i in $before.Items){if(!$lookup.ContainsKey($i.Id) -or $lookup[$i.Id].Path -ne $i.Path){throw "Movie removed or media path changed: $($i.Id)"}}
'PASS: Every original movie entry retained with its original media path'
$results=Get-ChildItem "$p/metadata-repair/results*.jsonl"|ForEach-Object {Get-Content $_.FullName}|ForEach-Object {$_|ConvertFrom-Json}
$identified=@($results|Where-Object Status -eq Identified|Sort-Object Id -Unique)
$issues=@()
foreach($r in $identified){$i=$lookup[$r.Id];if($i.ProviderIds.Tmdb -ne $r.Tmdb -or $i.ProductionYear -ne $r.Year -or !$i.Overview -or !$i.ImageTags.Primary){$issues+=[pscustomobject]@{Id=$r.Id;Name=$i.Name;Tmdb=$i.ProviderIds.Tmdb;Expected=$r.Tmdb;Year=$i.ProductionYear;ExpectedYear=$r.Year;HasOverview=[bool]$i.Overview;HasPoster=[bool]$i.ImageTags.Primary}}}
$issues|ConvertTo-Json -Depth 5|Set-Content "$p/metadata-repair/verification-issues.json"
[pscustomobject]@{TotalBefore=$before.TotalRecordCount;TotalAfter=$after.TotalRecordCount;Identified=$identified.Count;VerificationIssues=$issues.Count;MissingTmdbBefore=@($before.Items|Where-Object {!$_.ProviderIds.Tmdb}).Count;MissingTmdbAfter=@($after.Items|Where-Object {!$_.ProviderIds.Tmdb}).Count;MissingOverviewBefore=@($before.Items|Where-Object {!$_.Overview}).Count;MissingOverviewAfter=@($after.Items|Where-Object {!$_.Overview}).Count}|ConvertTo-Json
if($issues.Count){$issues|ConvertTo-Json -Depth 5;throw 'Metadata verification issues remain'}
'PASS: Identified movies have expected provider IDs, synopses and posters'
