#Set a cutoff date because every activesync device ever registered to the tenant will show up
$CutoffDate = (get-date).AddDays(-365).Date

#Get devices that have contacted ActiveSync since the cutoff date and dump to a CSV
Get-MobileDevice -ResultSize Unlimited | Where-Object { (($_.WhenChanged).Date -gt $CutoffDate) -and ($_.UserDisplayName -notlike "*NAMPR05A004*")} | Export-Csv .\ActiveSync_Devices.csv

