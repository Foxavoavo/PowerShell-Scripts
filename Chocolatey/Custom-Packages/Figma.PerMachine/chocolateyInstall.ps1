#Custom installer#
$ApplicationName = 'Figma'
$version = '116.15.4'
#
Function Set-Shortcut {
    param($SourceExe, $DestinationShortcut)
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DestinationShortcut)
    $Shortcut.TargetPath = $SourceExe
    $Shortcut.Save()
}
#preps
& Choco upgrade $ApplicationName -r --no-progress --version $version --force
If($LASTEXITCODE -ne 0) { Exit 5995 }
Start-Process -FilePath "${Env:ProgramData}\chocolatey\bin\figma.exe"
Start-Process -FilePath "${Env:ProgramData}\chocolatey\bin\figma_agent.exe"
Start-Process -FilePath "${Env:ProgramData}\chocolatey\bin\Figma_ExecutionStub.exe"
#set shortcut
Try {
    Set-Shortcut -SourceExe "${Env:ProgramData}\chocolatey\lib\Figma\lib\net45\Figma.exe" -DestinationShortcut "${env:Public}\Desktop\$ApplicationName.lnk"
}
Catch {
    Write-Output "Unable to create shortcut ${env:Public}\Desktop\$ApplicationName.lnk"
}
Try {
    Set-Shortcut -SourceExe "${Env:ProgramData}\chocolatey\lib\Figma\lib\net45\Figma.exe" -DestinationShortcut "${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$ApplicationName.lnk"
}
Catch {
    Write-Output "Unable to create shortcut ${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$ApplicationName.lnk"
}
#housekeep
Remove-Item "${Env:Public}\unpack\FigmaFiles" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "${Env:ProgramData}\chocolatey\bin\figma.exe" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "${Env:ProgramData}\chocolatey\bin\figma_agent.exe" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "${Env:ProgramData}\chocolatey\bin\Figma_ExecutionStub.exe" -Recurse -Force -ErrorAction SilentlyContinue
Exit 0
