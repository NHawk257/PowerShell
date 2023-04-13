Connect-ExchangeOnline

$csvfilename = ".\Inactive_DGs.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,PrimarySMTP,Owner,Members"

#Get a message trace for the last 10 days of messages sent to a specific domain's DGs
$Search = Get-MessageTrace -Status Expanded -RecipientAddress *@4refuel.com -StartDate (Get-Date).AddDays(-10) -EndDate (Get-Date) | Select-Object received,recipientaddress,status
#Group messages by the address they were sent to
$Search = $Search | Group-Object recipientaddress | Select-Object name,count

$ActiveDL = $Search.name

#This WILL work as message traces will resolve to the primary SMTP first if a proxy is used and the Expand action is done with the primary SMTP in mind
$AllDLs = Get-DistributionGroup -ResultSize Unlimited -WarningAction SilentlyContinue | Where-Object {$_.PrimarySMTPAddress -like "*@4refuel.com"} | Select-Object -ExpandProperty PrimarySMTPAddress

#Compare the list of all DGs with the list of DGs we see in message tracking
$InactiveDGs = $AllDLs | Where-Object {$activeDL -notcontains $_}

#Dump details for all inactive DGs to a CSV for reporting
foreach ($DG in $InactiveDGs){

    #Get list of Owners and Members for each DL
    $Owner = Get-DistributionGroup $DG | Select-Object -ExpandProperty ManagedBy
    $Members = Get-DistributionGroupMember $DG | Select-Object -ExpandProperty Name
    $Name = Get-DistributionGroup $DG | Select-Object -ExpandProperty DisplayName

    #Add details to CSV, one line per group
    Add-Content $csvfilename "$Name,$DG,$owner,$members"

}