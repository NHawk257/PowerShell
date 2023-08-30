#Get a list of all members of a Shared Mailbox based on an inputted list of mailboxes

$csvfilename = ".\SM_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Members"

$Mailboxes = Import-Csv '.\Unlicsensed Shared Mailboxes.csv' #| Where-Object {$_.type -eq "Shared Mailbox"}

foreach ($Mailbox in $Mailboxes){

    $Members = Get-MailboxPermission $Mailbox.PrimarySMTPAddress | Where-Object {$_.AccessRights -eq "FullAccess"} | Select-Object -ExpandProperty user
    $Name = $Mailbox.DisplayName

    Add-Content $csvfilename "$Name,$members"

}