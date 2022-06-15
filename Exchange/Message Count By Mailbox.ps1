<#
Report a count of the number of messages receievd in the last 90 days
And then MAYBE send it as an email to someone...?
#>

Connect-ExchangeOnline

Param(
    [Parameter(Mandatory = $true)]
    [string]$Mailbox,
    [number]$Days
    <#Remove this comment to require email values
    [string]$SMTPServer,
    [string]$Sender,
    [string]$Recipient
    #>
)

#Dates should be m/d/yyyy
$EndDate        = Get-Date -Format MM/dd/yyyy
$DaysAgo        = (Get-Date).AddDays(-$Days)
$StartDate      = Get-Date -Date $DaysAgo -Format MM/dd/yyyy
$ReportTitle    = "$mailbox - $StartDate-$EndDate"

$Search = Start-HistoricalSearch -ReportTitle $ReportTitle -ReportType MessageTrace -RecipientAddress $Mailbox -StartDate $StartDate -EndDate $EndDate

$Status = Get-HistoricalSearch -JobId $Search.JobId | Select-Object -ExpandProperty Status

while ($Status -ne "Done") {
    
    Write-Host "Waiting for Report to complete..."
    Start-Sleep -Seconds 60
    $Status = Get-HistoricalSearch -JobId $Search.JobId | Select-Object -ExpandProperty Status
}

$MessageCount = Get-HistoricalSearch -JobId $Search.JobId | Select-Object -ExpandProperty Rows

Write-Host "Number of messages received $StartDate to $EndDate is: $MessageCount"

<#
Remove the above line and put this in place instead to sent the details as an email

$Body =  "Number of messages received $StartDate to $EndDate is: $MessageCount"
Send-MailMessage -From $Sender -To $Recipient -Subject $ReportTitle -Body $Body -SmtpServer $SMTPServer

#>
