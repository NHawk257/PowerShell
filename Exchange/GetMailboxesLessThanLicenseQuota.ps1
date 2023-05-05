<#
    Previously, this script assumed every mailbox in the tenant is licensed for a 100GB mailbox (P2/E5)
    This needed to be modified to check the license type first and then compare the mailbox size.
#>

Connect-ExchangeOnline
#Connect-MsolService -- MSOL is Broken AF right now, switching to Graph API
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All

$csvfilename = ".\Under_Quota.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,PrimarySMTP,SKU,ProhibitSendQuota,ProhibitSendReceiveQuota,IssueWarningQuota"

$WrongReceive = 0
$WrongSend = 0
$WrongWarning = 0

#OLD MSOL COMMAND: $E5Users = Get-MsolUser -All | Where-Object {($_.Licenses).AccountSkuID -match "SPE_E5"} | Select -ExpandObject UserPrincipalName

$Mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox

#Check for misconfigured mailbox. Output a count to screen but also output details to a CSV file. 
#We will use the CSV to fix these after reviewing it and removing duplicates.
Foreach ($Mailbox in $mailboxes){

    $E5Check = Get-MgUserLicenseDetail -UserId $Mailbox.PrimarySMTPAddress -ErrorAction SilentlyContinue | Where-Object {$_.SkuPartNumber -match "SPE_E5"} 
    If ($E5Check -ne $Null){
        $ProhibitSend = $mailbox.ProhibitSendQuota
        $ProhibitSendReceive = $mailbox.ProhibitSendReceiveQuota
        $IssueWarning = $mailbox.IssueWarningQuota
        $PrimarySMTP = $Mailbox.PrimarySmtpAddress
        $SKU = $E5Check.SkuPartNumber

        $CleanProhibitSend = $ProhibitSend -replace ',',';'
        $CleanProhibitSendReceive = $ProhibitSendReceive -replace ',',';'
        $CleanIssueWarning = $IssueWarning -replace ',',';'

        if ($ProhibitSend -notlike '99 GB*'){
            $WrongSend++
            Add-Content $csvfilename "$Mailbox,$PrimarySMTP,$SKU,$CleanProhibitSend,$CleanProhibitSendReceive,$CleanIssueWarning"
        }

        if ($ProhibitSendReceive -notlike '100 GB*'){
            $WrongReceive++
            Add-Content $csvfilename "$Mailbox,$PrimarySMTP,$SKU,$CleanProhibitSend,$CleanProhibitSendReceive,$CleanIssueWarning"
        }

        if ($IssueWarning -notlike '98 GB*'){
            $WrongWarning++
            Add-Content $csvfilename "$Mailbox,$PrimarySMTP,$SKU,$CleanProhibitSend,$CleanProhibitSendReceive,$CleanIssueWarning"
        }
    }
    
    Else {}

    

} 

Write-host $WrongReceive "users with the wrong ProhibitSendReceive quota "
Write-host $WrongSend "users with the wrong ProhibitSend quota"
Write-host $WrongWarning "users with the wrong IssueWarning quota"

#Import the CSV file once cleaned and fix misconfigured mailboxes quotas
$BadMailboxes = Import-Csv .\Under_Quota.csv
Foreach ($BadMailbox in $BadMailboxes){

        if ($BadMailbox.ProhibitSendReceiveQuota -notlike '100 GB*'){
            Write-Host $BadMailbox.Name "has a wrong receive quota, correcting..."
            Set-Mailbox $BadMailbox.PrimarySMTP -ProhibitSendReceiveQuota 100GB
        }
        if ($BadMailbox.ProhibitSendQuota -notlike '99 GB*'){
            Write-Host $BadMailbox.Name "has a wrong send quota, correcting..."
            Set-Mailbox $BadMailbox.PrimarySMTP -ProhibitSendQuota 99GB
        }
        if ($BadMailbox.IssueWarningQuota -notlike '98 GB*'){
            Write-Host $BadMailbox.Name "has a wrong warning quota, correcting..."
            Set-Mailbox $BadMailbox.PrimarySMTP -IssueWarningQuota 98GB
        }
        Else {}
    }
    

    
