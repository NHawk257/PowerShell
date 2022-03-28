Connect-MsolService
Connect-AzureAD

#Two letter country code for expected countries here. Google country codes if you don't know them. Included are Mexico, Canada, and Chile.
$Countries = "MX", "CA", "CL"

#Get all License Plans available:
$licensePlanList = Get-AzureADSubscribedSku

#Creates a CSV for each country with list of users and their licenses. Needs Pivot Table to make useful.
Foreach ($country in $Countries) 
{
    $csvfilename = ".\$Country.csv"
    Remove-Item $csvfilename -Force -ErrorAction SilentlyContinue
    New-Item $csvfilename -Type File -Force | Out-Null
    Add-Content $csvfilename "User,License"
    $users = (Get-MsolUser -UsageLocation $Country -All | where {$_.isLicensed -eq $true}).userPrincipalName
    foreach ($user in $users)
    {
        $userList = Get-AzureADUser -ObjectID $user | Select -ExpandProperty AssignedLicenses | Select SkuID 
        $userList | ForEach { $sku=$_.SkuId ; 
            $licensePlanList | ForEach { 
                If ( $sku -eq $_.ObjectId.substring($_.ObjectId.length - 36, 36) ) {
                 $License= $_.SkuPartNumber 
                 #This is dirty but it works. If there's other licenses in use, add them here or do a find/replace in Excel.
                 $License = $License -replace ("VISIOCLIENT","Visio Online Plan 2")
                 $License = $License -replace ("STREAM","Microsoft Stream Trial")
                 $License = $License -replace ("WIN10_VDA_E5","Windows 10 Enterprise E5")
                 $License = $License -replace ("EMSPREMIUM","Enterprise Mobility + Security E5")
                 $License = $License -replace ("ENTERPRISEPREMIUM","Office 365 E5")
                 $License = $License -replace ("WINDOWS_STORE","Windows Store for Business")
                 $License = $License -replace ("M365_E5_SUITE_COMPONENTS","Microsoft 365 E5 Suite features")
                 $License = $License -replace ("FLOW_FREE","Microsoft Flow Free")
                 $License = $License -replace ("PHONESYSTEM_VIRTUALUSER","Microsoft 365 Phone System - Virtual User")
                 $License = $License -replace ("POWERAPPS_VIRAL","Microsoft Power Apps Plan 2 Trial")
                 $License = $License -replace ("MCOCAP","Common Area Phone")
                 $License = $License -replace ("MEETING_ROOM","Microsoft Teams Rooms Standard")
                 $License = $License -replace ("POWER_BI_STANDARD","Power BI (Free)")
                 $License = $License -replace ("WIN_DEF_ATP","Microsoft Defender for Endpoint")
                 $License = $License -replace ("SPE_E5","Microsoft 365 E5")
                 $License = $License -replace ("RMSBASIC","Rights Management Service Basic Content Protection")
                 $License = $License -replace ("PROJECTPROFESSIONAL","Project Plan 3")
                 $License = $License -replace ("EXCHANGEENTERPRISE","Exchange Online (Plan 2)")

                 Add-Content $csvfilename "$User,$License"
                 } 
                } 
              }
    }
}

#Check if there's users outside of $Countries and create a CSV with them in it. If not, script stops.
$Other_users = (Get-MsolUser -all | where {($_.UsageLocation -ne "US") -and ($_.UsageLocation -ne "CA") -and ($_.UsageLocation -ne "MX") -and ($_.UsageLocation -ne "CL") -and ($_.isLicensed -eq $true)}).userPrincipalName
if ($Other_users)
    {
    $csvfilename = ".\Other_Countries.csv"
    Remove-Item $csvfilename -Force -ErrorAction SilentlyContinue
    New-Item $csvfilename -Type File -Force
    Add-Content $csvfilename "User,License,Country"
    Foreach ($other_user in $Other_Users)
    {
       $userList = Get-AzureADUser -ObjectID $Other_user | Select -ExpandProperty AssignedLicenses | Select SkuID 
          $userList | ForEach { $sku=$_.SkuId ; 
             $licensePlanList | ForEach { 
                 If ( $sku -eq $_.ObjectId.substring($_.ObjectId.length - 36, 36) ) {
                  $License= $_.SkuPartNumber
                     Add-Content $csvfilename "$Other_User,$License"
                  } 
                 } 
    }
    }
   }
Else{}
