Connect-ExchangeOnline

$csvfilename = ".\DL_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Owner,Members"

$Groups = Get-DistributionGroup | Select-Object -ExpandProperty PrimarySmtpAddress

foreach ($Group in $groups){

$Owner = Get-DistributionGroup $Group | Select-Object -ExpandProperty ManagedBy
$members = Get-DistributionGroupMember $Group | Select-Object -ExpandProperty Name

Add-Content $csvfilename "$group,$owner,$members"

}