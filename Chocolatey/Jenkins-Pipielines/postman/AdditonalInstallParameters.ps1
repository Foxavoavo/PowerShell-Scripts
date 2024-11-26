##################################################
# Postman.perMachine Tailoring part
##################################################
# wait for installer to finish
Start-Sleep -Seconds 10
#
Function Find-Postman {
    param ($userlist, $date, $ApplicationName)
    Foreach ($user in $userlist) {
        $username = $user.name 
        If ((Test-Path "${env:SystemDrive}\Users\$username\AppData\Local\Postman\$ApplicationName.exe") -eq $True) { 
            $PossibleLocation = Get-ChildItem "${env:SystemDrive}\Users\$username\AppData\Local\Postman\$ApplicationName.exe"
            $WritedDate = ($PossibleLocation.LastWriteTime).ToString('ddMM')
            If ($WritedDate -match $Date) {
                Write-Output "${env:SystemDrive}\Users\$username\AppData\Local\Postman\$ApplicationName.exe"
                ; break
            }
        }
    }
}
Function ConvertTo-LocalApplication {
    param($ApplicationName,
        $ApplicationFolder,
        $SourceExe,
        $DestinationShortcut,
        $DestinationStartMenu
    )
    Function Set-Shortcut {
        param($SourceExe, $DestinationShortcut)
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($DestinationShortcut)
        $Shortcut.TargetPath = $SourceExe
        $Shortcut.Save()
    }
    Try {
        If ((Test-path "${env:SystemDrive}\$ApplicationName") -eq $True) { Remove-Item "${env:SystemDrive}\$ApplicationName" -Recurse -Force }
        $FolderAction = New-Item -Name $ApplicationName -ItemType Directory -Path "${env:SystemDrive}\" -Force -Verbose
        $CopyAction = Copy-Item "$ApplicationFolder*" -Destination "${env:SystemDrive}\$ApplicationName" -Recurse -Force -Verbose

        #Write-Output "${env:SystemDrive}\$ApplicationName ===>>> Folder created on systemdrive!"
        Write-Output $FolderAction
        Write-Output $CopyAction
    }
    Catch {
        Write-Output "Unable to create/copy the folder to the systemdrive"
    }
    Try {
        Set-Shortcut -SourceExe "$SourceExe" -DestinationShortcut "$DestinationShortcut"
        $ShortCutAction = Copy-Item $DestinationShortcut -Destination $DestinationStartMenu -Recurse -Force -Verbose
        #Write-Output "${env:Public}\Desktop\$ApplicationName.lnk ===>>> shortcut created for public user!"
        Write-Output $ShortCutAction
    }
    Catch {
        Write-Output "Unable to create shortcut"
    }
}
Function Remove-LocalPostman {
    param($userlist)
    ForEach ($User in $Userlist) {
        $UserPath = $User.FullName
        $Username = $User.Name
        $PostmanUserPath = "$UserPath\AppData\Local\$packageName\update.exe"
        #Evaluation
        If ((Test-Path $PostmanUserPath) -eq $True) {
            & $PostmanUserPath --uninstall -s
            Start-Sleep -Seconds 5
            Remove-Item "C:\users\$Username\AppData\Local\Postman" -Recurse -Force 
        }
    }
}   
#######################################
$ApplicationName = $packageName # <<<=== Your Application Name here
#######################################
#Gather application path
$Date = get-date -Format 'ddMM'
$Users = Get-ChildItem "${env:SystemDrive}\Users\" | select-object Name
$ApplicationPath = Find-Postman -date $date -userlist $Users -ApplicationName $ApplicationName
$UserTarget = $ApplicationPath -replace ('C\:\\Users\\', '') -replace ('\\AppData\\Local\\Postman\\postman\.exe', '')
#Housekeep list
$HousekeepUsers = Get-ChildItem "${env:SystemDrive}\users" -Exclude "$UserTarget", 'chocolateylocaladmin', 'defaultuser0', 'public' | Select-Object FullName, Name
If ($ApplicationPath -eq 0) {
    Write-Output "$ApplicationName path not found locally"
    Exit 7337
}
#
#Installation params
$ConfigurationArguments = @{
    ApplicationName      = $ApplicationName
    ApplicationFolder    = $ApplicationPath -replace ("$ApplicationName\.exe",'')
    SourceExe            = "${env:SystemDrive}\$ApplicationName\$ApplicationName.exe"
    DestinationShortcut  = "${env:Public}\Desktop\$ApplicationName.lnk"
    DestinationStartMenu = "${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$ApplicationName.lnk"
}
#
#Check for process
$Evaluations = Get-Process | Where-Object { $_.Name -like "$ApplicationName*" }
If ($Evaluations.Count -gt 0) {
    ForEach ($Evaluation in $Evaluations) {
        $StopProcess = $Evaluation.ProcessName 
        Stop-Process -Name $StopProcess -Force
    }
}
#Housekeep actions
Remove-LocalPostman -userlist $HousekeepUsers
#Install actions
Switch (Test-Path $ApplicationPath) {
    $True { ConvertTo-LocalApplication @ConfigurationArguments } 
    $False { 
        Write-Output "Unable to locate $ApplicationPath"
        Exit 9669
    }
}
