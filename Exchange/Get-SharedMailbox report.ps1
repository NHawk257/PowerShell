#Connect-ExchangeOnline 

#Create the CSV file
$csvfilename = ".\SharedMailboxReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,Email,Items,Size,LastAccessed,Created,LastChanged"

#Get list of Shared Mailboxes, Alias was too vauge in some cases, PrimarySMTP cannot be vauge
$SharedMailboxes = Get-mailbox -RecipientTypeDetails SharedMailbox | Select -ExpandProperty PrimarySmtpAddress 
$MailboxCount=0
$TotalMailboxes = $SharedMailboxes.count

Foreach ($SharedMailbox in $SharedMailboxes) {
    
    $MailboxCount++
    Write-Progress -Activity "`n     Processed user count: $MailboxCount of $TotalMailboxes"`n"  Currently Processing: $SharedMailbox" -PercentComplete ($MailboxCount/$TotalMailboxes*100)
    $Mailbox = Get-Mailbox -Identity $SharedMailbox
    $MailboxStats = Get-MailboxStatistics -Identity $SharedMailbox
    $LastAccessed = $MailboxStats.LastInteractionTime
    $Items = $MailboxStats.ItemCount
    $Size = $MailboxStats.TotalItemSize
    $CleanSize = $Size -replace ',',';'
    $Email = $Mailbox.PrimarySMTPAddress
    $Created = $Mailbox.WhenCreated
    $Changed = $Mailbox.WhenChanged

    #Change nonsense 1600 date to "Never Accessed"
    if ($LastAccessed -eq '12/31/1600 5:00:00 PM'){

        $LastAccessed = 'Never Accessed'

    }Else {
        $LastAccessed = $LastAccessed

    }

    Add-Content $csvfilename "$Mailbox,$Email,$Items,$CleanSize,$LastAccessed,$Created,$Changed"
}
