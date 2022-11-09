Connect-ExchangeOnline

#Input the CSV name/path:
$CSVPath = "C:\Users\Evan\Documents\Cubiq_Accounts.csv"
$Members = @('kim.ng@finning.com','pentti.huttunen@finning.com','nick.rao@finning.com','Oscar.Palacio@finning.com','jessicapaola.gaytan@finning.com')

$Mailboxes = Import-Csv $CSVPath

#Check if mailboxes exist first (double-checking to verify no issues in creating mailboxes)
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

    Write-host ""$Mailbox.name" created with "$Mailbox.email" address"
    #New-Mailbox -Alias $Mailbox.Name -PrimarySmtpAddress $Mailbox.Email -Shared

    #Assign permissions to mailboxes as created
    Foreach ($Member in $Members){
        Write-Host "$Member addeded to "$Mailbox.name""
        #Add-MailboxPermission -Identity $Mailbox.Name -User $member -AccessRights FullAccess,SendAs

    }
    

}