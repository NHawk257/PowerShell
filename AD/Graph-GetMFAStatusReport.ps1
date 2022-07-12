<#
=============================================================================================
Credit where credit is due: Primary details sourced from o365reports.com, some tweaking has been done.
Source Link: https://o365reports.com/2022/04/27/get-mfa-status-of-office-365-users-using-microsoft-graph-powershell
============================================================================================
#>

#Define what we consider strong vs weak MFA
[array]$StrongMFAMethods=("Fido2","PasswordlessMSAuthenticator","AuthenticatorApp","WindowsHelloForBusiness")
[array]$WeakMFAMethods=("SoftwareOath","PhoneAuthentication")

#Check if MS Graph module is installed, install it if its not, and then connect
Function Connect_MgGraph
{
 #Check for module installation
 $Module=Get-Module -Name microsoft.graph -ListAvailable
 if($Module.count -eq 0) 
 { 
  Write-Host Microsoft Graph PowerShell SDK is not available  -ForegroundColor yellow  
  $Confirm= Read-Host Are you sure you want to install module? [Y] Yes [N] No 
  if($Confirm -match "[yY]") 
  { 
   Write-host "Installing Microsoft Graph PowerShell module..."
   Install-Module Microsoft.Graph -Repository PSGallery -Scope CurrentUser -AllowClobber -Force
  }
  else
  {
   Write-Host "Microsoft Graph PowerShell module is required to run this script. Please install module using Install-Module Microsoft.Graph cmdlet." 
   Exit
  }
 }

 #Connecting to MgGraph beta
 Select-MgProfile -Name beta
 Write-Host Connecting to Microsoft Graph...
 Connect-MgGraph -Scopes "User.Read.All","UserAuthenticationMethod.Read.All"
}
Connect_MgGraph

#Import/connect to MSOL. The MS Graph Module doesn't give Admin roles currently due to a bug
Import-Module MSOnline -UseWindowsPowerShell #For VSC/PS7 purposes, this isn't needed for regular PS
Connect-Msonline

#Verify connected and advise the user of the connected context
if((Get-MgContext) -ne "")
{
 Write-Host Connected to Microsoft Graph PowerShell using (Get-MgContext).Account account -ForegroundColor Yellow
}
#Reset global counters
$ProcessedUserCount=0
$ExportCount=0
$Result=""  
$Results=@()

#Set output file 
$ExportCSV=".\MfaStatusReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
 
#Get all users filtering out guests
$Users = Get-MgUser -All -Filter "UserType eq 'Member'"  
$TotalUsers = $Users.count

Foreach ($User in $Users) {
 $ProcessedUserCount++
 $Name= $User.DisplayName
 $UPN=$User.UserPrincipalName

 #Write-Progress -Activity "`n     Processed users count: $ProcessedUserCount "`n"  Currently processing user: $Name"
 Write-Progress -Activity "`n     Processed mailbox count: $ProcessedUserCount of $TotalUsers "`n"  Currently Processing: $Name" -PercentComplete ($ProcessedUserCount/$TotalUsers*100)

 #Reset per-user variables
 $Is3rdPartyAuthenticatorUsed="False"
 $MFAPhone="-"
 $MicrosoftAuthenticatorDevice="-"
 $AuthenticationMethod=@()
 $AdditionalDetails=@()
 $MFAStatus="Disabled"
 $RolesAssigned=""

 #Check if account is enabled
 if($User.AccountEnabled -eq $true)
    {
       $SigninStatus="Allowed"
    }
 else
    {
       $SigninStatus="Blocked"
    }
 #Check if accoun is licensed
 if(($User.AssignedLicenses).Count -ne 0)
    {
       $LicenseStatus="Licensed"
    }
 else
    {
       $LicenseStatus="Unlicensed"
    }   
 
 #Get the list of authentication methods for the user
 [array]$MFAData=Get-MgUserAuthenticationMethod -UserId $UPN
 
 #Break down complicated authentication methods into something we can understand
 foreach($MFA in $MFAData)
 { 
   Switch ($MFA.AdditionalProperties["@odata.type"]) 
   { 
    "#microsoft.graph.passwordAuthenticationMethod"
    { # Basic Auth (no MFA)
     $AuthMethod     = 'PasswordAuthentication'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
    } 
    "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"  
    { # Microsoft Authenticator App
     $AuthMethod     = 'AuthenticatorApp'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
     $MicrosoftAuthenticatorDevice=$MFA.AdditionalProperties["displayName"]
    }
    "#microsoft.graph.phoneAuthenticationMethod"                  
    { # Phone authentication (SMS or Voice)
     $AuthMethod     = 'PhoneAuthentication'
     $AuthMethodDetails = $MFA.AdditionalProperties["phoneType", "phoneNumber"] -join ' ' 
     $MFAPhone=$MFA.AdditionalProperties["phoneNumber"]
    } 
    "#microsoft.graph.fido2AuthenticationMethod"                   
    { # FIDO2 key
     $AuthMethod     = 'Fido2'
     $AuthMethodDetails = $MFA.AdditionalProperties["model"] 
    }  
    "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" 
    { # Windows Hello
     $AuthMethod     = 'WindowsHelloForBusiness'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
    }                        
    "#microsoft.graph.emailAuthenticationMethod"        
    { # Email Authentication
     $AuthMethod     = 'EmailAuthentication'
     $AuthMethodDetails = $MFA.AdditionalProperties["emailAddress"] 
    }               
    "microsoft.graph.temporaryAccessPassAuthenticationMethod"   
    { # Temporary Access pass (Backup codes)
     $AuthMethod     = 'TemporaryAccessPass'
     $AuthMethodDetails = 'Access pass lifetime (minutes): ' + $MFA.AdditionalProperties["lifetimeInMinutes"] 
    }
    "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" 
    { # Passwordless
     $AuthMethod     = 'PasswordlessMSAuthenticator'
     $AuthMethodDetails = $MFA.AdditionalProperties["displayName"] 
    }      
    "#microsoft.graph.softwareOathAuthenticationMethod"
    { #3rd Party MFA (Ping, Duo, etc.)
      $AuthMethod     = 'SoftwareOath'
      $Is3rdPartyAuthenticatorUsed="True"            
    }
    
   }
  #Format additional details where available for the methods used 
   $AuthenticationMethod +=$AuthMethod
   if($AuthMethodDetails -ne $null)
   {
    $AdditionalDetails +="$AuthMethod : $AuthMethodDetails"
   }
  }
  #Remove duplicate authentication methods
  $AuthenticationMethod =$AuthenticationMethod | Sort-Object | Get-Unique
  $AuthenticationMethods= $AuthenticationMethod  -join ","
  $AdditionalDetail=$AdditionalDetails -join ", "
  
  #Determine MFA status (Disabled, Weak, Strong)
  foreach($StrongMFAMethod in $StrongMFAMethods)
   {
    if($AuthenticationMethod -contains $StrongMFAMethod)
    {
     $MFAStatus="Strong"
     $AuthenticationMethods = $AuthenticationMethods -replace ",PasswordAuthentication" 
    }
   }
  foreach($WeakMFAMethod in $WeakMFAMethods)
   {
    if(($MFAStatus -ne "Strong") -and ($AuthenticationMethod -contains $WeakMFAMethod))
    {
     $MFAStatus="Weak"
     $AuthenticationMethods = $AuthenticationMethods -replace "PasswordAuthentication," 
    }
   }

  #Get Admin Roles using MSOL
  $Roles=(Get-MsolUserRole -UserPrincipalName $User.UserPrincipalName).Name
  if($Roles.count -eq 0)
   {
    $RolesAssigned="No roles"
    $IsAdmin="False"
   }
  else
   {
    $IsAdmin="True"
    foreach($Role in $Roles)
    {
     $RolesAssigned=$RolesAssigned+$Role
     if($Roles.indexof($role) -lt (($Roles.count)-1))
     {
      $RolesAssigned=$RolesAssigned+","
     }
    }
  }
  
  #Export Results to a CSV
  $ExportCount++
  $Result=@{'Name'=$Name;'UPN'=$UPN;'License Status'=$LicenseStatus;'SignIn Status'=$SigninStatus;'IsAdmin'=$IsAdmin;'AdminRoles'=$RolesAssigned;'Authentication Methods'=$AuthenticationMethods;'MFA Status'=$MFAStatus;'MFA Phone'=$MFAPhone;'Microsoft Authenticator Configured Device'=$MicrosoftAuthenticatorDevice;'Is 3rd-Party Authenticator Used'=$Is3rdPartyAuthenticatorUsed;'Additional Details'=$AdditionalDetail} 
  $Results= New-Object PSObject -Property $Result 
  $Results | Select-Object Name,UPN,'License Status','SignIn Status','IsAdmin','AdminRoles','Authentication Methods','MFA Status','MFA Phone','Microsoft Authenticator Configured Device','Is 3rd-Party Authenticator Used','Additional Details' | Export-Csv -Path $ExportCSV -Notype -Append
 
}

#Prompt user if they want to open the file (if it was created)
if((Test-Path -Path $ExportCSV) -eq "True") 
 {
  Write-Host `nThe output file contains $ExportCount users.
  Write-Host `nThe Output file available in the current working directory with name: $ExportCSV -ForegroundColor Green
    $Prompt = New-Object -ComObject wscript.shell   
  $UserInput = $Prompt.popup("Do you want to open output file?",`   
 0,"Open Output File",4)   
  If ($UserInput -eq 6)   
  {   
   Invoke-Item "$ExportCSV"   
  } 
 }
 else
 {
  Write-Host No users found
 }

 Disconnect-Graph