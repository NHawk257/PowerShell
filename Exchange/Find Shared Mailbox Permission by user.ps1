Connect-ExchangeOnline

$user =  Read-Host -Prompt "Please provide a user to check permissions for"
$mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails SharedMailbox | Select-Object  -ExpandProperty PrimarySMTPAddress

foreach($mailbox in $mailboxes){

    $Perms = Get-MailboxPermission $mailbox -User $user -ErrorACtion SilentlyContinue

    If ($Perms -ne $Null){
        
        $mailbox.Name

    }
   
}