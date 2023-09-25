Connect-ExchangeOnline

#Create the CSV file with headers
$csvfilename = ".\UsageReport_$((Get-Date -format dd-MM-yy).ToString()).csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,UPN,Disabled,Title,Total Size"

#Filtering for Title specific mailboxes
$Users = Get-User -ResultSize Unlimited -Filter  "Title -like '*CRP*' -or Title -like '*Certified Refuelling Professional*'"

Foreach ($User in $Users){
    #Specifically looking for 4F Users
    $Mailbox = Get-Mailbox $User | Where-Object {$_.PrimarySMTPAddress -like "*@4refuel.com"}
    If ($Mailbox -ne $Null){
        $Stats          =   Get-EXOMailboxStatistics $Mailbox.UserPrincipalName
        $TotalSize      =   $Stats.TotalItemSize
        #Commas in the size value causes issues wtih CSV files, replacing with semis
        $CleanSize      =   $TotalSize -replace ',',';'
        $DisplayName    =   $Stats.DisplayName
        $Title          =   $User.Title
        $UPN            =   $Mailbox.UserPrincipalName
        $Disabled       =   $Mailbox.AccountDisabled
        $MRMPolicy      =   $Mailbox.RetentionPolicy
        #Our Default Policy does nothing, re-writing this variable to reflect this in the report.
        If ($MRMPolicy -eq "Default MRM Policy"){
            $MRMPolicy = "No Policy"
        }

    Add-Content $csvfilename "$DisplayName,$UPN,$Disabled,$Title,$MRMPolicy,$CleanSize"
    }
}
