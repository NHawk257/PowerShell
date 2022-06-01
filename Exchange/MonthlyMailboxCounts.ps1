<# Used for reporting on the total number of mailboxes in a tenant
   Plus a CSV file to backup the data. Primarily for billing use.
   
   I keep forgetting what exactly I used for this and have to 
   re-write it every month. It's just a 1 liner but This way I 
   don't have to remember it.
#>

Connect-ExchangeOnline

$Name = Get-AcceptedDomain | Where-object {$_.Default -eq "True"} | Select-Object -ExpandProperty Name 
$Name = $Name.replace(".onmicrosoft.com","")

Get-mailbox -ResultSize Unlimited | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails | Export-Csv .\"$Name"_Mailbox_Count_$((Get-Date -format dd-MM-yy).ToString()).csv 
