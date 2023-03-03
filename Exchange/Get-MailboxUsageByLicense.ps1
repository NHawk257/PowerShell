Connect-ExchangeOnline
Connect-MsolService

#Get list of MSOL SKUs:
#Get-MsolAccountSku

#Create the CSV file with headers
$csvfilename = ".\F3UsageReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,UPN,Total Size,Licenses"

$Users = Get-MsolUser -all | Where-Object {(($_.licenses).AccountSkuId -match "SPE_F1") -and ($_.SignInName -like "*@4refuel.com")} | Select-Object userPrincipalName,licenses

Foreach ($User in $Users){

    $Stats  =   Get-EXOMailboxStatistics $User.UserPrincipalName
    $TotalSize = $Stats.TotalItemSize
    $CleanSize = $TotalSize -replace ',',';'
    $DisplayName = $Stats.DisplayName
    $SKU        =   $User.Licenses.AccountSkuId
    $UPN        =   $User.UserPrincipalName

    Add-Content $csvfilename "$DisplayName,$UPN,$CleanSize,$SKU"
}
