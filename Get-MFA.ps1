Connect-MsolService
Connect-ExchangeOnline


$csvfilename = ".\FBFA_MFA.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "User,Email,MFA_Status,MFA_Method,Last_Logon"

$Users = Get-MsolUser -All | ? { $_.UserType -ne "Guest" }
ForEach ($User in $Users) {
    $MFA_Method = $User.StrongAuthenticationMethods.MethodType
    $MFA_State = $User.StrongAuthenticationRequirements.State
    $UserUPN = $user.UserPrincipalName
    $userName = $user.FirstName + ' ' +$user.LastName
    $MailboxStats = Get-MailboxStatistics $user.UserPrincipalName
    $LastLogon = $MailboxStats.LastLogonTime

    Add-Content $csvfilename "$userName,$UserUPN,$MFA_State,$MFA_Method,$lastlogon"
}
