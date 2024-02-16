# Add AD DS objects to AD DS groups
#provide a csv list of names of AD DS objects to add to the specified AD DS group.
Import-Module activedirectory
$csv = import-csv 'C:\scripts_Gus\AD\RAW\objects.csv'
$group = 'your AD DS group name here' ##  <<<=== AD DS group name here
foreach ($adobject in $csv) {
    $object = $adobject.name
    try {
        Add-ADGroupMember -Identity $group -Members (get-adcomputer $object) -ea SilentlyContinue
        "This $adobject is been add it to $group"
    }
    catch { "===>>> $object not in AD" }
}
