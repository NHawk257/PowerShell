<#
With Help from: https://blog.haake.nu/2015/01/exchange-2013-mailbox-quota-usage-and.html
Some changes made to help math work better and checks to stop empty mailboxes from throwing errors
#>
#Connect to Exchange Online
Connect-ExchangeOnline

#Set quota percent limit (80% by default) 
$quotalimit = 80

# Get all mailboxes
$Mailboxes = @(Get-Mailbox -ResultSize Unlimited | select-object DisplayName, Identity, ProhibitSendQuota, ProhibitSendReceiveQuota)
# Clear the report object variable
$Report =@()

# Loop through all mailboxes
foreach ($Mailbox in $Mailboxes)
{
    # Get statistics for all mailboxes
    $Mailboxstats = Get-MailboxStatistics -identity $Mailbox.Identity | select-object Displayname,Identity,Database,TotalItemSize,TotalDeletedItemSize,DatabaseIssueWarningQuota,DatabaseProhibitSendQuota

    #Convert size values to INT64 and remove crap (looks like this initially "1.123 GB (1,205,513,370 bytes)" and comes out as a numeric 1205513370)
    #If statements in use to turf errors related to null values (empty mailboxes)
    If ($MailboxStats.TotalItemSize -ne $Null){
        [int64]$Mailboxstats_totalitemsize = [convert]::ToInt64(((($Mailboxstats.TotalItemSize.ToString().split("(")[-1]).split(")")[0]).split(" ")[0]-replace '[,]',''))
    }
    Else {}
    If ($MailboxStats.TotalDeletedItemSize -ne $Null){
        [int64]$Mailboxstats_totaldeleteditemsize = [convert]::ToInt64(((($Mailboxstats.TotalDeletedItemSize.ToString().split("(")[-1]).split(")")[0]).split(" ")[0]-replace '[,]',''))
    }
    Else{}
    #Quotas are never null so no IF statement needed here
    [INT64]$Quota = [convert]::ToInt64(((($Mailbox.ProhibitSendQuota.ToString().split("(")[-1]).split(")")[0]).split(" ")[0]-replace '[,]',''))
    
    # Calculate the quota percentage as a full decimal and then round to 2 points
    $Quota_percentage = [decimal](($Mailboxstats_totalitemsize / $Quota)*100)
    $Quota_percentage = [Math]::Round($Quota_percentage,2)

    # Add to report object
    if ($Quota_percentage -ge $quotalimit) {
        $ReportObject = New-Object PSObject
        $ReportObject | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $Mailboxstats.DisplayName
        $ReportObject | Add-Member -MemberType NoteProperty -Name "TotalItemSize" -Value $Mailboxstats_totalitemsize
        $ReportObject | Add-Member -MemberType NoteProperty -Name "TotalDeletedItemSize" -Value $Mailboxstats_totaldeleteditemsize
        $ReportObject | Add-Member -MemberType NoteProperty -Name "ProhibitSendQuota" -Value $Quota
        $ReportObject | Add-Member -MemberType NoteProperty -Name "QuotaPercent" -Value $Quota_percentage
        $report += $ReportObject
    }
}
# Output the report, sorted with the highest quota percentage at the top
$Report | Sort-Object QuotaPercent -Descending