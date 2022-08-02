<# Used for reporting on the total number of mailboxes in a tenant
   Plus a CSV file to backup the data. Primarily for billing use.
   
   I keep forgetting what exactly I used for this and have to 
   re-write it every month. It was just a 1 liner but This way 
   I don't have to remember it.
#>

Connect-ExchangeOnline

$Name = Get-AcceptedDomain | Where-object {$_.Default -eq "True"} | Select-Object -ExpandProperty Name 
$Name = $Name.replace(".onmicrosoft.com","")

Get-mailbox -ResultSize Unlimited | Select-Object DisplayName,PrimarySmtpAddress,RecipientTypeDetails | Export-Csv .\"$Name"_Mailbox_Count_$((Get-Date -format dd-MM-yy).ToString()).csv 

<# - Display a count of mailboxes on the screen rather than needing to Pivot
   $UserMailboxes    = (Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox).count
   $SharedMailboxes  = (Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails SharedMailbox).count
   $RoomMailboxes    = (Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails RoomMailbox).count
   $EquipMailboxes   = (Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails EquipmentMailbox).count

   Write-Host "There are $UserMailboxes User Mailboxes"
   Write-Host "There are $SharedMailboxes Shared Mailboxes"
   Write-Host "There are $RoomMailboxes Room Mailboxes"
   Write-Host "There are $EquipmentMailboxes Equipment Mailboxes"
#>