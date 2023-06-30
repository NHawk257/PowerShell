#Get a list of all members of a DL based on an inputted list of mailboxes

$csvfilename = ".\SM_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Members"

$Mailboxes = Import-Csv .\EPS_Recipients.csv | ? {$_.type -eq "Shared Mailbox"}

foreach ($Mailbox in $Mailboxes){

    $Members = Get-MailboxPermission $Mailbox.Alias | ? {$_.AccessRights -eq "FullAccess"} | Select -ExpandProperty user
    $Name = $Mailbox.DisplayName

    Add-Content $csvfilename "$Name,$members"

}