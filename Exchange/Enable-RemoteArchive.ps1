#Copyright (c) 2016 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#
#This script sets msExchArchiveGUID, msExchArchiveName and msExchRemoteRecipientType of the user. Then the attributes will get synced to cloud and ForwardSync will enable archive for the user.
#
Clear-Host
Write-Host "This script is to be used to enable an In-Place Archive for a user which has been synced from on-prem AD"
Write-Host "Simply enabling this achive is not enough. Once this script has run successfully, please run a manual AD Sync"
Write-Host "Once the sync has been run, verify in the EXO Admin Center that the user has an enabled archive."
Write-host ""

$domain_controller  = Read-Host -Prompt "Please provide a domain controller"
$domain_account     = Read-Host -Prompt "Please provide a domain admin including the domain"
$identity           = Read-Host -Prompt "Please provide the AD username for the account which you need to enable"

if($AD_cred -eq $null) { $AD_cred = (Get-Credential $domain_account) }
    if($ad_session -eq $null -or $ad_session.State -ne "Opened")
    {
        $ad_session = New-PSSession -Computername $domain_controller -Credential $AD_cred
        Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
        Import-PSSession -Session $ad_session -Module ActiveDirectory
    }

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!DO NOT TOUCH ANYTHING BELOW THIS LINE. THIS IS FROM THE MICROSOFT SCRIPT!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Param 
(
    [Parameter(Mandatory=$true)]
    [string] $Identity,
    
    [Parameter(Mandatory=$false)]
    [string] $ArchiveName
)

# Get the ADObject.
function TryGetADObject($identity, [ref]$user)
{
    $domainName = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName;
    $ldapBindString = "LDAP://{0}/RootDse" -f $domainName;
    $rootDse = New-Object System.DirectoryServices.DirectoryEntry($ldapBindString);
    $defaultNamingContext = [string] $rootDse.Properties["defaultNamingContext"];
	$rootDse.Dispose();

    $ldapQueryBindString = "LDAP://{0}/{1}" -f $domainName, $defaultNamingContext;
    $searchRoot = New-Object System.DirectoryServices.DirectoryEntry($ldapQueryBindString)
    $searcher = New-Object System.DirectoryServices.DirectorySearcher;
    $searcher.SearchRoot = $searchRoot;
    $searcher.Filter = "(samaccountname=$identity)";
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree;
    $result = $searcher.FindAll();

    if ($result.Count -eq 1)
    {
        $user.Value = New-Object System.DirectoryServices.DirectoryEntry($result[0].Path);
    }
    else
    {
        if ($result.Count -eq 0)
        {
            Write-Error "Could not find AD Object with name=($identity)."
        }
        else
        {
            Write-Error "More than one AD Object with name=($identity) are found."
        }

        $searcher.Dispose();
        return $false;
    }

    $searcher.Dispose();
    return $true;
}

# msExRemoteRecipientType is a COMObject, which is a large integer.
function GetRemoteRecipientTypeValue($largeInteger)
{
    $highPart = $largeInteger.GetType().InvokeMember("HighPart", "GetProperty", $null, $largeInteger, $null);
    $lowPart  = $largeInteger.GetType().InvokeMember("LowPart", "GetProperty", $null, $largeInteger, $null);
    $bytes = [System.BitConverter]::GetBytes($highPart);
    $tmp = [System.Byte[]]@(0, 0, 0, 0, 0, 0, 0, 0);
    [System.Array]::Copy($bytes, 0, $tmp, 4, 4);
    $highPart = [System.BitConverter]::ToInt64($tmp, 0);
    $bytes = [System.BitConverter]::GetBytes($lowPart);
    $lowPart = [System.BitConverter]::ToUInt32($bytes, 0);
    return $lowPart + $highPart;
}

# Set msExRemoteRecipientType.
function SetRemoteRecipientTypeValue([System.DirectoryServices.DirectoryEntry]$user, [UInt64]$value)
{
    $byteArray = [System.BitConverter]::GetBytes($value);
    $highPart = [System.BitConverter]::ToInt32($byteArray, 4);
    $lowPart = [System.BitConverter]::ToInt32($byteArray, 0);
    $largeInteger = new-object -ComObject LargeInteger;
    [Void] $largeInteger.GetType().InvokeMember("HighPart", "SetProperty", $null, $largeInteger, $highPart);
    [Void] $largeInteger.GetType().InvokeMember("LowPart", "SetProperty", $null, $largeInteger, $lowPart);
    $user.msExchRemoteRecipientType.Value = $largeInteger;
}

$PROVISIONARCHIVE = 0x2;
$DEPROVISIONARCHIVE= 0x10;

Import-Module ActiveDirectory;
$user = New-Object PSObject;

if (!(TryGetADObject -identity $Identity -user ([ref]$user)))
{
    return;
}

if ($user.msExchRemoteRecipientType -ne $null)
{
    $userRemoteRecipientType = GetRemoteRecipientTypeValue -largeInteger ($user.msExchRemoteRecipientType.Value);
}

if (($userRemoteRecipientType -band $PROVISIONARCHIVE) -eq $PROVISIONARCHIVE)
{
    Write-Error "Archive for this user is already present.";
    return;
}

try
{
    # If msExchDisabledArchiveGuid is not null, then we should recover the old archive. Otherwise, create a new GUID as the ArchiveGUID.
    if (($user.msExchArchiveGUID.Value -eq $null) -or ((New-Object System.Guid (,([Byte[]]($user.msExchArchiveGUID.Value)))).Guid -eq [Guid]::Empty))
    {
        if (($user.msExchDisabledArchiveGuid.Value -ne $null) -and ((New-Object System.Guid (,([Byte[]]($user.msExchDisabledArchiveGuid.Value)))).Guid -ne [Guid]::Empty))
        {
            $user.msExchArchiveGUID.Value = $user.msExchDisabledArchiveGuid.Value;
        }
        else
        {
            $user.msExchArchiveGUID.Value = [Guid]::NewGuid().ToByteArray();
        }
    }

    if ([string]::IsNullOrEmpty($ArchiveName))
    {
        $ArchiveName = "In-Place Archive - $Identity";
    }

    $user.msExchArchiveName.Value = $ArchiveName;
    $userRemoteRecipientType = ($userRemoteRecipientType -band (-bnot $DEPROVISIONARCHIVE)) -bor $PROVISIONARCHIVE;
    SetRemoteRecipientTypeValue -user $user -value $userRemoteRecipientType;
    $user.CommitChanges();
}
catch 
{
    Write-Error "Errors encountered when trying to write to ADObject $Identity. Exception: $($_.Exception.Message)";
}
finally
{
    $user.Dispose();
}
