#Creating this script for Bruce to help with large Teams Voice migration efforts

Connect-MicrosoftTeams

$Users = Import-Csv <filename here>
$ResourceAccounts = Import-Csv <Filename Here>

#User Accounts
Foreach ($U in $Users){
    #Update Users for Dial Pad and assign Direct Routing Phone Number
    Set-CsPhoneNumberAssignment -Identity $U.Email -EnterpriseVoiceEnabled $true 
    #We need to fix the phone number because Excel removes the leading +
    $U.PhoneNumber = "+" + $U.PhoneNumber
    Set-CsPhoneNumberAssignment -Identity $U.Email -PhoneNumber $U.PhoneNumber -PhoneNumberType DirectRouting

    #Update Policies for Voice Routing, Dial Plan, and Emergency Routing
    Grant-CsOnlineVoiceRoutingPolicy -Identity $U.Email -PolicyName $U.VoiceRoutingPolicy
    Grant-CsTenantDialPlan -Identity $U.Email -PolicyName $U.DialPlanPolicy
    Grant-CsTeamsEmergencyCallRoutingPolicy -Identity $U.Email -PolicyName $U.EmergencyRoutingPolicy
}

#Resource Accounts
Foreach ($R in $ResourceAccounts){

    Grant-CsOnlineVoiceRoutingPolicy -Identity $R.Email -PolicyName $R.VoiceRoutingPolicy
}