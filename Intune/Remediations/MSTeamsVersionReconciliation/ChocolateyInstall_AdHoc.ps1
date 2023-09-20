<#
Custom chocolatey package to drop the MSI on the device.
you can use winget to update too.

https://www.saotn.org/extract-files-from-an-msi-package/
https://learn.microsoft.com/en-us/microsoftteams/msi-deployment
#>
Function Copy-MSTeamsItems {
    Param($Destination, $Source)
    Copy-Item -Path "$Source\Teams Installer\*" -Destination $Destination -Recurse -Force
    Write-Host "Copy completed"
    Remove-Item -Path $Source -Force -Recurse -ErrorAction SilentlyContinue
}
#values
$Teams32Path = "${Env:ProgramFiles(x86)}\Teams Installer"
$Teams64Path = "${Env:ProgramFiles}\Teams Installer"
& msiexec.exe /a "$PSScriptRoot\Teams_windows_x64.msi" /qn TARGETDIR="${Env:Public}\unpack"
Start-Sleep -Seconds 10
$Source = "${Env:Public}\unpack"
$AvailableVersion = (Get-Item "$Source\Teams Installer\Teams.exe").VersionInfo.ProductVersion
Switch (Test-Path $Teams32Path) {
    $True {
        $LocalVersion = (Get-Item "$Teams32Path\Teams.exe").VersionInfo.ProductVersion
        $Destination = $Teams32Path
    }
}
Switch (Test-Path $Teams64Path) {
    $True {
        $LocalVersion = (Get-Item "$Teams64Path\Teams.exe").VersionInfo.ProductVersion
        $Destination = $Teams64Path
    }
}
Switch ($AvailableVersion) {
    { ([Version]$_ -lt [Version]$LocalVersion) -or ([Version]$_ -eq [Version]$LocalVersion) } {
        Write-Host 'Nothing to update'
        Exit 0
    }
    { [Version]$_ -gt [Version]$LocalVersion } {
        Write-Host 'Something to update'
        Copy-MSTeamsItems -Source $Source -Destination $Destination
        Exit 0
    }
}
