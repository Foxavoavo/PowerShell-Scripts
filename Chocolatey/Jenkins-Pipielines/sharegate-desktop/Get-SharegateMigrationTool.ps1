[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]
    $localRepo,

    [Parameter(Mandatory)]
    [string]
    $localRepoApiKey,

    [Parameter(Mandatory)]
    [string]
    $CCMpackageName,

    [Parameter(Mandatory)]
    [string]
    $remoteRepo,

    [Parameter(Mandatory)]
    [string]
    $versionManifest,

    [Parameter(Mandatory)]
    [string]
    $providerRepository,

    [string]
    $installFilePath = "$PsScriptRoot\AdditionalInstallParameters.ps1",
    [string] 
    $uninstallFilePath = "$PsScriptRoot\AdditionalUninstallParameters.ps1"
)
# format local repo package.
. "${Env:SystemDrive}\scripts\ConvertTo-ChocoObject.ps1"

If (([version] (choco --version).Split('-')[0]) -ge [version] '2.1.0') {
    Write-Verbose "Clearing Chocolatey CLI cache to ensure latest package information is retrieved."
    choco cache remove
}

Write-Verbose "Getting list of local packages from '$localRepo'."
$localPkgs = choco search --source $localRepo -r | ConvertTo-ChocoObject
Write-Verbose "Retrieved list of $(($localPkgs).count) packages from '$localRepo'."

If ((($localPkgs | Where-Object { $_.name -eq $CCMpackageName } | Measure-Object).Count) -in (0, 1)) {
    Write-Verbose "Getting remote package information for '$($CCMpackageName)'."
    $remotePkg = choco search $CCMpackageName --source $remoteRepo --exact -r | ConvertTo-ChocoObject
    If ((($remotePkg | Measure-Object).Count -eq 0) -or ([version]($remotePkg.version) -gt ([version]$_.version))) {
        If (($remotePkg | Measure-Object).Count -eq 1) {
            #Write-Verbose "Package '$($CCMpackageName)' has a remote version of '$($remotePkg.version)' which is later than the local version '$($_.version)'."
            #Write-Verbose "Internalizing package '$($CCMpackageName)' with version '$($remotePkg.version)'."
        }
        # create the temporary folder.
        $tempPath = Join-Path -Path D:\ChocoCache -ChildPath ([GUID]::NewGuid()).GUID
        # condition for temporary folder.
        If (-not (Test-Path $tempPath)) {
            New-Item $tempPath -ItemType Directory | Out-Null
        }
        # condition to check for latest version of the chocolatey package in the internal repo. #

        $raw = Invoke-WebRequest -Uri $versionManifest
        $content = $raw.content 
        if ($null -eq $content) {
            Write-Output 'The version evaluation is null, check the version url page.'
            Exit 1
        }
        # regex part 
        [regex]$regex = '\w*ShareGate\..*\.\w*msi'
        $currentVersion = $regex.Matches($content).Value
        [regex]$regex = '(?<=\.)\d.*'
        $versionNumber = ($regex.Matches($currentVersion).Value) -replace ('\.\w*msi$', '')
        Write-Verbose "Package '$($CCMpackageName)' has a remote version of '$($versionNumber)' in the Vendor Repository."
        # compare with existing version in Repo.
        Write-Verbose "Compare Package '$($CCMpackageName)' version with remote version from Vendor Repository."
        $localVersion = $localPkgs | Where-Object { $_.Name -eq $CCMpackageName } | Select-Object Version
        Write-Verbose "The local chocolatey repository version is '$($localVersion.Version)'"
        if (([Version]$localVersion.Version) -lt [Version]$versionNumber) {
            Write-Verbose "The version of '$($CCMpackageName)' in Local repo is '$($localVersion.Version)' lower than the Vendor available version '$($versionNumber)'."
            Write-Verbose "Preparing to download '$($CCMpackageName)' from Vendor repository."
            # download latest msi.
            $downloader = New-Object -TypeName System.Net.WebClient
            $url = $providerRepository + "ShareGate.$($versionNumber).msi"
            $fileName = Join-Path $tempPath "ShareGate.$($versionNumber).msi"
            $downloader.DownloadFile($url, $fileName)

            # Av Scan downloaded files for threats. #
            Write-Output "Preparing AV defender file scan in '$($tempPath)'"     
            $defenderAction = & "${env:ProgramFiles}\windows Defender\mpcmdrun.exe" -Scan -ScanType 3 -File $tempPath -Level 0x10
            # evaluate for threats          
            If (($defenderAction | Select-String -Pattern 'no threats.').count -gt 0 -and $LASTEXITCODE -eq 0 ) { 
                Write-Output $defenderAction 
                # Package construction
                Choco new --File $FileName silentargs="'/q sharegateinstallscope=permachine restartedasadmin=1 allusers=1 /l ${env:WinDir}\logs\SharegateDesktopInstall.log'" --output-directory $tempPath
                $nuspec = (Get-ChildItem $tempPath -Recurse -Filter *.nuspec).FullName
                [xml]$xml = Get-Content $nuspec
                $xml.package.metadata.id = $CCMpackageName
                $xml.Save($nuspec)
                # Tailor chocolateyinstall.ps1 to move the application files to C:\ rather than the service account and to add shortcuts to the users. #
                if ((Test-Path $installFilePath) -eq $true -or (Test-Path $uninstallFilePath) -eq $true) {
                    # Install
                    $installPSFile = (Get-ChildItem $tempPath -Recurse -Filter 'chocolateyInstall.ps1').FullName
                    $ImportedLines = Get-Content $installFilePath -Raw
                    Try { Add-Content $InstallPSFile -Value $ImportedLines }
                    Catch { Write-Output 'unable to edit ChocolateyInstall.ps1' }
                    # Uninstall
                    $uninstallPSFile = (Get-ChildItem $tempPath -Recurse -Filter 'chocolateyUninstall.ps1').FullName
                    $importedUninstallLines = Get-Content $uninstallFilePath -Raw -ErrorAction SilentlyContinue
                    if ($null -eq $uninstallPSFile) {
                        $destinationPath = (Get-ChildItem $tempPath -Recurse -Filter 'tools').FullName
                        Copy-Item -Path $uninstallFilePath -Destination "$destinationPath\chocolateyUninstall.ps1" -Force -Recurse
                    }
                    if (($UninstallPSFile.count) -gt 0) { Add-Content $uninstallPSFile -Value $importedUninstallLines }
                }
                # End Tailoring lines #
                Choco pack $nuspec --outputdirectory $tempPath
                switch ($LASTEXITCODE) {
                    0 {  
                        Write-Verbose "Pushing package '$($CCMpackageName)' to local repository '$localRepo'."
                    (Get-Item -Path (Join-Path -Path $tempPath -ChildPath "*.nupkg")).fullname | ForEach-Object {
                            Choco push $_ --source $localRepo --api-key $localRepoApiKey --force
                            Switch ($LASTEXITCODE) {
                                0 { Write-Verbose "Package '$_' pushed to '$localRepo'." }
                                { $_ -ne 0 } { Write-Verbose "Package '$_' could not be pushed to '$localRepo'.`nThis could be because it already exists in the repository at a higher version and can be mostly ignored. Check error logs." }
                            }
                            Remove-Item $tempPath -Recurse -Force
                        }
                    }
                    { $_ -ne 0 } { Write-Verbose "Failed to download package '$($CCMpackageName)'" }
                }
            }
            else { 
                Write-output "!!! ===>>> the execautable has a detected threat by the Antivirus, check Antivirus logs in eventviewer"
                Write-output $defenderAction
                Exit 1       
            }
        }
        else { Write-Verbose "The local repository version for '$($CCMpackageName)' is '$($localVersion.Version)' which is greater or equal than the reported '$($versionNumber)' from the Vendor repo." }
    }
    else {
        Write-Verbose "Package '$($CCMpackageName)' has a remote version of '$($remotePkg.version)' which is not later than the local version '$($_.version)'."
        Exit 0
    }
}
