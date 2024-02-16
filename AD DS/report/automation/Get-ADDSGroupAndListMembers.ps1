<# I will pull a list of the AD DS security groups in AD and list their members
this will output multiple list per AD DS group
will report also ADDS groups with no members 
V2
#>
# housekeep
Remove-Item 'C:\scripts_Gus\AD\RAW\All_ADSecurityGroups.csv' -force -ea SilentlyContinue
Get-ChildItem 'C:\scripts_Gus\AD\Report_Results\groups' -Include * -File -Recurse | ForEach-Object { $_.Delete() }
# action
Import-Module activedirectory
Get-ADGroup -filter 'GroupCategory -eq "Security"' -SearchBase 'your distinguished name here' -pro description | Select-Object Name, samaccountname, description | export-csv 'C:\scripts_Gus\AD\RAW\All_ADSecurityGroups.csv' -NoTypeInformation -ea stop
# logging
add-content 'C:\scripts_Gus\AD\Report_Results\groups\Groups_without_Users.csv' "groupname, notes"
$res = 'C:\scripts_Gus\AD\Report_Results\groups\Groups_without_Users.csv'
# array
$groups = import-csv 'C:\scripts_Gus\AD\RAW\All_ADSecurityGroups.csv'
foreach ($group in $groups) {
    $adgroup = $group.samaccountname
    $details = 'C:\scripts_Gus\AD\Report_Results\groups\' + $adgroup + '.txt'
    try {
        $currentgroup = Get-ADGroupMember $adgroup | Select-Object Name
						   
        if ($currentgroup.count -eq 0) {
            "===>>> $adgroup with no members!"
            Add-Content $res "$adgroup,this group has no members"
            Start-Sleep -S 1
        }			   
        else {
            $currentgroup | Out-File $details
            Start-Sleep -S 1
            "===>>> $adgroup Done!"
        }			
    }
    catch {
        "===>>> Issue with this $adgroup"
        Add-Content $res "$adgroup,this group output an error while running Get-ADGroupMember"
    }
}
