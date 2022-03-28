Connect-ExchangeOnline -DelegatedOrganization tundrasolutions.ca
#GET RID OF CLIENT INFORMATION IN SCRIPT

$csvfilename = ".\DL_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Owner,Members"

$Groups = Get-DistributionGroup -Filter 'EmailAddresses -Like "*@ssilift.com"' | Select -ExpandProperty PrimarySmtpAddress

foreach ($Group in $groups){

$Owner = Get-DistributionGroup $Group | select -ExpandProperty ManagedBy
$members = Get-DistributionGroupMember $Group | select -ExpandProperty Name

Add-Content $csvfilename "$group,$owner,$members"

}