<# The idea here is to get a list of group members from one group and add them all to another group
 In this case, the groups are rather large and could not be done by hand

 #>

Connect-AzureAD
# I know this is going away soon but this script was needed quickly. Might need to re-write for Graph AAD

$OldGroup = Get-azureAdGroup -SearchString "ES_Office 365 E5 License" | Select-Object -ExpandProperty ObjectId
$OldMembers = Get-AzureADGroupMember -ObjectId $OldGroup -All $True | Select-Object -ExpandProperty ObjectId

$NewGroup = Get-AzureADGroup -SearchString "ES_Microsoft 365 E5 License" | Select-Object -ExpandProperty ObjectId
$NewMembers = Get-AzureADGroupMember -ObjectId $NewGroup -All $True | Select-Object -ExpandProperty ObjectId


foreach ($OldMember in $OldMembers){

    Add-AzureADGroupMember -ObjectId $NewGroup -RefObjectId $OldMember

}

#Double-checking counts make sense
$NewNewMembers = Get-AzureADGroupMember -ObjectId $NewGroup -All $True | Select-Object -ExpandProperty ObjectId

Write-Host "Old Count was:"
$OldMembers.Count
Write-Host "New Count was:"
$NewMembers.Count
Write-Host "New New Count should be:"
($OldMembers.count) + ($NewMembers.count)
Write-Host "New Count is:"
$NewNewMembers.Count
