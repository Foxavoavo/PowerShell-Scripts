#shared mailbox info from specific users.
# includes all user mailgroup and sharemailboxes and report.
# sept 1
# put your usernames in this file ===>>> C:\Scripts_Gus\Exchange\RAW\UsertoLook.csv
# sept2
# runt the code & let it finish 
# You will find the results in this folder ===>>> C:\Scripts_Gus\Exchange\Results\MailGroup_list.csv
#
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
#
Remove-item 'C:\Scripts_Gus\Exchange\Results\MailGroupList.csv' -Force -Recurse -ErrorAction SilentlyContinue
Add-Content 'C:\Scripts_Gus\Exchange\Results\MailGroupList.csv' "UserName,SharedMailboxName,UserRights"
$Results = 'C:\Scripts_Gus\Exchange\Results\MailGroupList.csv'
#raw
$CSV = Import-Csv C:\Scripts_Gus\Exchange\RAW\UserstoLook.csv
'===>>> Users in okay!'
$SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox | Select-Object name | Select-Object -First 6
$Count = $SharedMailboxes.count
'===>>> sharedmailboxes names pulled okay!'
Foreach ($user in $CSV) {
    $Usr = $user.name
    $Email = Get-Mailbox | Where-Object { $_.name -like "$Usr" } | Select-Object primarysmtpaddress
    $UsrMlb = $Email.primarysmtpaddress
    "===>>> mailbox pull okay, running catch, this task might take time, there is $Count sharedmailboxes to search"
    #look for the membership
    Foreach ($SharedMailbox in $SharedMailboxes) {
        $Shrdmlbx = $SharedMailbox.name
        $gsmp = get-mailboxpermission $Shrdmlbx | Where-Object { $_.User -like "$UsrMlb*" } | Select-Object user, accessrights
        If ($Null -ne $gsmp.user) {
            $Rights = $gsmp.accessrights
            "===>>> Found $Usr in $Shrdmlbx with $Rights rights"
            Add-Content $Results "$Usr,$Shrdmlbx,$Rights"
        }
        Else {}
    }
}
'All done'
