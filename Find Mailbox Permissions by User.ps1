Connect-ExchangeOnline

$mailboxes = Get-Mailbox
$user =  Read-Host -Prompt "Please provide a user to check permissions for"

foreach($mailbox in $mailboxes)

{
    Try {
    
        Get-MailboxFolderPermission "${mailbox}:\calendar" -User $user -erroraction stop,silentlycontinue
        $mailbox.Name
    }

    Catch {
        
    }
}
