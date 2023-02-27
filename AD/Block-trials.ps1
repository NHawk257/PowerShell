<#
Microsoft's setting found in the M365 Admin center does not block users from starting trials in "Power Platform" based apps including Project, Visio, and Dynamics.
This script will run through all these products (based on the ID list provided at the moment by MS) and disable the ability for users to initiate trials.
#>

Connect-MSCommerce 
#Install this module if you don't have it, it is likely not used as of yet

#Get a list of all ProductIDs with the ServiceService policy assigned (enabled and disabled)
$IDs = Get-MSCommerceProductPolicies AllowSelfServicePurchase | Select-Object -ExpandProperty ProductID -ErrorAction SilentlyContinue

Foreach ($ID in $IDs){

    $Status = Get-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $ID | Select-Object ProductName,PolicyID,PolicyValue

    If ($Status.PolicyValue -eq 'Enabled'){

        #Just proving it works by outputting the list of products allowed:
        Write-Host ""$Status.ProductName"allows free user trials"
        #Update all to disabled status (Setting Allow to Disabled state)
        #Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $ID -Value "Disabled"

    }
}
