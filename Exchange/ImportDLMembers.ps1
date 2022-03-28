 Connect-ExchangeOnline

 #Input the CSV name/path and the group name:

 $CSVPath = ".\AIAMassTimberCommittee.csv"
 $GroupName = "AIAmasstimber"
 
 
 $DLMembers = Import-Csv $CSVPath | select EmailAddress


   foreach ($DLMember in $DLMembers)
    {
        Add-DistributionGroupMember -identity $GroupName -Member $DLMember.EmailAddress
       
    }