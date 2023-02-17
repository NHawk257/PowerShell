Connect-MSCommerce
#Install this module if you don't have it, it is likely not used as of yet

#ID list pulled from MS (https://learn.microsoft.com/en-us/microsoft-365/commerce/subscriptions/allowselfservicepurchase-powershell?view=o365-worldwide#view-a-list-of-self-service-purchase-products-and-their-status)
$IDs = 'CFQ7TTC0LH2H','CFQ7TTC0KP0N','CFQ7TTC0KXG6','CFQ7TTC0KXG7','CFQ7TTC0L3PB','CFQ7TTC0HDB1','CFQ7TTC0HDB0','CFQ7TTC0HD33','CFQ7TTC0HD32','CFQ7TTC0PW0V','CFQ7TTC0HHS9',
'CFQ7TTC0J203','CFQ7TTC0HX99','CFQ7TTC0LH05','CFQ7TTC0LH3N','CFQ7TTC0LHWP','CFQ7TTC0LHVK','CFQ7TTC0LHWM'

Foreach ($ID in $IDs){

    $Status = Get-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $ID | Select-Object ProductName,PolicyID,PolicyValue

    If ($Status.PolicyValue -eq 'Enabled'){

        #Just proving it works by outputting the list of products allowed:
        Write-Host ""$Status.ProductName"allows free user trials"
        #Update all to disabled status (Setting Allow to Disabled state)
        #Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $ID -Value "Disabled"

    }
}
