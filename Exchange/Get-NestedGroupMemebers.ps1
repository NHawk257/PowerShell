#Had a request for all named members of a DL with nested DLs
#Connect-ExchangeOnline

#(Re)set Variables
$Group = 'ProductSupportSales@finning.ca'
$members = New-Object System.Collections.ArrayList
$csvfilename = ".\$Group Nested Members.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Display Name,Primary SMTP,Title"

#Function to loop through nested groups if there is more than 1 level
Function GetMembers($group){
    $Details = Get-DistributionGroupMember $Group -ResultSize Unlimited
    Foreach ($member in $Details){

        If ($Member.RecipientTypeDetails -like "*DistributionGroup*"){
            GetMembers($member.PrimarySMTPaddress)

        }
        Else {
            #If the member has not already been included in one of the nested groups, add to the array for tracking
            If (! $Members.contains($member.PrimarySMTPAddress)){
                $Members.Add($member.PrimarySMTPAddress) >$null
                
                #Add details to CSV
                $SMTPAddress = $Member.PrimarySmtpAddress
                $DisplayName = $Member.DisplayName
                $Title       = $Member.Title
                Add-Content $csvfilename "$DisplayName,$SMTPAddress,$Title"
            }
        }
    }
}

GetMembers($group)

#Dump to display if needed
#$members.GetEnumerator() | Sort-Object