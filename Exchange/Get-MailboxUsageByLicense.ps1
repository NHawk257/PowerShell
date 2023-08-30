Connect-ExchangeOnline
#Connect-MsolService -- Switching to Graph as MSOL is broken AF regularly...
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All

#Get list of MSOL SKUs: Get-MsolAccountSku
#Old MSOL User Search
#$Users = Get-MsolUser -all | Where-Object {(($_.licenses).AccountSkuId -match "SPE_F1") -and ($_.SignInName -like "*@4refuel.com")} | Select-Object userPrincipalName,licenses

#Create the CSV file with headers
$csvfilename = ".\F3UsageReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,UPN,Disabled,License,Total Size"

#Filtering for domain specific mailboxes
$Mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox | Where-Object {$_.PrimarySMTPAddress -like "*@4refuel.com"}

Foreach ($Mailbox in $Mailboxes){
    #Specifically looking for F3 users. Adjust to different SKU if needed
    $F3Check = Get-MgUserLicenseDetail -UserId $Mailbox.PrimarySMTPAddress -ErrorAction SilentlyContinue | Where-Object {$_.SkuPartNumber -match "SPE_F1"}
    If ($F3Check -ne $Null){
        $Stats          =   Get-EXOMailboxStatistics $Mailbox.UserPrincipalName
        $TotalSize      =   $Stats.TotalItemSize
        #Commas in the size value causes issues wtih CSV files, replacing with semis
        $CleanSize      =   $TotalSize -replace ',',';'
        $DisplayName    =   $Stats.DisplayName
        $SKU            =   $F3Check.SkuPartNumber
        $UPN            =   $Mailbox.UserPrincipalName
        $Disabled       =   $Mailbox.AccountDisabled

    Add-Content $csvfilename "$DisplayName,$UPN,$Disabled,$SKU,$CleanSize"
    }
}
