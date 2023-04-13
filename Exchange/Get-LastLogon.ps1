#Connect-ExchangeOnline

#Create the CSV file with headers
$csvfilename = ".\LastLogonReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,UPN,Last Interaction,Last Logon,Last User Action"

#Import SAMs given to us by Andrew
$SAMs = Import-csv 'C:\Users\Evan\Desktop\Service Account Review - March 3.csv'
$UPNs = $SAMs.UPN

Foreach ($UPN in $UPNs){

    $Stats = Get-MailboxStatistics $UPN

    $DisplayName     = $Stats.DisplayName
    $LastInteraction = $Stats.LastInteractionTIme
    $LastLogon       = $Stats.LastLogonTime
    $LastUserAction  = $Stats.LastUserActionTime

    Add-Content $csvfilename "$DisplayName,$UPN,$LastInteraction,$LastLogon,$LastUserAction"

}