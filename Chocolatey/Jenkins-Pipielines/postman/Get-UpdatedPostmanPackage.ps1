[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]
    $LocalRepo,

    [Parameter(Mandatory)]
    [string]
    $LocalRepoApiKey,

    [Parameter(Mandatory)]
    [string]
    $RemoteRepo,
    
    [Parameter(Mandatory)]
    [string]
    $VersionManifest,

    [Parameter(Mandatory)]
    [string]
    $ProviderRepository,

    [Parameter(Mandatory)]
    [string]
    $CCMPackageName
)

. "${Env:SystemDrive}\scripts\ConvertTo-ChocoObject.ps1"

If (([version] (choco --version).Split('-')[0]) -ge [version] '2.1.0') {
    Write-Verbose "Clearing Chocolatey CLI cache to ensure latest package information is retrieved."
    choco cache remove
}
Write-Verbose "Getting list of local packages from '$LocalRepo'."
$localPkgs = Choco search --source $LocalRepo -r | ConvertTo-ChocoObject
Write-Verbose "Retrieved list of $(($localPkgs).count) packages from '$Localrepo'."
##################################
$packageName = $CCMPackageName # <<<=== your Package Name
#################################
If ((($localPkgs | Where-Object { $_.Name -eq $packageName } | Measure-Object).Count) -in (0, 1)) {
    Write-Verbose "Getting remote package information for '$($packageName)'."
    $remotePkg = Choco search $packageName --source $RemoteRepo --exact -r | ConvertTo-ChocoObject
    If ((($remotePkg | Measure-Object).Count -eq 0) -or ([version]($remotePkg.version) -gt ([version]$_.version))) {
        If (($remotePkg | Measure-Object).Count -eq 1) {
            Write-Verbose "Package '$($packageName)' has a remote version of '$($remotePkg.version)' which is later than the local version '$($_.version)'."
            Write-Verbose "Internalizing package '$($packageName)' with version '$($remotePkg.version)'."
        }
        $tempPath = Join-Path -Path D:\ChocoCache -ChildPath ([GUID]::NewGuid()).GUID
        If (-not (Test-Path $tempPath)) {
            New-Item $tempPath -ItemType Directory
        }
        <# Version evaluations and downloads #>
        $JsonReleaseNotesUri = $VersionManifest 
        $JsonResponse = Invoke-RestMethod -Method Get -Uri $jsonReleaseNotesUri
        $Version = [Version] $jsonResponse.notes[0].version
        $Url = $ProviderRepository + "$($version.Major).$($version.Minor).$($version.Build)/win64"
        $FileName = Join-Path $tempPath "$($CCMPackageName)-win64-$($version.Major).$($version.Minor).$($version.Build)-Setup.exe"
        $Downloader = New-Object -TypeName System.Net.WebClient
        $Downloader.DownloadFile($Url, $FileName)
        #Av Scan downloaded files
        #Start-MpScan -ScanPath $FileName -ScanType CustomScan
        $DefenderAction = & "${Env:ProgramFiles}\windows Defender\mpcmdrun.exe" -Scan -ScanType 3 -File $tempPath -Level 0x10
        # Evaluate AV Scan           
        If (($DefenderAction | Select-String -Pattern 'no threats.').count -gt 0 -and $LASTEXITCODE -eq 0 ) { 
            Write-output $DefenderAction
            # Package construction
            Choco new --File $FileName silentargs="'-s'" --output-directory $tempPath
            $nuspec = (Get-ChildItem $tempPath -Recurse -Filter *.nuspec).FullName
            [xml]$xml = Get-Content $nuspec
            $xml.package.metadata.id = $CCMPackageName
            $xml.Save($nuspec)
            <# Tailor chocolateyinstall.ps1 to move the applicatino files to C:\ rather than the service account and to add shortcuts to the users. #>
            # Install
            $InstallPSFile = (Get-ChildItem $tempPath -Recurse -Filter 'chocolateyInstall.ps1').FullName
            $ImportedLines = Get-Content "$PSScriptRoot\AdditionalInstallParameters.ps1" -Raw
            Try { Add-Content $InstallPSFile -Value $ImportedLines }
            Catch { Write-Output 'unable to edit ChocolateyInstall.ps1' }
            # Uninstall
            $UninstallPSFile = (Get-ChildItem $tempPath -Recurse -Filter 'chocolateyUninstall.ps1').FullName
            If (($UninstallPSFile.count) -ge 0) {
                $ImportedUninstallLines = Get-Content "$PSScriptRoot\AdditionalUninstallParameters.ps1" -Raw
                Set-Content -Path "$($tempPath)\$($CCMPackageName)\tools\chocolateyUninstall.ps1" $ImportedUninstallLines -Force 
            }
            <# End Custom Lines #>
            Choco pack $nuspec --outputdirectory $tempPath
            Switch ($LASTEXITCODE) {
                0 {
                    Write-Verbose "Pushing package '$($packageName)' to local repository '$LocalRepo'."
                (Get-Item -Path (Join-Path -Path $tempPath -ChildPath "*.nupkg")).fullname | ForEach-Object {
                        Choco push $_ --source $LocalRepo --api-key $LocalRepoApiKey --force
                        Switch ($LASTEXITCODE) {
                            0 { Write-Verbose "Package '$_' pushed to '$LocalRepo'." }
                            { $_ -ne 0 } { Write-Verbose "Package '$_' could not be pushed to '$LocalRepo'.`nThis could be because it already exists in the repository at a higher version and can be mostly ignored. Check error logs." }
                        }
                        Remove-Item $tempPath -Recurse -Force
                    }
                }
                { $_ -ne 0 } { Write-Verbose "Failed to download package '$($packageName)'" }
            }
        }
        Else { 
            Write-output "!!! ===>>> the execautable has a detected threat by the Antivirus, check Antivirus logs in eventviewer"
            Write-output $DefenderAction
            Exit 1       
        }
    }
    Else {
        Write-Verbose "Package '$($packageName)' has a remote version of '$($remotePkg.version)' which is not later than the local version '$($_.version)'."
        Exit 0
    }
}
