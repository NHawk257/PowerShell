﻿<#
=============================================================================================
This script has been heavily modified from its source, documentation online might not be accurate
Always ensure you review a script fully to understand what is happening before you run it...
Source credit: https://o365reports.com/2023/05/23/get-office-365-room-mailbox-usage-statistics-using-powershell/
============================================================================================
#>
Param
(
    [switch]$OnlineMeetingOnly,
    [switch]$ShowTodaysMeetingsOnly,
    [String]$OrgEmailId,
    [switch]$CreateSession,
    [string]$TenantId,
    [string]$ClientId,
    [string]$CertificateThumbprint
)

#Function to check and install Beta Graph module as the Beta cmdlets are used for this
Function Connect_MgGraph
{
 $MsGraphBetaModule =  Get-Module Microsoft.Graph.Beta -ListAvailable
 if($MsGraphBetaModule -eq $null)
 { 
    Write-host "Important: Microsoft Graph Beta module is unavailable. It is mandatory to have this module installed in the system to run the script successfully." 
    $confirm = Read-Host Are you sure you want to install Microsoft Graph Beta module? [Y] Yes [N] No  
    if($confirm -match "[yY]") 
    { 
        Write-host "Installing Microsoft Graph Beta module..."
        Install-Module Microsoft.Graph.Beta -Scope CurrentUser -AllowClobber
        Write-host "Microsoft Graph Beta module is installed in the machine successfully" -ForegroundColor Magenta 
    } 
    else
    { 
        Write-host "Exiting. `nNote: Microsoft Graph Beta module must be available in your system to run the script" -ForegroundColor Red
        Exit 
    } 
 }
 Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
 #Client/Cert auth option if specified
 if(($TenantId -ne "") -and ($ClientId -ne "") -and ($CertificateThumbprint -ne ""))  
 {  
    Connect-MgGraph  -TenantId $TenantId -AppId $ClientId -CertificateThumbprint $CertificateThumbprint -ErrorAction SilentlyContinue -ErrorVariable ConnectionError|Out-Null
    if($ConnectionError -ne $null)
    {    
        Write-Host $ConnectionError -Foregroundcolor Red
        Exit
    }
 }
 #Otherwise, user based credentials
 else
 {
    Connect-MgGraph -Scopes "Place.Read.All,User.Read.All,Calendars.Read.Shared"  -ErrorAction SilentlyContinue -Errorvariable ConnectionError |Out-Null
    if($ConnectionError -ne $null)
    {
        Write-Host "$ConnectionError" -Foregroundcolor Red
        Exit
    }
 }
 Write-Host "Microsoft Graph Beta PowerShell module is connected successfully" -ForegroundColor Green
 Write-Host "`nNote: If you encounter module related conflicts, run the script in a fresh Powershell window." -ForegroundColor Yellow
}

Connect_MgGraph
Connect-ExchangeOnline
#####################################
#       ~   Actual Script   ~       #
#####################################

#Setup Variables and file paths
$ExportSummaryCSV=".\RoomMailboxUsageSummaryReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm-ss` tt).ToString()).csv"  
$ExportSummary=""
$startDate=(Get-date).AddDays(-30).Date
$EndDate=(Get-date).AddDays(0).Date
$MbCount=0
$PrintedMeetings=0

#Calculate Number of Workdays for Maths
$difference = (New-TimeSpan -Start $startdate -End $enddate).Days
$days = [Math]::Ceiling($difference)
$workdays = 0..$days | ForEach-Object {
    $startdate
    $startdate = $startdate.AddDays(1)
    } |  Where-Object { $_.DayOfWeek -gt 0 -and $_.DayOfWeek -lt 6 } | Measure-Object | Select-Object -ExpandProperty Count
    

$startDate=(Get-date).AddDays(-30).Date
$EndDate=(Get-date).AddDays(0).Date

#To make a trend line rather than summary, we need an array of dates to iterate through
    $Dates = @()
    while ($startDate -lt $endDate) {
        $Dates += $startDate.ToString("yyyy-MM-dd")
        
        $startDate = $startDate.AddDays(+1)
    }


#You NEED minimum REVIEWER access to each Room Calendar to run this report
#See bottom of the script for a quick way to add that for your account
#Using EXO to get all resources based on RL memberships
$rooms = get-distributionGroupMember edmhorooms | Get-place

Foreach ($date in $Dates){
foreach ($Room in $Rooms){
 $RoomAddress=$Room.Identity
 $RoomName=$Room.DisplayName
 $Capacity = $Room.Capacity
 $MeetingCount=0
 $MbCount++
 $RoomUsage=0
 $OnlineMeetingCount=0
 $AllDayMeetingCount=0
 $AvailableHours=0
 $RoomUsageHrs=0
 $RoomUsagePerc=0


 Get-MgBetaUserCalendarView  -UserId $RoomAddress -StartDateTime $Date -EndDateTime $Date -All | ForEach-Object {
  Write-Progress -Activity "`n     Processing room: $MbCount - $RoomAddress : Meeting Count - $MeetingCount"
  if($_.IsCancelled -eq $false)
  {
   $Print=1
   $MeetingCount++
   $Organizer=$_.Organizer.EmailAddress.Address
   $MeetingSubject=$_.Subject
   $IsAllDayMeeting=$_.IsAllDay
   $IsOnlineMeeting=$_.IsOnlineMeeting
   if($IsOnlineMeeting -eq $true)
   {
    $OnlineMeetingCount++
   }
   if($IsAllDayMeeting -eq $true)
   {
    $AllDayMeetingCount++
   }
   $MeetingStartTimeZone=$_.OriginalStartTimeZone
   [Datetime]$MeetingStart=$_.Start.DateTime
   $MeetingStartTime=$MeetingStart.ToLocalTime()
   [Datetime]$MeetingEnd=$_.End.DateTime
   $MeetingEndTime=$MeetingEnd.ToLocalTime()
   if($_.IsAllDay -eq $true)
   {
    $MeetingDuration="480"
   }
   else
   { 
    $MeetingDuration=($MeetingEndTime-$MeetingStartTime).TotalMinutes
   }
   $RoomUsage =$RoomUsage+$MeetingDuration

   #Math out available hours for the resource and usage percentage
   If ($Room.Type -eq "Room"){
    $AvailableHours = 8
   }
   Else{
    $AvailableHours = 8 * $Capacity
   }
   $RoomUsageHrs = $RoomUsage/60
   $RoomUsagePerc = $RoomUsageHrs/$AvailableHours
   If ($RoomUsagePerc -gt 1){
    $RoomUsagePerc = 1
   }

   #Detailed Report
   #if($Print -eq 1)
   #{
   # $PrintedMeetings++
   # $ExportResult=[PSCustomObject]@{'Room Name'=$RoomName;'Organizer'=$Organizer;'Subject'=$MeetingSubject;'Start Time'=$MeetingStartTime;'End Time'=$MeetingEndTime;'Duration(in mins)'=$MeetingDuration;'TimeZone'=$MeetingStartTimeZone;'Total Attendees Count'=$AllAttendeesCount;'Required Attendees'=$ReqiredAttendees;'Optional Attendees'=$OptionalAttendees;'Is Online Meeting'=$IsOnlineMeeting;'Is AllDay Meeting'=$IsAllDayMeeting}
   # $ExportResult | Export-Csv -Path $ExportCSV -Notype -Append
   #}
  }
 }  
 #Summary Report
    $PrintedMeetings++
    $ExportSummary=[PSCustomObject]@{'date'=$date;'Room Name'=$RoomName;'Total Meeting Count'=$MeetingCount;'Online Meeting Count'=$OnlineMeetingCount;'Full Day Meetings'=$AllDayMeetingCount;'Usage Duration(in mins)'=$RoomUsage;'Usage Duration(in hrs)'=$RoomUsageHrs;'Usage %'=$RoomUsagePerc;'Capacity'=$Capacity}
    $ExportSummary | Export-Csv -Path $ExportSummaryCSV -Notype -Append
}
}

####################################
# Open output file after execution #
####################################
Write-Host `nScript executed successfully
if((Test-Path -Path $ExportSummaryCSV) -eq "True")
{
    Write-Host "`nExported report has" -NoNewLine ; Write-Host " $PrintedMeetings meeting(s)" -ForegroundColor Magenta
    Write-Host `nSummary report available in: -NoNewline -ForegroundColor Yellow; Write-Host " $ExportSummaryCSV `n" 
}
else
{
    Write-Host "No meetings found" -ForegroundColor Red
}

#Adding Room Permissions as required, you will need to reconnect Graph after the permissions are added
<#
Connect-ExchangeOnline
$AdminAccount = "admin@domain.net"

Foreach ($room in $rooms){
    $RoomAddress=$Room.identity
    Add-MailboxFolderPermission "${roomaddress}:\calendar" -User $AdminAccount -AccessRights REVIEWER -ErrorAction SilentlyContinue
}
#>
