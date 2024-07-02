Install-Module -Name Az -Repository PSGallery -Force
Install-Module -Name MicrosoftPlaces -RequiredVersion 0.32.0-alpha -AllowPrerelease -Force 


Connect-MicrosoftPlaces
Connect-AzAccount

$displayNameCore = "AG EPS Places Pilot"

$tenant = Get-AzTenant
function Set-PlacesCore {
    Write-Host -Message "Enabling Places Core Features for the tenant"

    $plCoreGroup = Get-AzADGroup -DisplayName $displayNameCore
    $oidtidCoreGroup=$plCoreGroup.Id + "@" + $tenant.TenantId
    $groupstring = "Default:false,OID:" + $oidtidCoreGroup + ":true"

    Write-Host "Enabling Places Web App"

    Set-PlacesSettings -Collection Places -EnablePlacesWebApp  $groupstring | Out-Null
    Set-PlacesSettings -Collection Places -EnableBuildings 'Default:true'
}

function Set-PremiumFeatures {
    Write-Host "Enabling Places Advanced Features for the tenant"
    
    $plGroup = Get-AzADGroup -DisplayName $displayNamePrem 
    $oidtidGroup=$plGroup.Id + "@" + $tenant.TenantId
    $groupstring = "Default:false,OID:" + $oidtidGroup + ":true"
    
    Write-Host "Enabling Advanced Places features"

    Set-PlacesSettings -Collection Places -PlacesEnabled $groupstring -ErrorAction SilentlyContinue

    Set-PlacesSettings -Collection Places -PlacesFinderEnabled $groupstring  
}
function Enable-PlacesMobileApp {
    Write-Host "Enabling the group that can use the Places iOS App"

    $plGroup = Get-AzADGroup -DisplayName $displayNameMobile 
    $oidtidGroup=$plGroup.Id + "@" + $tenant.TenantId
    $groupstring = "Default:false,OID:" + $oidtidGroup + ":true"

    Set-PlacesSettings -Collection Places -EnablePlacesMobileApp $groupstring
}

function Enable-PlacesAnalytics {
    Write-Host "Enabling the group that can see Places Analytics"

    $plGroup = Get-AzADGroup -DisplayName $displayNameAnalytics 
    $oidtidGroup=$plGroup.Id + "@" + $tenant.TenantId
    $groupstring = "Default:false,OID:" + $oidtidGroup + ":true"

    Set-PlacesSettings -Collection Places -SpaceAnalyticsEnabled $groupstring
}


$settingEnabled = $false
function Get-PlacesSetting { 
    param([string]$placesSetting)
    $settings = Get-PlacesSettings -Collection Places

    foreach ($setting in $settings)
    {
        if ($setting.Name -eq $placesSetting)
        {
            $scopedValues = $setting.ScopedValues;
            foreach($scope in $scopedValues)
            {
                if ($scope.ScopeValue.BoolValue)
                {
                    $settingEnabled = $true;
                    break;
                }
            }
        }

        if ($settingEnabled)
        {
            break;
        }
    }
    return $settingEnabled
}

$coreRun = $false;
if ($PlacesWebApp)
{
    Set-PlacesCore
    $coreRun = $true;
}
if ($PlacesAdvancedFeatures)
{
    if (!$coreRun)
    {
        Set-PlacesCore
    }
    Set-PremiumFeatures
}
if ($PlacesMobileApp)
{
    $a = "Places.PlacesEnabled"
    $enabledSetting = Get-PlacesSetting $a
    if (!$enabledSetting)
    {
        Write-Error -Message "Please enable PlacesAdvancedFeatures first" -Exception ([System.IO.FileNotFoundException]::new()) -ErrorAction Stop
    }
    Enable-PlacesMobileApp
}
if ($PlacesAnalytics)
{
    $a = "Places.PlacesEnabled"
    $enabledSetting = Get-PlacesSetting $a
    if (!$enabledSetting)
    {
        Write-Error -Message "Please enable PlacesAdvancedFeatures first" -Exception ([System.IO.FileNotFoundException]::new()) -ErrorAction Stop
    }
    Enable-PlacesAnalytics
}