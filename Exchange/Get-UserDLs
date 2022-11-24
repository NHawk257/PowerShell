#This is a one line script, don't reinvent the wheel...
$Mailbox = <PrimarySMTPAddress Here>
$DN = (get-mailbox $Mailbox).distinguishedname
$Filters = "Members -Like ""$DN"""

Get-DistributionGroup -ResultSize Unlimited -Filter $Filters | Select-Object Name,GroupType,PrimarySMTPAddress,ManagedBy,IsDirSynced | Export-Csv .\Groups.csv