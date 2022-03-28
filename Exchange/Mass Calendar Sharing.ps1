Connect-ExchangeOnline
$user = Read-Host -Prompt "Please provide a user or group to grant permission to"

$mailboxes = Get-Mailbox | Select -expandproperty primarysmtpaddress

foreach ($mailbox in $mailboxes)
{
    write-host "Setting permission for $mailbox" -ForegroundColor Green

    Try {
        Add-MailboxFolderPermission "${mailbox}:\calendar" -User $user -AccessRights Publishingeditor -erroraction stop 
    }
    Catch{
        Set-MailboxFolderPermission "${mailbox}:\calendar" -User $user -AccessRights Publishingeditor -WarningAction Silentlycontinue
    }
}
