Connect-MsolService
Connect-AzureAD

Get-AzureADSubscribedSku | Select SkuPartNumber

$allSKUs=Get-AzureADSubscribedSku

$licArray = @()
for($i = 0; $i -lt $allSKUs.Count; $i++)
{
$licArray += "Service Plan: " + $allSKUs[$i].SkuPartNumber
$licArray +=  Get-AzureADSubscribedSku -ObjectID $allSKUs[$i].ObjectID | Select -ExpandProperty ServicePlans
$licArray +=  ""
}
$licArray

$csvfilename = ".\LicenseReport.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "User,License"

$userUPNs = Get-MsolUser -all | foreach {$_.UserPrincipalName} 

foreach($userUPN in $userUPNs)
{
    $licensePlanList = Get-AzureADSubscribedSku
    $userList = Get-AzureADUser -ObjectID $userUPN | Select -ExpandProperty AssignedLicenses | Select SkuID 
    $userList | ForEach { $sku=$_.SkuId ; 
        $licensePlanList | ForEach { 
            If ( $sku -eq $_.ObjectId.substring($_.ObjectId.length - 36, 36) ) 
                { 
                $License = $_.SkuPartNumber 
                Add-Content $csvfilename "$UserUPN,$License"

                } 
            } 
          }
}
