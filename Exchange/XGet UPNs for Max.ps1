<#
    The idea here is to check the list of mailboxes I provided Max with against AAD/EXO and see if there are ever any cases where the PrimarySMTP <> UPN
    Max wants a list of UPNs from AAD but I'm fairly sure that's going to be the same as the Primary SMTP 9/10 times
    Honestly, probably trash this and never post it unless you really need to...
#>
Connect-AzureAD
Connect-ExchangeOnline

$Mailboxes = Import-Csv 'C:\users\evan.ashdown\OneDrive - Finning\Documents\Downloads\EvanReport_Mailboxes.csv'

#Reset Arrays to be empty
$MismatchUPNs = @()
$Deleted = @()

Foreach ($Mailbox in $Mailboxes){

    try {
        #Try to get the AAD User object for the matching SMTP address
        $UPN = Get-AzureADUser -ObjectId $Mailbox.PrimarySMTP -ErrorAction Stop,SilentlyContinue | Select-Object -ExpandProperty UserPrincipalName
        #Verify the UPN of the AAD user object matches the Primary SMTP address, if not add it to the array
        If ($UPN -ne $Mailbox.PrimarySMTP){
            $MismatchUPNs += $UPN
        }
    }
    catch {
        Try{
            #Try to get a mailbox with the SMTP address provided as it clearly isn't matched to a UPN
            $UPN = Get-Mailbox $Mailbox.PrimarySMTP -ResultSize Unlimited -ErrorAction Stop,SilentlyContinue | Select-Object -ExpandProperty UserPrincipalName
            #Obviously the UPN and SMTP aren't going to match so check that and record it in the array
            If ($UPN -ne $Mailbox.PrimarySMTP){
                $MismatchUPNs += $Mailbox.PrimarySMTP
            }
        }
        Catch{
            #If we cannot find a mailbox with that SMTP address, we must assume the mailbox has been deleted
            $Deleted += $Mailbox.PrimarySMTP
        }
    }
}

$Table = @()
Foreach ($SMTP in $MismatchUPNs){
        $Compare = "" | Select-object SMTP,UPN
        $Compare.SMTP = $SMTP
        $Compare.UPN = Get-mailbox $SMTP | Select-Object -ExpandProperty UserPrincipalName
        $Table += $Compare
}
$Table | Format-Table
