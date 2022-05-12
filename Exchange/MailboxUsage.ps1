#Connect-ExchangeOnline

#Create the master CSV file with headers
$csvfilename = ".\MailboxSizeReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Email,Items,Size,Quota"

$Mailboxes = Get-Mailbox -ResultSize Unlimited | Select-Object -ExpandProperty PrimarySmtpAddress

Foreach ($Mailbox in $Mailboxes) {
    
    $CurrentMailbox = Get-Mailbox -Identity $Mailbox
    $MailboxStats = Get-MailboxStatistics -Identity $Mailbox

    $Email = $CurrentMailbox.PrimarySMTPAddress
    $Items = $MailboxStats.ItemCount
    $Size  = $MailboxStats.TotalItemSize
    $Quota = Get-Mailbox $Mailbox | Select-Object -ExpandProperty ProhibitSendReceiveQuota 


    #Clean the Size numbers. The commas in it create havoc in a CSV file.
    $CleanSize = $Size -replace ',',';'
    $CleanQuota = $Quota -replace ',',';'

    Add-Content $csvfilename "$CurrentMailbox,$Email,$Items,$CleanSize,$CleanQuota"
}