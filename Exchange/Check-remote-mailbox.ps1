<#
    This script is used to check for mismatches between Exchange Online AD Synced mailboxes and on-prem Exchange Remote Mailboxes
    The mismatch of these two services can cause signifigant issues when attempting to relay messages through on-prem Exchange
    Depending on the size of your environment, this script may take HOURS to run fully as it calls between EXO and on-prem
    The final output is a CSV file with a list of all mailboxes that exist in EXO and AD but do not have remote mailboxes 
#>

#Connect to EXO using a Prefix so commands don't run into eachother on-prem
Connect-ExchangeOnline -Prefix ExchOnline

#Connect to Exchange on-prem
$UserCredential = Get-Credential
$Server = Read-Host -Prompt 'Input Exchange Server PS URI'
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $Server -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking

#Set AD Scope to entire forest for the case of sub/split domains
Set-ADServerSettings -ViewEntireForest $true

#Create the CSV file with headers
$csvfilename = ".\Remote_MailboxReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,Alias,Primary SMTP,Usage Location,Exchange Online GUID"

#Get list of DirSynced Mailboxes that belong to our primary domain
#Alias was too vauge in some cases, using PrimarySMTP instead as it cannot be vauge
$CloudMailboxes = Get-ExchOnlineMailbox -resultsize Unlimited | ? {($_.IsDirSynced -eq 'True') -and ($_.PrimarySMTPAddress -like "*@finning.com")} | Select-Object -ExpandProperty PrimarySmtpAddress

#Reset counts everytime the script is ran for progress bar
#This isn't working right now, idk why but I can't be bothered to fix it...
$MailboxCount=0
$TotalMailboxes = $CloudMailboxes.count

Foreach ($CloudMailbox in $CloudMailboxes){
    #Update Progress bar for each mailbox processed, again this doesn't work but doesn't effect the script itself
    $MailboxCount++
    Write-Progress -Activity "`n     Processed user count: $MailboxCount of $TotalMailboxes"`n"  Currently Processing: $SharedMailbox" -PercentComplete ($MailboxCount/$TotalMailboxes*100)

    #Try to see if there's a remote mailbox for the user. If there is, the script will stop here
    #Had to 'Out-Null' as remote-ps sessions to Exchange do not support WarningAction flags and it will fill the page with warnings
    #You may want to remote the 'Out-Null' if you want to see RemoteMailboxes that have warnings
    try {
        Get-RemoteMailbox $CloudMailbox -ErrorAction Stop,silentlycontinue | Out-Null
    }
    catch {
        #If there isn't a remote mailbox that matches the PrimarySMTP address, add its details to the CSV
        $Mailbox     = Get-ExchOnlineMailbox $CloudMailbox
        $DisplayName = $Mailbox.DisplayName
        $Alias       = $Mailbox.Alias
        $PrimarySMTP = $Mailbox.PrimarySMTPAddress
        $Location    = $Mailbox.UsageLocation
        $GUID        = $Mailbox.ExchangeGuid
        
        Add-Content $csvfilename "$DisplayName,$Alias,$PrimarySMTP,$Location,$GUID"
    }
}