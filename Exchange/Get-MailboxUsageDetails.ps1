Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All
Connect-ExchangeOnline

#Create the CSV file with headers
$csvfilename = ".\UsageReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "DisplayName,UPN,Disabled,TotalSize,Quota,Location,Type,Policy"

#Get all mailboxes in tenant
$Mailboxes = Get-Mailbox -ResultSize Unlimited -reci

Foreach ($Mailbox in $Mailboxes){
    
        $Stats          =   Get-EXOMailboxStatistics $Mailbox.UserPrincipalName
        $TotalSize      =   $Stats.TotalItemSize
        #Commas in the size value causes issues wtih CSV files, replacing with semis
        $CleanSize      =   $TotalSize -replace ',',';'
        $DisplayName    =   $Mailbox.DisplayName
        $UPN            =   $Mailbox.WindowsLiveID
        $Disabled       =   $Mailbox.AccountDisabled
        $Quota          =   $Mailbox.ProhibitSendReceiveQuota
        #Commas in the size value causes issues wtih CSV files, replacing with semis
        $CleanQuota     =   $Quota -replace ',',';'
        $Type           =   $Mailbox.RecipientTypeDetails
        $Location       =   $Mailbox.UsageLocation
        $MRMPolicy      =   $Mailbox.RetentionPolicy
        #Our Default Policy does nothing, re-writing this variable to reflect this in the report.
        If ($MRMPolicy -eq "Default MRM Policy"){
            $MRMPolicy = "No Policy"
        }

    Add-Content $csvfilename "$DisplayName,$UPN,$Disabled,$CleanSize,$CleanQuota,$Location,$Type,$MRMPolicy"
    
}
