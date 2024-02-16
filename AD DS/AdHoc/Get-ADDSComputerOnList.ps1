#Gather EUDs from AD DS & Report them in .csv
Import-Module activedirectory
Remove-Item 'C:\scripts_Gus\AD\Report_Results\ADcomputers.csv' -recurse -force -ea SilentlyContinue
Add-Content 'C:\scripts_Gus\AD\Report_Results\ADcomputers.csv' 'Name,Status'
$Result = 'C:\scripts_Gus\AD\Report_Results\ADcomputers.csv'
$EnabledComputers = Get-ADComputer -Filter 'Name -like "SomeString*" -and Enabled -eq $True' | Select-Object Name ## <<<=== replace somestring with your device naming convention. 
$DisabledComputers = Get-ADComputer -Filter 'Name -like "SomeString*" -and Enabled -eq $False' | Select-Object Name ## <<<=== replace somestring with your device naming convention. 
$EnabledVDIs = Get-ADComputer -Filter 'Name -like "*VDIStrings*" -and Enabled -eq $True' | Select-Object Name ## <<<=== replace somestring with your vdi naming convention. 
ForEach ($EnabledComputer in $EnabledComputers) {
    $Name = $EnabledComputer.name
    $Status = 'Enabled'
    Add-Content $Result "$Name,$Status"
}
ForEach ($DisabledComputer in $DisabledComputers) {
    $Name = $DisabledComputer.name
    $Status = 'Disabled'
    Add-Content $Result "$Name,$Status"
}
ForEach ($EnabledVDI in $EnabledVDIs) {
    $Name = $EnabledVDI.name
    $Status = 'VDI'
    Add-Content $Result "$Name,$Status"
}
