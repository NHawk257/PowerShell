Connect-ExchangeOnline

#Create the initial CSV file. Adjust Path/Name as needed
$csvfilename = ".\DL_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Owner,Members"

#Get all groups. Adjust as needed to filter or scope to an OU
$Groups = Get-DistributionGroup -ResultSize Unlimited -WarningAction SilentlyContinue | Where-Object {$_.Name -like "*catrents*"} | Select-Object -ExpandProperty PrimarySmtpAddress
Write-Host $groups.count "groups found, starting report generation."

foreach ($Group in $groups){

    #Get list of Owners and Members for each DL
    $Owner = Get-DistributionGroup $Group | Select-Object -ExpandProperty ManagedBy
    $Members = Get-DistributionGroupMember $Group | Select-Object -ExpandProperty DisplayName
    $Name = Get-DistributionGroup $Group | Select-Object -ExpandProperty DisplayName

    #Add details to CSV, one line per group
    Add-Content $csvfilename "$Name,$owner,$members"

}