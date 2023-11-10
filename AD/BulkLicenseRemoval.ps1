Connect-AzureAD
#Get List of Available SKUs
Get-AzureADSubscribedSku | Select-Object SkuPartNumber

$E5license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$F3license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses

$E5license.RemoveLicenses += (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value SPE_E5 -EQ).skuid
$F3license.RemoveLicenses += (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value SPE_F1 -EQ).skuid
$F3license.RemoveLicenses += (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value SPE_F5_SECCOMP -EQ).skuid
#Adjust SkuPartNumber to whatever you need it to be

$Users = Import-Csv .\Users.csv

Foreach ($user in $users){
    #This will fail if the user doesn't have any of the licenses listed, need to check for which the user has based on CSV
    If ($User.ProductID1 -like "*SPE_E5*"){
        Set-AzureADUserLicense -ObjectId $User.ObjectID -AssignedLicenses $E5license

    }
    elseif ($user.ProductID1 -like "*SPE_F1*") {
        Set-AzureADUserLicense -ObjectId $User.ObjectID -AssignedLicenses $F3license
    }
    else {
        Write-Host $User.Displayname "Does not have any of the listed licenses, please review"
    }
}