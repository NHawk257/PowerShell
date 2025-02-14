<#
This is a purpose built script for bulk updating existing rooms to match our current standards and onboard to Room Finder.

We have various rooms with random naming and non-standard UPNs. These need to be updated in either the cloud or on-prem Exchange
depending on where their home is. This script will update the cloud objects and output a CSV of rooms that need updating on-prem.
#>

#Connect-ExchangeOnline

#Validate rooms and get sync status. Add this to a CSV to manually copy over to spreadsheet provided for easier filtering later...
$Rooms = Import-Csv '.\Finning Global Rooms List.csv'
$csvfilename = ".\RoomSyncStatus.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "UPN,SyncStatus"

Foreach ($R in $Rooms){
    
    try {
        $Mailbox = Get-Mailbox $R.ExistingUPN -ErrorAction stop,SilentlyContinue| Select-Object WindowsEmailAddress,IsDirSynced

                $UPN = $Mailbox.WindowsEmailAddress
                $DirSync = $Mailbox.IsDirSynced
                Add-Content $csvfilename "$UPN,$DirSync"

    }
    catch {
        Write-Host $R.ExistingUPN "is not a valid mailbox" -ForegroundColor Red -BackgroundColor Gray 
    }
}

#Re-import rooms once the DirSynced column has been added
$Rooms = Import-Csv '.\Finning Global Rooms List.csv'
$CloudRooms = $Rooms | Where-Object {$_.SyncStatus -eq "False"}

Foreach ($C in $CloudRooms){

    $NewSMTP = $C.NewUPN
    #Set-Mailbox $C.ExistingUPN -DisplayName $c.NewDisplayName -ResourceCapacity $C.Capacity -EmailAddresses @{Add = "$NewSMTP"}
   # Set-Mailbox $C.ExistingUPN -WindowsEmailAddress $NewSMTP #this has to be done in two steps to keep the existing SMTP in tact as a proxy, otherwise it deletes that
    
    If ($C.Newbldgname -ne ""){
        Write-Host "I NEED A NEW HOME"
        #Create the RL the fist time... How do we iterate that through then??
        #Add-DistributionGroupMember -Identity $C.Newbldgname -Member $C.ExistingUPN
    }

   #Checking for any rooms that were indicated as not needing Places changes made, Trevor noted this in the AUDIO column...
    If ($C.Audio -like "*No Changes*"){
        Write-Host "No Places changes to " $C.NewDisplayName
    }

   # else{
    #    Write-Host "I'm going thru changes...."
     #   Set-Place $C.ExistingUPN -Capacity $C.Capacity -Street $C.Street -State $c.State -CountryOrRegion $C.Country -PostalCode $C.PostalCode -AudioDeviceName $C.Audio `
     #   -DisplayDeviceName $C.Display -Floor $C.Floor -GeoCoordinates $C.GeoCoords -IsWheelChairAccessible $C.Wheelchairaccess!!!! -MTREnabled $C.MTR -Phone $C.Phone `
     #   -VideoDeviceName $C.Video
   # }
}