Connect-ExchangeOnline

$VIPs = Import-Csv .\VIPs.csv
#Only need this section because the list being provided is just names, no other useful information...
$Mailboxes = @()
Foreach ($Vip in $VIPs){

        $Mailboxes += Get-Mailbox $VIP.name | Select-Object -ExpandProperty PrimarySMTPAddress
}

#Create folder for CSVs
$DateString = (Get-Date).ToString('dd-MMM-yyyy hh-mm-tt')
$FolderPath = ".\VIP_Perms_$DateString"
New-Item -ItemType Directory -Path $FolderPath
Set-Location $FolderPath

#INBOX:
Foreach ($Mailbox in $Mailboxes){
    Get-MailboxPermission $Mailbox | Where-Object {$_.User -notlike "*NT AUTH*"} | Export-Csv .\$Mailbox'inbox_list'.csv
}

#CALENDARS:
Foreach ($Mailbox in $Mailboxes){
    Try { #English Users
        #Get-MailboxFolderPermission $Mailbox':\Calendar' -ErrorAction SilentlyContinue | Where-Object {$_.User -notlike "*NT AUTH*"} | Export-Csv .\$Mailbox'list'.csv
        $Users = Get-MailboxFolderPermission $Mailbox':\Calendar' -ErrorAction SilentlyContinue | Where-Object {($_.User -notlike "*NT AUTH*") -and ($_.User -notlike "*Default*")} `
        | Select-object User
        Foreach ($user in $Users){
            try {
                Get-Mailbox $user.user -ErrorAction SilentlyContinue 
            }
            catch {
                Write-Host $user.user "does not exist"
            }
        }
    }
    Catch{ #Spanish Users
        #Get-MailboxFolderPermission $Mailbox':\Calendario' | Where-Object {$_.User -notlike "*NT AUTH*"} | Export-Csv .\$Mailbox'calendar_list'.csv
        $Users = Get-MailboxFolderPermission $Mailbox':\Calendario' -ErrorAction SilentlyContinue | Where-Object {($_.User -notlike "*NT AUTH*") -and ($_.User -notlike "*Default*")} `
        | Select-object User
        Foreach ($user in $Users){
            try {
                Get-Mailbox $user.user -ErrorAction SilentlyContinue 
            }
            catch {
                Write-Host $user.user "does not exist"
            }
        }
    }
}

<#CONTACTS:
Foreach ($Mailbox in $Mailboxes){
    Try { #English Users
        Get-MailboxFolderPermission $Mailbox':\Contacts' -ErrorAction SilentlyContinue | Where-Object {$_.User -notlike "*NT AUTH*"} | Export-Csv .\$Mailbox'list'.csv
    }
    Catch{ #Spanish Users
        Get-MailboxFolderPermission $Mailbox':\Contactos' | Where-Object {$_.User -notlike "*NT AUTH*"} | Export-Csv .\$Mailbox'contacts_list'.csv
    }
}
#>
Set-Location ..