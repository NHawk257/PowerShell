#Connect-ExchangeOnline 

#Create the master CSV file with headers
$csvfilename = ".\SharedMailboxReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Email,Items,Size,LastAccessed,Created,LastChanged,Disabled,Delegates,Rules"

#Get list of Shared Mailboxes, Alias was too vauge in some cases, PrimarySMTP cannot be vauge
$SharedMailboxes = Get-mailbox -RecipientTypeDetails SharedMailbox | Select -ExpandProperty PrimarySmtpAddress

#Reset counts everytime the script is ran 
$MailboxCount=0
$TotalMailboxes = $SharedMailboxes.count

Foreach ($SharedMailbox in $SharedMailboxes) {
    
    $MailboxCount++
    Write-Progress -Activity "`n     Processed user count: $MailboxCount of $TotalMailboxes"`n"  Currently Processing: $SharedMailbox" -PercentComplete ($MailboxCount/$TotalMailboxes*100)
    
    #Re-gather all information for each mailbox as we needed to be specific for our  master list
    $Mailbox = Get-Mailbox -Identity $SharedMailbox
    $MailboxStats = Get-MailboxStatistics -Identity $SharedMailbox

    #Create a list of attributes we care about
    $Email = $Mailbox.PrimarySMTPAddress
    $Items = $MailboxStats.ItemCount
    $Size = $MailboxStats.TotalItemSize
    $AccessedDate = $MailboxStats.LastInteractionTime  
    $Created = $Mailbox.WhenCreated
    $Changed = $Mailbox.WhenChanged
    $Disabled = $Mailbox.AccountDisabled

    #More specific values that we need from different commands
    $Delegates = Get-MailboxPermission $SharedMailbox | ? {$_.User -ne 'NT AUTHORITY\SELF'} | Select -ExpandProperty User
    $MailboxRules = Get-InboxRule -Mailbox $SharedMailbox

    #Clean the Size number. The commas in it create havoc in a CSV file.
    $CleanSize = $Size -replace ',',';'

    #Change nonsense 1600 date to "Never Accessed"
    If ($AccessedDate -eq '12/31/1600 5:00:00 PM'){

        $LastAccessed = 'Never Accessed'

    }
    Else {
        $LastAccessed = $AccessedDate

    }

    #Clarify mailbox rules. If they exist, export a CSV with a list of rules for it
    #The first time one matches, a new folder will be created. This action will fail every time after which is fine.
    If ($MailboxRules -eq $null){

            $Rules = 'No'
        }
        Else {
            $Rules = 'Yes; see export'
            New-Item -itemtype "directory" -Name "Rules" -ErrorAction SilentlyContinue
            Get-InboxRule -Mailbox $SharedMailbox | Export-Csv ".\Rules\${mailbox}_rules.csv"
            
        }

    #Dump all the attributes we care about to a master CSV
    Add-Content $csvfilename "$Mailbox,$Email,$Items,$CleanSize,$LastAccessed,$Created,$Changed,$Disabled,$Delegates,$Rules"
}
