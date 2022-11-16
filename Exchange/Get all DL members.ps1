Connect-ExchangeOnline

#Create the initial CSV file. Adjust Path/Name as needed
$csvfilename = ".\DL_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Owner,Members"

#Get all groups. Adjust as needed to filter or scope to an OU
$Groups = Get-DistributionGroup | Select-Object -ExpandProperty PrimarySmtpAddress

foreach ($Group in $groups){

    #Get list of Owners and Members for each DL
    $Owner = Get-DistributionGroup $Group | Select-Object -ExpandProperty ManagedBy
    $Members = Get-DistributionGroupMember $Group | Select-Object -ExpandProperty Name

    #Add details to CSV, one line per group
    Add-Content $csvfilename "$group,$owner,$members"

}