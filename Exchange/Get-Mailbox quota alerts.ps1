#Connect to Exchange Online
Connect-ExchangeOnline
#Set quota percent limit 
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

    #Convert TotalItemSize to INT64 and remove crap (looks like this initially "1.123 GB (1,205,513,370 bytes)" and comes out as a numeric 1205513370)
    [int64]$Mailboxstats_totalitemsize = [convert]::ToInt64(((($Mailboxstats.TotalItemSize.ToString().split("(")[-1]).split(")")[0]).split(" ")[0]-replace '[,]',''))
    #Convert TotalDeletedItemSize to INT and remove crap (looks like this initially "1.123 GB (1,205,513,370 bytes)" and comes out as a numeric 1205513370)
    [int64]$Mailboxstats_totaldeleteditemsize = [convert]::ToInt64(((($Mailboxstats.TotalDeletedItemSize.ToString().split("(")[-1]).split(")")[0]).split(" ")[0]-replace '[,]',''))
    #Convert ProhibitSendQuota to INT64 and remove crap (looks like this initially "1.123 GB (1,205,513,370 bytes)" and comes out as a numeric 1205513370)
    [INT64]$Quota = [convert]::ToInt64(((($Mailbox.ProhibitSendQuota.ToString().split("(")[-1]).split(")")[0]).split(" ")[0]-replace '[,]',''))
    
    # Calculate the quota percentage
    $Quota_percentage = [INT]((($Mailboxstats_totalitemsize + $Mailboxstats_totaldeleteditemsize) / $Quota)*100)

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