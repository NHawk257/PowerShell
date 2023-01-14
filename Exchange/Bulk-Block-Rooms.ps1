Connect-ExchangeOnline

$Rooms = Import-Csv .\Block_Rooms.Csv

Foreach($Room in $Rooms) {

    #Block booking in case someone pulls the room from their auto-complete cache
    Set-CalendarProcessing -Identity $Room.name -AllBookInPolicy $False -AllRequestInPolicy $False 
    #Provide a mailtip live in Outlook warning that the room cannot be booked
    Set-Mailbox -Identity $Room.name -MailTip "This room is currently unavailable for booking"

    $Synced = Get-Mailbox $Room.Name | Select-Object -ExpandProperty IsDirSynced

    If ($Synced -ne "True") {
        #If we can, hide the room from the GAL in EXO
        Set-Mailbox -Identity $Room.name -HiddenFromAddressListsEnabled $true
        Write-host "You can hide $Room in EXO"
    }
    Else{
        #If we cannot hide the room, tell us to do it on-prem
        Write-Host "$Room needs to be hidden from GAL on-prem"
    }

}