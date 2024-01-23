#mail info
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
#
Remove-item 'C:\Scripts_Gus\Exchange\Results\MailgroupsANDSharedmailboxes.csv' -ea silentlycontinue
Add-Content 'C:\Scripts_Gus\Exchange\Results\MailgroupsANDSharedmailboxes.csv' "DisplayName,PrimarySmtpAddress,GroupType,ManagedBy,Description"
$res = 'C:\Scripts_Gus\Exchange\Results\MailgroupsANDSharedmailboxes.csv'
# all mail groups in PPf online
$mailgroupds = Get-DistributionGroup | Select-Object DisplayName, PrimarySmtpAddress, GroupType, ManagedBy, Description
foreach ($group in $mailgroupds) {
    $DisplayName = $group.DisplayName
    $PrimarySmtpAddress = $group.PrimarySmtpAddress
    $GroupType = $group.GroupType
    $ManagedBy = $group.ManagedBy
    $Description = $group.Description
    Add-Content $res "$DisplayName,$PrimarySmtpAddress,$GroupType,$ManagedBy,$Description"
    Start-Sleep -s 1 
    "===>>> $DisplayName ===>>> Done!"
}
"Moving to distribution list now"
#
$sharedmailboxes = Get-mailbox -RecipientTypeDetails sharedmailbox | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails
foreach ($shared in $sharedmailboxes) {
    $DisplayName = $shared.DisplayName
    $PrimarySmtpAddress = $shared.PrimarySmtpAddress
    $GroupType = $shared.RecipientTypeDetails
                                     
                                     
    Add-Content $res "$DisplayName,$PrimarySmtpAddress,$GroupType"
    Start-Sleep -s 1 
    "===>>>  $DisplayName ===>>>  Done!"
}
"Fisnish"
