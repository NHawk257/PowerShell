Connect-ExchangeOnline
Connect-MsolService

#Name and create CSV file
$Name = Get-AcceptedDomain | Where-object {$_.Default -eq "True"} | Select-Object -ExpandProperty Name 
$Name = $Name.replace(".onmicrosoft.com","")
$csvfilename = ".\'$Name'_Unlicensed_Mailbox_Report_$((Get-Date -format dd-MM-yy).ToString()).csv"
$csvfilename = $csvfilename.Replace("'","")
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,UPN,Mailbox Type,Hold Enabled?,Hold Date,Hold Created by,Hold End,Last Accessed"

#Get list of unlicensed users from AAD
$UnlicensedUsers = Get-MsolUser -All -UnlicensedUsersOnly | Select-Object -ExpandProperty UserPrincipalName

Foreach ($user in $UnlicensedUsers)
{
    #Reset variables
    $MailboxType = $null
    $MailboxName = $null
    $MailboxHold = $null
    $HoldCreatedBy = $null
    $HoldEndDate = $null
    $LastLogon = $null

    Try {
        #Using a try to get all variables. Only actual failure for the catch is $MailboxType
        $MailboxType    = Get-Mailbox -Identity $user -ErrorAction Stop,silentlycontinue | Select-Object -ExpandProperty RecipientTypeDetails
        $MailboxName    = Get-Mailbox -Identity $user | Select-Object -ExpandProperty Name
        $MailboxHold    = Get-Mailbox -Identity $user | Select-Object -ExpandProperty LitigationHoldEnabled
        $HoldDate       = Get-Mailbox -Identity $user | Select-Object -ExpandProperty LitigationHoldDate
        $HoldCreatedBy  = Get-Mailbox -Identity $user | Select-Object -ExpandProperty LitigationHoldOwner
        $HoldEndDate    = Get-Mailbox -Identity $user | Select-Object -ExpandProperty EndDateForRetentionHold
        $LastLogon      = Get-MailboxStatistics -Identity $user | Select-Object -ExpandProperty LastLogonTime
    }
    
    Catch {
        #We don't care about documenting these right now but we could if we wanted to
        Write-Host "No Mailbox Exists for $user"
    }

    If ($HoldEndDate -eq $null) {
        #Adjust empty end date to an actual output
        $HoldEndDate = "No End Date"
    }

    If ($MailboxType -ne $null){
        #Only add content to the CSV if it exists. Stops a ridiculous number of empty lines.
        Add-Content $csvfilename "$MailboxName,$user,$MailboxType,$MailboxHold,$HoldDate,$HoldCreatedBy,$HoldEndDate,$LastLogon"
    }

    Else {
        #do nothing.
    }
    
}
