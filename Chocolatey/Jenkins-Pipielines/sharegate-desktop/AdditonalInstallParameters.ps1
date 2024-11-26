#########################################
#            Tailoring part             #        
#########################################
# wait for installer to finish
#######################################
$applicationName = $env:ChocolateyPackageName # <<<=== Your Application Name here
#######################################
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv
Start-Sleep -Seconds 5
#
function Find-LatestApplicationInstall {
    param ($users, $date, $localAppName, $localPath, $devicePath)

    if ((Test-Path "$devicePath\$localAppName.exe") -eq $True) { 
        $fileLocation = Get-ChildItem $devicePath -ErrorAction SilentlyContinue
        $writedDate = ($fileLocation.LastWriteTime).ToString('ddMM')
        if ($writedDate -match $date) {
                $result = "$devicePath\$localAppName.exe"
            }   
    }
    if ((Test-Path "$devicePath\$localAppName.exe") -eq $False) { 
    foreach ($user in $users) {
        $userName = $user.name 
        if ((Test-Path "${env:SystemDrive}\Users\$username\$localPath\$localAppName\$localAppName.exe") -eq $True) { 
            $fileLocation = Get-ChildItem "${env:SystemDrive}\Users\$username\$localPath" -ErrorAction SilentlyContinue
            $writedDate = ($fileLocation.LastWriteTime).ToString('ddMM')
            if ($writedDate -match $date) {
                $result = "${env:SystemDrive}\Users\$username\$localPath\$localAppName\$localAppName.exe"
            }
        }
    }
    }
    Write-Output $result
}
function ConvertTo-LocalApplication {
    param(
        $localAppName,
        $applicationFolder,
        $sourceExe = "${env:SystemDrive}\$localAppName\$localAppName.exe",
        $destinationShortcut = "${env:Public}\Desktop\$localAppName.lnk",
        $destinationStartMenu = "${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$localAppName.lnk"
    )
    function Set-Shortcut {
        param($sourceExe, $destinationShortcut)
        $wshShell = New-Object -comObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($destinationShortcut)
        $shortcut.TargetPath = $sourceExe
        $shortcut.Save()
    }
    try {
        if ((Test-path "${env:SystemDrive}\$localAppName") -eq $True) { 
            try { Remove-Item "${env:SystemDrive}\$localAppName" -Recurse -Force }
            catch { Write-Output "Unable to delete existing folder in the systemdrive" }
        }
        try { 
            $folderAction = New-Item -Name $localAppName -ItemType Directory -Path "${env:SystemDrive}\" -Force
            Write-Output $folderAction
        }
        catch { Write-Output "Unable to create folder in the systemdrive" }
        try { 
            $copyAction = Copy-Item "$applicationFolder*" -Destination "${env:SystemDrive}\$localAppName" -Recurse -Force 
            Write-Output $copyAction
        }
        catch { Write-Output "Unable to copy stack files in the systemdrive folder" }
    }
    catch {
        Write-Output "Unable to create/copy the folder to the systemdrive"
        exit 1
    }
    try {
        Set-Shortcut -SourceExe "$sourceExe" -DestinationShortcut "$destinationShortcut"
        $shortcutAction = Copy-Item $destinationShortcut -Destination $destinationStartMenu -Recurse -Force -Verbose
        Write-Output $shortCutAction
    }
    catch {
        Write-Output "Unable to create shortcut"
    }
}
# specific application tailored for sharegate.
Function Remove-UserApplication {
    param($users, $localAppName, $applicationName, $applicationPath, $date)
    # users housekeep loop
    $excludedUser = $applicationPath -replace ('C:\\users\\', '') -replace ("\\AppData\\Local\\Apps\\$localAppName\\$localAppName.exe", '')
    # remove shortcut from excluded user.
    $shortcutPath = $applicationPath -replace ("\\AppData\\Local\\Apps\\$localAppName\\$localAppName.exe", '\Desktop')
    $originalShortcut = Get-ChildItem -Path $shortcutPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$localAppName*" } | Select-Object fullName
    if ($null -ne $originalShortcut.fullName) {
        Remove-Item -path $($originalShortcut.fullName) -Force -Recurse -ErrorAction SilentlyContinue
    }
    #tailoring users
    $userlist = $users | Where-Object { $_.Name -ne $excludedUser }
    foreach ($user in $userlist) {
        $userName = $user.name
        if ((Test-Path "C:\Users\$userName\AppData\Local\Apps\$localAppName\$localAppName.exe") -eq $True) {
            # compare installed app first, to avoid left over reg entries.
            $localAppObject = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "$localAppName*" }
            $currentVersion = ($localAppObject.Version) -replace ('\.\d*$', '')
            # capture version from repo.
            $availableVersionRaw = & Choco search $applicationName | Select-String -Pattern $applicationName
            [regex]$regex = '\s\d.*\d.*'
            $availableVersion = ($regex.Matches($availableVersionRaw).Value) -replace ('\s', '')
            # validations 
            if ([Version]$currentVersion -lt [Version]$availableVersion) {
                $localAppObject.Uninstall() | Out-Null
            }
            # remove file stack.
            Remove-Item "C:\Users\$userName\AppData\Local\Apps\$localAppName" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}   
# Values
$localAppName = $applicationName -replace ('\-\w*desktop', '')
$params = @{
    applicationName = $applicationName
    localAppName    = $localAppName
    date            = get-date -Format 'ddMM'
    users           = Get-ChildItem "${env:SystemDrive}\Users\" | select-object Name
    localPath       = 'AppData\Local\Apps'
    devicePath      = "${env:Windir}\SysWOW64\config\systemprofile\AppData\Local\Apps\ShareGate"
}
# Gather application path
$applicationPath = Find-LatestApplicationInstall @params
if ($null -ne $applicationPath) {
    $params += @{ applicationPath = $applicationPath }
    # Housekepp leftover stack items
    Remove-UserApplication @params
    # Installation params
    $params += @{ applicationFolder = $applicationPath -replace ("\w*$localAppName\.exe", '') } 
    # Check for process & stop application
    $evaluations = Get-Process | Where-Object { $_.Name -like "$localAppName*" }
        If ($evaluations.Count -gt 0) {
            foreach ($evaluation in $evaluations) {
            $stopProcess = $evaluation.ProcessName 
            Stop-Process -Name $stopProcess -Force
        }
    }
    # Install actions
    Switch (Test-Path $applicationPath) {
        $true { ConvertTo-LocalApplication @params } 
        $false { 
            Write-Output "Unable to locate $localAppName "
            exit 1
        }
    }
}
if ($null -eq $applicationPath) { 
    write-output 'The function Find-LatestApplicationInstall variable is empty' 
    exit 1
}
