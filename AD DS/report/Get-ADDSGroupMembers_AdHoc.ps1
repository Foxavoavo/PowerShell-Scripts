# Pull Ad DS Group members from specific AD DS Group

# Ad hoc pull
Import-Module activedirectory
$ADGroup = 'Here' ## Your AD DS Group Name Here
$Results = 'c:\temp\' + $ADGroup + '.txt'
Get-ADGroupMember $ADGroup | select Name | out-file $Results

#Array pull
$csv = import-csv 'c:\temp\MARS_ADGroups.csv'
foreach($Group in $csv){
$ADGroup = $Group.name
$Results = ('c:\temp\' + $ADGroup + '.txt').Replace('?','')
Get-ADGroupMember "$ADGroup" | select Name | out-file $Results
}
