Connect-ExchangeOnline

$Rooms = Import-csv .\Surrey_Workspaces.csv
$Rooms = Import-Csv .\Surrey_Rooms.csv

Foreach ($Room in $Rooms){

   # New-Mailbox -Name $Room.alias -DisplayName $Room.DisplayName -Room
   # Set-Mailbox $Room.alias -Type Workspace -ResourceCapacity $Room.capacity
   # Add-DistributionGroupMember -Identity $Room.Facility -Member $Room.alias

   # Set-place $Room.alias -Capacity $room.Capacity -City $Room.City -CountryOrRegion CA -Floor $Room.Floor -PostalCode $Room.Postcode -State BC `
   # -Street $room.Street -GeoCoordinates $Room.GeoCoords -IsWheelChairAccessible ([system.convert]::ToBoolean([int]$Room.Wheelchair)) `
   # -MTREnabled ([system.convert]::ToBoolean([int]$Room.mtr))

    #For Workspaces:
    #Set-CalendarProcessing $Room.Alias -EnforceCapacity $True -MinimumDurationInMinutes 30

    #For Rooms:
    Set-CalendarProcessing -Identity $Room.UPN -AllBookInPolicy $true -BookInPolicy $Null
    #-AutomateProcessing AutoAccept -DeleteComments $False -DeleteSubject $False -ProcessExternalMeetingMessages $True -RemovePrivateProperty $False
}

#Checking details, needed to script creating as a table
$Table = @()
Foreach ($Room in $Rooms){
    #$Details = Get-Place $Room.alias | Select-Object DisplayName,Capacity,City,Country,Localities
    #$Details = Get-mailbox $Room.Alias | Select-object PrimarySMTPAddress,Alias,DisplayName,ResourceCapacity
    $Details = Get-CalendarProcessing $Room.UPN | Select Identity,AllBookInPolicy,AllRequestInPolicy,BookInPolicy,RemoveCanceledMeetings
    $Table += $Details
}
$Table | Format-Table -AutoSize