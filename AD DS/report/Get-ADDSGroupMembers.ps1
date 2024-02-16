# Pull AD DS Group members from specific AD DS Group
# Ad hoc pull
Import-Module activedirectory
$ADGroup = 'Here ADDS group' ## Your AD DS Group Name Here
$Results = 'c:\temp\' + $ADGroup + '.txt'
Get-ADGroupMember $ADGroup | Select-Object Name | out-file $Results

#Array pull
Import-Module activedirectory
$csv = import-csv 'c:\temp\ADDS_ADGroups.csv' ## Lists of AD DS groups to report members.
foreach ($Group in $csv) {
    $ADGroup = $Group.name
    $Results = ('c:\temp\' + $ADGroup + '.txt').Replace('?', '')
    Get-ADGroupMember "$ADGroup" | Select-Object Name | out-file $Results
}
