#Connect to AAD module
Connect-AzureAD

$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 
$Skus = Get-AzureADSubscribedSku | Select-Object Sku*, ConsumedUnits 
ForEach ($Sku in $Skus) {
   Write-Host "Processing license holders for" $Sku.SkuPartNumber
   $SkuUsers = Get-AzureADUser -All $True | ? {$_.AssignedLicenses -Match $Sku.SkuId}
   ForEach ($User in $SkuUsers) {
      $ReportLine  = [PSCustomObject] @{
          User       = $User.DisplayName 
          UPN        = $User.UserPrincipalName
          Department = $User.Department
          Country    = $User.Country
          SKU        = $Sku.SkuId
          SKUName    = $Sku.SkuPartNumber} 
         $Report.Add($ReportLine) }}
<# Use this section to just view the report
    $Report | Sort User | Out-GridView
#>
#Export to a CSV file to manipulate. A Pivot Table works great for summarizing
$Report | Export-Csv .\LicenseReport.csv -Force
