#Connect to EXO using a Prefix so commands don't run into eachother on-prem
Connect-ExchangeOnline -Prefix ExchOnline

#Connect to Exchange on-prem
$UserCredential = Get-Credential
$Server = Read-Host -Prompt 'Input Exchange Server PS URI'
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $Server -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking

#Set AD Scope to entire forest
Set-ADServerSettings -ViewEntireForest $true

#Create the CSV file with headers
$csvfilename = ".\Remote_MailboxReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,Alias,Primary SMTP,Exchange Online GUID"

#Get list of DirSynced Mailboxes, Alias was too vauge in some cases, PrimarySMTP cannot be vauge
$CloudMailboxes = get-ExchOnlineMailbox -resultsize Unlimited | ? {$_.IsDirSynced -eq 'True'} | Select-Object -ExpandProperty PrimarySmtpAddress

#Reset counts everytime the script is ran for progress bar
$MailboxCount=0
$TotalMailboxes = $CloudMailboxes.count

Foreach ($CloudMailbox in $CloudMailboxes){
    #Update Progress bar for each mailbox processed
    $MailboxCount++
    Write-Progress -Activity "`n     Processed user count: $MailboxCount of $TotalMailboxes"`n"  Currently Processing: $SharedMailbox" -PercentComplete ($MailboxCount/$TotalMailboxes*100)

    #Try to see if there's a remote mailbox for the user
    try {
        Get-RemoteMailbox $CloudMailbox -ErrorAction Stop,silentlycontinue | Out-Null
    }
    catch {
        #If there isn't a remote mailbox that matches, add it to the CSV
        $Mailbox     = Get-ExchOnlineMailbox $CloudMailbox
        $DisplayName = $Mailbox.DisplayName
        $Alias       = $Mailbox.Alias
        $PrimarySMTP = $Mailbox.PrimarySMTPAddress
        $GUID        = $Mailbox.ExchangeGuid
        
        Add-Content $csvfilename "$DisplayName,$Alias,$PrimarySMTP,$GUID"
    }
}