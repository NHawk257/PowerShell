Connect-ExchangeOnline

#Create the CSV file with headers
$csvfilename = ".\Fake_Shared_Mailbox_report.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,Alias,Primary SMTP,RecipientTypeDetails"

#Get user type mailboxes. Adjust filtering as required
$Users = Get-Mailbox -ResultSize 1000 -RecipientTypeDetails UserMailbox

#Check each user type mailbox for sharing permissions. If they have permissions, add them to the CSV Report
Foreach ($User in $Users){
    $Perms = $Null
        $Perms = Get-MailboxPermission -Identity $User.PrimarySMTPaddress | Where-Object {$_.User -notlike "*NT Auth*"}
        If ($Perms -ne $Null){
            $DisplayName    =   $User.DisplayName
            $Alias          =   $User.Alias
            $PrimarySMTP    =   $User.PrimarySMTPAddress
            $RecipientType  =   $User.RecipientTypeDetails
        
        Add-Content $csvfilename "$DisplayName,$Alias,$PrimarySMTP,$RecipientType"
    }
        else{}
}

#For the sake of double-checking myself...
$Users = import-csv .\fake_shared_mailbox_report.csv
