Connect-AzureAD
#Get List of Available SKUs if needed
Get-AzureADSubscribedSku | Select-Object SkuPartNumber

#Create properly formatted objects for License Assignment
$E5license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$F3license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses

#Adjust SkuPartNumber to whatever you need it to be
#Any missing license will cause a failure. If removing different ones, you need multiple variables unless they rely on eachother like F3+F5
$E5license.RemoveLicenses += (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value SPE_E5 -EQ).skuid
$F3license.RemoveLicenses += (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value SPE_F1 -EQ).skuid
$F3license.RemoveLicenses += (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value SPE_F5_SECCOMP -EQ).skuid

$Users = Import-Csv .\Users.csv

Foreach ($user in $users){
    #This will fail if the user doesn't have any of the licenses listed, need to check for which the user has based on CSV
    #If there are more, add more ElseIf checks
    If ($User.ProductID1 -like "*SPE_E5*"){
        Set-AzureADUserLicense -ObjectId $User.ObjectID -AssignedLicenses $E5license

    }
    elseif ($user.ProductID1 -like "*SPE_F1*") {
        Set-AzureADUserLicense -ObjectId $User.ObjectID -AssignedLicenses $F3license
    }
    else { #Generic Catch-all failure, nothing should hit this
        Write-Host $User.Displayname "Does not have any of the listed licenses, please review"
    }
}