#Get a list of all members of a Shared Mailbox based on an inputted list of mailboxes

$csvfilename = ".\SM_Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Type,LastAccessed,Members"

$Mailboxes = Import-Csv '.\SCTASK0583459.csv' #| Where-Object {$_.type -eq "Shared Mailbox"}

foreach ($Mailbox in $Mailboxes){

    $Type = Get-Recipient $Mailbox.SMTP | Select -ExpandProperty RecipientType
    If ($Type -eq "UserMailbox"){

        $Members = Get-MailboxPermission $Mailbox.SMTP | Where-Object {$_.AccessRights -eq "FullAccess"} | Select-Object -ExpandProperty user
        $LastUserAction = Get-MailboxStatistics $Mailbox.SMTP | Select-Object -ExpandProperty LastInteractionTime

    }
    elseif ($Type -Like "*MailUniversal*") {
        $Members = Get-DistributionGroupMember $Mailbox.SMTP | Select-Object -ExpandProperty DisplayName
        $LastUserAction = $null
    }

    else {
        Write-Host $Mailbox.SMTP "Does not exist"
        }

    $Name = $Mailbox.SMTP

    Add-Content $csvfilename "$Name,$Type,$LastUserAction,$members"

}