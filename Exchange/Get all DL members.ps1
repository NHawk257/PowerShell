Connect-ExchangeOnline

#Create the initial CSV file. Adjust Path/Name as needed
$csvfilename = ".\DL_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Owner,Members"

#Get all groups. Adjust as needed to filter or scope to an OU
#$Groups = Get-DistributionGroup | Select-Object -ExpandProperty PrimarySmtpAddress

foreach ($Group in $groups){

    #Get list of Owners and Members for each DL
    $Owner = Get-Group $Group.Alias | Select-Object -ExpandProperty Owners
    $Members = Get-Group $Group.Alias | Select-Object -ExpandProperty Members
    $Name = $Group.DisplayName

    #Add details to CSV, one line per group
    Add-Content $csvfilename "$Name,$owner,$members"

}