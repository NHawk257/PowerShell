Connect-ExchangeOnline

$mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails SharedMailbox | Select-Object  -ExpandProperty PrimarySMTPAddress
$user =  Read-Host -Prompt "Please provide a user to check permissions for"

foreach($mailbox in $mailboxes){

    $Perms = Get-MailboxPermission $mailbox -User $user

    If ($Perms -ne $Null){
        
        $mailbox.Name

    }
   
}
