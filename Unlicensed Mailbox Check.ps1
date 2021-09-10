Connect-ExchangeOnline
Connect-MsolService

$csvfilename = ".\No_Mailbox.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "User,Mailbox Type"

$UnlicensedUsers = Get-MsolUser -All -UnlicensedUsersOnly | Select -ExpandProperty UserPrincipalName

Foreach ($user in $UnlicensedUsers)
{
    Try {

        $MailboxType = Get-Mailbox -Identity $user -ErrorAction Stop,silentlycontinue | Select -ExpandProperty RecipientTypeDetails
        
    }
    
    Catch {
        
        $MailboxType = "No Mailbox Exists"
    }

    Add-Content $csvfilename "$user,$MailboxType"
}
