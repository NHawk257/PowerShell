Connect-ExchangeOnline

<# Parameters Note:
CSV file should be created with two columns, Name and Email. 
The Name column will be used for the DisplayName and Name values of the mailbox. The Email will be used for the Primary SMTP
The Members Aray should be a list of all users (Alias or SMTP) that will be given permissions to this mailbox
#>
$CSVPath = ".\FilePath.csv"
$Members = @('Member1','Member2','Member3')
$Mailboxes = Import-Csv $CSVPath

#Check if mailboxes exist first to stop errors. Also useful to verify creations worked OK
Foreach ($Mailbox in $mailboxes){

    try {
        Get-Mailbox $Mailbox.Name -ErrorAction Stop,SilentlyContinue
        Write-Host "MATCH FOUND FOR "$Mailbox.Name"" -ForegroundColor Yellow
    }
    catch {
        try {
            Get-Mailbox $Mailbox.Email -ErrorAction Stop,SilentlyContinue
            Write-Host "MATCH FOUND FOR "$Mailbox.Name"" -ForegroundColor Yellow
        }
        catch {
            Write-Host "No match found for "$Mailbox.Name""
        }
    }

}
#Create Mailboxes
Foreach ($Mailbox in $mailboxes){

    New-Mailbox -Name $Mailbox.Name -Alias $Mailbox.Name -PrimarySmtpAddress $Mailbox.Email -Shared

    #Assign permissions to mailboxes as created
    Foreach ($Member in $Members){
                
        <# Permissions Note:
        If you are creating a bunch of mailboxes, Outlook will only display the first 32 entries (including the user's mailbox and archive).This is why we have disabled AutoMapping. 
        Adjust these lines as needed for appropriate AccessRights, AutoMapping settings, and if SendAs is required or not.
        #>
        Add-MailboxPermission -Identity $Mailbox.Name -User $member -AccessRights FullAccess -AutoMapping $false
        Add-RecipientPermission -Identity $Mailbox.Name -Trustee $member -AccessRights SendAs -Confirm:$false
        
    }
    

}