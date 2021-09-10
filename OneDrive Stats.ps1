Write-Host "Connecting to MSOL for user list..." -foregroundColor Green
Connect-MsolService

$users = Get-MsolUser -All | where {$_.isLicensed -eq $true}

Write-Host "Connecting to SPO..." -foregroundColor Green
$TenantAdminName = '%tenant%-admin'
Connect-SPOService https://$TenantAdminName.sharepoint.com/

$csvfilename = ".\OneDrive Usage - $TenantAdminName.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Owner,Usage,Quota,Status"

Write-Host "Getting OneDrive usage..." -foregroundColor Green
foreach ($user in $Users)
{
    $Stats = Get-SPOSite -IncludePersonalSite $True -Filter {Url -like '-my.sharepoint.com/personal/'} -Limit All | ? { $_.owner -like $user.userprincipalname} | select Owner,StorageUsageCurrent,StorageQuota,Status
    
    $Owner = $stats.Owner
    $Usage = $stats.StorageUsageCurrent
    $Quota = $stats.StorageQuota
    $Status = $Stats.Status
            
    Add-Content $csvfilename "$Owner,$Usage,$Quota,$Status"
}


