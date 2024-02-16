# Just move ad objects to some OU
# AD DS Module
#provide device names  which you want to move to an OU
Import-Module activedirectory
#
$targetOU = 'distinguished target OU here'
#
$devices = import-csv 'C:\scripts_Gus\ad\raw\objects.csv'
foreach ($device in $devices) {
    $name = $device.name
    try {
        $a = Get-ADComputer "$name" | Select-Object name, objectguid -ea SilentlyContinue
        $n = $a.name
        $o = $a.objectguid
        try {
            Move-ADObject "$o" -TargetPath $targetOU
            "===>>> $n move it okay!"
            start-sleep -s 1
        }
        catch { "Unable to move $n" }
    }
    catch { "$name device not found in AD(!)" }
}
