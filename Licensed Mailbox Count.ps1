Connect-ExchangeOnline
Connect-MsolService


$LicensedUsers = Get-MsolUser -All | where {$_.isLicensed -eq $true} | Select -ExpandProperty UserPrincipalName
$i = 0
$j = 0

Foreach ($user in $LicensedUsers)
{
    Try {

        $MailboxType = Get-Mailbox -Identity $user -ErrorAction Stop,silentlycontinue
        $i++
         }
    
    Catch {
        
        $MailboxType = "No Mailbox Exists"
        $j++
    }

}

Write-Host "$i licensed mailboxes"
Write-Host "$j licensed users with no mailboxes"
