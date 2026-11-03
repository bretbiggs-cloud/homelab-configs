# Export the remaining unmatched entries for private review after repair.
# Does not change library state or media. Requires a fresh audit-after JSON.
$ErrorActionPreference='Stop'
$p=Join-Path $env:USERPROFILE '.codex/private/homelab'
$a=Get-Content "$p/movie-metadata-audit-after.json" -Raw|ConvertFrom-Json
$rows=foreach($i in $a.Items|Where-Object {!$_.ProviderIds.Tmdb -or ($_.RunTimeTicks -gt 0 -and $_.RunTimeTicks -lt 6000000000 -and $_.Path -notmatch '(?i)(s\d{1,2}[ ._-]*e\d{1,3}|season[ ._-]*\d|\d{1,2}x\d{2})')}){
 $reason=if($i.Path -match '(?i)(s\d{1,2}[ ._-]*e\d{1,3}|season[ ._-]*\d|\d{1,2}x\d{2})' -or $i.Name -like 'Planet.Earth.*'){'TV episode in Movies'}
 elseif($i.RunTimeTicks -gt 0 -and $i.RunTimeTicks -lt 6000000000){'Short clip or intro; review content'}
 elseif($i.Path -match '(?i)ufc|jake.paul.*tyson'){'Sporting event; separate identification'}
 elseif($i.Name -in @('enforcera','enforcerb','fafdm','fofdm','firefoxa','firefoxb','m-crheart-a','m-crheart-b','turkiso-whbha','turkiso-whbhb','pale.rb')){'Split or partial movie; preserve part identity'}
 else{'Needs individual identification'}
 [pscustomobject]@{Title=$i.Name;Year=$i.ProductionYear;Minutes=[math]::Round($i.RunTimeTicks/600000000,1);Reason=$reason;Path=$i.Path;Id=$i.Id}
}
$rows|Export-Csv "$p/metadata-repair/remaining-review.csv" -NoTypeInformation
$rows|Group-Object Reason|Select-Object Name,Count|ConvertTo-Json
