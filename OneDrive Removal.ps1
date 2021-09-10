Write-Host "Connecting to MSOL for user list..." -foregroundColor Green
Connect-MsolService

$F3users = get-msoluser -all  | Where-Object {($_.licenses).AccountSkuId -match "DESKLESSPACK"} | foreach {$_.UserPrincipalName}
                                                                                #^Adjust this SkuID as needed. This is F3.

Write-Host "Connecting to SPO..." -foregroundColor Green
$TenantAdminName = '%tenant%-admin'
Connect-SPOService https://$TenantAdminName.sharepoint.com/

<# To Dump Data to a CSV instead of actioning, use these lines:
$csvfilename = ".\OneDrive Usage - $TenantAdminName.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "URL,Owner"

#>


foreach ($F3user in $F3users)
{
    Write-Host "Removing access for user $F3user" -foregroundColor Green
    $Owner = $F3user
    $Site = Get-SPOSite -IncludePersonalSite $True -Filter {Url -like '-my.sharepoint.com/personal/'} -Limit All | ? { $_.owner -like "*$F3user*"} | select URL
    Set-SPOSite -LockState NoAccess -Identity $Site.URL

    #Use the below line to append data to a CSV for tracking if needed
    #Add-Content $csvfilename "$Site,$Owner"
}
