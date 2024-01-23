<#
create a list of mailgroups and shared mailbox from exchange online.

*you need the PS modude for Exchange online and Exchange Administrative-level credentials.
#>
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
#
Remove-item 'C:\Scripts_Gus\Exchange\Results\MailgroupsANDSharedmailboxes.csv' -ErrorAction silentlycontinue
Add-Content 'C:\Scripts_Gus\Exchange\Results\MailgroupsANDSharedmailboxes.csv' "DisplayName,PrimarySmtpAddress,GroupType,ManagedBy,Description"
$results = 'C:\Scripts_Gus\Exchange\Results\MailgroupsANDSharedmailboxes.csv'
# all mail groups in PPf online
$MailGroups = Get-DistributionGroup | Select-Object DisplayName, PrimarySmtpAddress, GroupType, ManagedBy, Description
foreach ($Group in $MailGroups) {
    $DisplayName = $Group.DisplayName
    $PrimarySmtpAddress = $Group.PrimarySmtpAddress
    $GroupType = $Group.GroupType
    $ManagedBy = $Group.ManagedBy
    $Description = $Group.Description
    Add-Content $results "$DisplayName,$PrimarySmtpAddress,$GroupType,$ManagedBy,$Description"
    Start-Sleep -Seconds 1 
    "===>>> $DisplayName ===>>> Done!"
}
"Moving to distribution list now"
#
$sharedmailboxes = Get-mailbox -RecipientTypeDetails sharedmailbox | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails
foreach ($shared in $sharedmailboxes) {
    $DisplayName = $shared.DisplayName
    $PrimarySmtpAddress = $shared.PrimarySmtpAddress
    $GroupType = $shared.RecipientTypeDetails
                                     
                                     
    Add-Content $results "$DisplayName,$PrimarySmtpAddress,$GroupType"
    Start-Sleep -Seconds 1 
    "===>>>  $DisplayName ===>>>  Done!"
}
"Fisnish"
