#Tweaking our previous script to run against a CSV dumped from ShareGate of only ACTIVE Teams for pre-migration review.

# Define a new object to gather output
$OutputCollection=  @()

Write-Verbose "Getting Team Names and Details"
$teams = Import-Csv .\Downloads\2025_07_18_SG_Manage.csv
                
Write-Host "Teams Count is $($teams.count)"

ForEach ($T in $Teams) {
    
    Write-host "Getting details for Team $($T.Name)"
    $Team = Get-Team -GroupId $T.GroupID

    #Get channel details

    $Channels = $null
    $Channels = Get-TeamChannel -GroupId $Team.GroupID
    $ChannelCount = $Channels.count

    # Get Owners, members and guests

    $TeamUsers = Get-TeamUser -GroupId $Team.GroupID
                    
    $TeamOwners = $TeamUsers | Where-Object {$_.Role -like "owner"}
    $TeamMembers = $TeamUsers | Where-Object {$_.Role -like "member"}
    $TeamGuests = $TeamUsers | Where-Object {$_.Role -like "guest"}

    # Put all details into an object

    $output = New-Object -TypeName PSobject 

    $output | add-member NoteProperty "DisplayName" -value $Team.DisplayName
    $output | add-member NoteProperty "Description" -value $Team.Description
    $output | add-member NoteProperty "Visibility" -value $Team.Visibility
    $output | add-member NoteProperty "Archived" -value $Team.Archived
    $output | Add-Member NoteProperty "ChannelCount" -Value $ChannelCount
    $output | Add-Member NoteProperty "OwnerCount" -Value $TeamOwners.count
    $output | Add-Member NoteProperty "Owners" -Value $TeamOwners
    $output | Add-Member NoteProperty "MemberCount" -Value $TeamMembers.count
    $output | Add-Member NoteProperty "Members" -Value $TeamMembers
    $output | Add-Member NoteProperty "GuestCount" -Value $TeamGuests.count
    $output | Add-Member NoteProperty "Guests" -Value $TeamGuests
    $output | add-member NoteProperty "GroupId" -value $Team.GroupId

    $OutputCollection += $output
    }

    # Output collection
    $OutputCollection