###################################################
$ApplicationName = $PackageName # <<<=== Your Application Name here
###################################################
# Functions
Function Remove-UserApplication {
    param($users, $localAppName, $applicationName)
    # users housekeep loop
    foreach ($user in $userlist) {
        $userName = $user.name
        if ((Test-Path "C:\Users\$userName\AppData\Local\Apps\$localAppName\$localAppName.exe") -eq $True) {
            # compare installed app first, to avoid left over reg entries.
            $localAppObject = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "$localAppName*" }
            $localAppObject.Uninstall() | Out-Null
            # remove file stack.
            Remove-Item "C:\Users\$userName\AppData\Local\Apps\$localAppName" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    # Check for process & stop application
    $evaluations = Get-Process | Where-Object { $_.Name -like "$localAppName*" }
    If ($evaluations.Count -gt 0) {
        foreach ($evaluation in $evaluations) {
            $stopProcess = $evaluation.ProcessName 
            Stop-Process -Name $stopProcess -Force
        }
    }
    Start-Sleep -Seconds 1
    Remove-Item "${env:SystemDrive}\$localAppName" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "${env:Public}\Desktop\$localAppName.lnk" -Recurse -Force -ErrorAction SilentlyContinue 
    Remove-Item  "${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$localAppName.lnk" -Recurse -Force -ErrorAction SilentlyContinue
}
# Values
$params = @{
    Users           = Get-ChildItem "${env:SystemDrive}\users" | Select-Object FullName, Name
    applicationName = $applicationName
    localAppName    = $applicationName -replace ('\-\w*desktop', '')
}
# Housekeep 
Remove-UserApplication @params
exit 0
