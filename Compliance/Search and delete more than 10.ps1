# Some information for the batch
$SearchName = "INC000005242548"
# Some information to identify the messages we want to purge
$Sender = "MCampol@oib.ca"
$Subject = "Osoyoos Indian Band, June 2022 RFQ!!!"
$Location = "All"
# Date range for the search - make this as precise as possible
#$StartDate = "10-Mar-2020"
#$EndDate = "13-Mar-2020"
#$Start = (Get-Date $StartDate).ToString('yyyy-MM-dd')   
#$End = (Get-Date $EndDate).ToString('yyyy-MM-dd')
#$ContentQuery = '(c:c)(received=' + $Start + '..' + $End +')(senderauthor=' + $Sender + ')(subjecttitle="' + $Subject + '")'

$ContentQuery = '(from=' + $Sender + ')(subject="' + $Subject + '")'

If (Get-ComplianceSearch -Identity $SearchName) {
   Write-Host "Cleaning up old search"
   Try {
      $Status = Remove-ComplianceSearch -Identity $SearchName -Confirm:$False  } 
   Catch {
       Write-Host "We can't clean up the old search" ; break }}

New-ComplianceSearch -Name $SearchName -ContentMatchQuery $ContentQuery -ExchangeLocation $Location -AllowNotFoundExchangeLocationsEnabled $True | Out-Null
                                                                            
Write-Host "Starting Search..."
Start-ComplianceSearch -Identity $SearchName | Out-Null
$Seconds = 0
While ((Get-ComplianceSearch -Identity $SearchName).Status -ne "Completed") {
  
   Write-Host "Still searching... (" $Seconds ")"
   Sleep -Seconds 30 
   $Seconds = $Seconds+30
}

$ItemsFound = (Get-ComplianceSearch -Identity $SearchName).Items
Write-Host "Items Found: "$ItemsFound""

If ($ItemsFound -gt 0) {
   $Stats = Get-ComplianceSearch -Identity $SearchName | Select -Expand SearchStatistics | Convertfrom-JSON
   $Data = $Stats.ExchangeBinding.Sources |?{$_.ContentItems -gt 0}
   Write-Host ""
   Write-Host "Total Items found matching query:" $ItemsFound 
   Write-Host ""
   Write-Host "Items found in the following mailboxes"
   Write-Host "--------------------------------------"
   Foreach ($D in $Data)  {Write-Host $D.Name "has" $D.ContentItems "items of size" $D.ContentSize }
   Write-Host " "
   #$Iterations = 0; $ItemsProcessed = 0
   While ($ItemsProcessed -lt $ItemsFound) {
       $Iterations++
       Write-Host "Deleting items... (" $Iterations ")"
       New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete -Confirm:$False | Out-Null
       While ((Get-ComplianceSearchAction -Identity ($SearchName + '_Purge')).Status -ne "Completed") 
       { # Let the search action complete
           Sleep -Seconds 2 }
       $ItemsProcessed = $ItemsProcessed + 10 # Can remove a maximum of 10 items per mailbox
       # Remove the search action so we can recreate it
       Remove-ComplianceSearchAction -Identity ($SearchName + '_Purge') -Confirm:$False  }}
  Else {
       Write-Host "No items found" }

Write-Host "All done!"
