<#
    As is, this script assumes every mailbox in the tenant is licensed for a 100GB mailbox (P2/E5)
    This needs to be modified to check the license type first and then compare the mailbox size.
#>

Connect-ExchangeOnline

$WrongReceive = 0
$WrongSend = 0
$WrongWarning = 0

$Mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox 

Foreach ($Mailbox in $mailboxes){

    $ProhibitSend = $mailbox.ProhibitSendQuota
    $ProhibitSendReceive = $mailbox.ProhibitSendReceiveQuota
    $IssueWarning = $mailbox.IssueWarningQuota

    if ($ProhibitSend -notlike '99 GB*'){
        $WrongSend++
        Write-Host "$mailbox has a wrong send quota, correcting..."
        Set-Mailbox $Mailbox.PrimarySMTPAddress -ProhibitSendQuota 99GB
        }

    if ($ProhibitSendReceive -notlike '100 GB*'){
        $WrongReceive++
        Write-Host "$mailbox has a wrong receive quota, correcting..."
        Set-Mailbox $Mailbox.PrimarySMTPAddress -ProhibitSendReceiveQuota 100GB
        }

    if ($IssueWarning -notlike '98 GB*'){
        $WrongWarning++
        Write-Host "$mailbox has a wrong warning quota, correcting..."
        Set-Mailbox $Mailbox.PrimarySMTPAddress -IssueWarningQuota 98GB
        }

}

$WrongReceive
$WrongSend
$WrongWarning
