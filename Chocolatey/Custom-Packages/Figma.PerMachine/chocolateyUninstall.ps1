#Custom uninstaller#
$ApplicationName = 'Figma'
#
#stop process
$ProcessList = Get-Process | Where-Object {$_.Name -like 'figma*'} | Select-Object ProcessName
ForEach($Process in $ProcessList) {
    $ProcessName = $Process.ProcessName
    Stop-Process -Name $ProcessName -Force
}
& Choco Uninstall $ApplicationName -r --no-progress
#housekeep
Remove-Item "${env:Public}\Desktop\$ApplicationName.lnk" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$ApplicationName.lnk" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "${Env:ProgramData}\chocolatey\lib\Figma" -Recurse -Force -ErrorAction SilentlyContinue
Exit 0
