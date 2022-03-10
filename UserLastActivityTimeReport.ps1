#Accept input parameter
Param
(
    [Parameter(Mandatory = $false)]
    [int]$InactiveDays,
    [switch]$UserMailboxOnly,
    [switch]$ReturnNeverLoggedInMBOnly,
    [string]$UserName,
    [string]$Password    
)

Connect-ExchangeOnline

Function Get_LastLogonTime
{
 $MailboxStatistics=Get-MailboxStatistics -Identity $upn
 $LastActionTime=$MailboxStatistics.LastUserActionTime
 Write-Progress -Activity "`n     Processed mailbox count: $MBUserCount of $MBTotal "`n"  Currently Processing: $DisplayName" -PercentComplete ($MBUserCount/$MBTotal*100)
 
 #Retrieve lastlogon time and then calculate Inactive days 
 if($LastActionTime -eq $null)
 { 
   $LastActionTime ="Never Logged In" 
   $InactiveDaysOfUser="-" 
 } 
 else
 { 
   $InactiveDaysOfUser= (New-TimeSpan -Start $LastActionTime).Days
   #Convert Last Action Time to Friendly Time
   if($friendlyTime.IsPresent) 
   {
    $FriendlyLastActionTime=ConvertTo-HumanDate ($LastActionTime)
    $friendlyLastActionTime="("+$FriendlyLastActionTime+")"
    $LastActionTime="$LastActionTime $FriendlyLastActionTime" 
   }
 }
 
 #Inactive days based filter 
 if($InactiveDaysOfUser -ne "-"){ 
 if(($InactiveDays -ne "") -and ([int]$InactiveDays -gt $InactiveDaysOfUser)) 
 { 
  return
 }} 

 #Filter result based on user mailbox 
 if(($UserMailboxOnly.IsPresent) -and ($MBType -ne "UserMailbox"))
 { 
  return
 } 

 #Never Logged In user
 if(($ReturnNeverLoggedInMBOnly.IsPresent) -and ($LastActionTime -ne "Never Logged In"))
 {
  return
 }




 #Export result to CSV file 
 $Result=@{'UserPrincipalName'=$upn;'DisplayName'=$DisplayName;'LastUserActionTime'=$LastActionTime;'CreationTime'=$CreationTime;'InactiveDays'=$InactiveDaysOfUser;'MailboxType'=$MBType } 
 $Output= New-Object PSObject -Property $Result 
 $Output | Select-Object UserPrincipalName,DisplayName,LastUserActionTime,InactiveDays,CreationTime,MailboxType | Export-Csv -Path $ExportCSV -Notype -Append
} 


Function main()
{

 #Set output file 
 $ExportCSV=".\LastAccessTimeReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"


 $Result=""  
 $Output=@() 
 $MBUserCount=0 

  #Get all mailboxes from Office 365
 
  Write-Progress -Activity "Getting Mailbox details from Office 365..." -Status "Please wait." 
  $MBTotal = (Get-Mailbox -ResultSize Unlimited | Where{$_.DisplayName -notlike "Discovery Search Mailbox"}).count
  Get-Mailbox -ResultSize Unlimited | Where{$_.DisplayName -notlike "Discovery Search Mailbox"} | ForEach-Object{ 
  $upn=$_.UserPrincipalName 
  $CreationTime=$_.WhenCreated
  $DisplayName=$_.DisplayName 
  $MBType=$_.RecipientTypeDetails
  $MBUserCount++
  Get_LastLogonTime
 }

 #Open output file after execution 
 Write-Host `nScript executed successfully
 if((Test-Path -Path $ExportCSV) -eq "True")
 {
  Write-Host "Detailed report available in: $ExportCSV" 
  $Prompt = New-Object -ComObject wscript.shell  
  $UserInput = $Prompt.popup("Do you want to open output file?",`  
 0,"Open Output File",4)  
  If ($UserInput -eq 6)  
  {  
   Invoke-Item "$ExportCSV"  
  } 
 }
 Else
 {
  Write-Host No mailbox found
 }
 }
 . main

