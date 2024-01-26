<#
Evaluate if Ms Teams V1 in device is outdated.
Evaluate Ms Teams V1 in user profiles.
Also, look for left over Ms Teams V1 app parts in User profiles too.
#>
Function Get-TeamsObjects {
    param($Usage, $Version, $RepoAvailablePackage, $Username)
    #tailor
    $Package = $RepoAvailablePackage | Select-String -Pattern '\w*Microsoft-Teams-Update.PerMachine*'
    [regex]$regex = '(?<=\s).*'
    $RepoAvailableVersion = $regex.Matches($Package).Value
    $ToReview = 0
    $UsersToReview = 0
    If ($Usage -eq 'App') {
        Switch ($Version) {
            { $Null -eq $_ } {
                #Write-Output 'Local Teams Not Found'
                #$ToReview = 0
            }
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                #Write-Output 'Local Teams needs update'
                $ToReview = 1
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {
                #Write-Output 'Local Teams at glance'
                $ToReview = 0
            }
        }
        Write-Output $ToReview
    }
    If ($Usage -eq 'User') {
        Switch ($Version) {
            { $Null -eq $_ } {
                #Write-Output "===>>> Local Teams Not Found for $User"
                $UsersToReview = 0
            }
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                #Write-Output "===>>> Local Teams needs update for $User"
                $UsersToReview = 1
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {
                #Write-Output "===>>> Local Teams at glance for $User"
                $UsersToReview = 0
            }
        }
        Write-Output $UsersToReview
    }
}
#Evaluation
$RepoAvailablePackage = & Choco search Microsoft-Teams-Update
#local paths
$Teams32Path = "${Env:ProgramFiles(x86)}\Teams Installer"
$Teams64Path = "${Env:ProgramFiles}\Teams Installer"
#housekepp evaluation
$Housekeep = 0
$Paths = @($Teams32Path, $Teams64Path)
Foreach ($Path in $Paths) {
    Switch (Test-Path $Path) {
        $True { $LocalTeams = "$Path\Teams.exe" }
        $False {}
    }
}
#Local drive application version validation
Switch (Test-Path $LocalTeams) {
    $True {
        $LocalTeamsVersion = (Get-Item $LocalTeams).VersionInfo.ProductVersion
        $LocalResult = Get-TeamsObjects -Version $LocalTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Usage 'App'
    }
    $False {}
}
#User profile version validation
$Users = Get-ChildItem "${env:SystemDrive}\users" -Exclude 'chocolateylocaladmin', 'defaultuser0', 'public' | Select-Object FullName, Name
ForEach ($User in $Users) {
    $UserPath = $User.FullName
    $Username = $User.Name
    #Defender 365 hash
    $TeamsUserPath = "$UserPath\AppData\Local\Microsoft\Teams\current\Teams.exe"
    #Evaluation
    Switch (Test-Path $TeamsUserPath) {
        $True {
            $LocalUserTeamsVersion = (Get-Item $TeamsUserPath).VersionInfo.ProductVersion
            $UserResult = Get-TeamsObjects -Version $LocalUserTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Username $Username -Usage 'User'
            #Write-Output "$Username have Teams"
        }
        $False {
            #check for dead path
            $TeamsDeadPath = $TeamsUserPath -replace ('\\\w*current\\\w*Teams.exe', '')
            If ((Test-path "$TeamsDeadPath\.dead") -eq $True) { $Housekeep = 1 }
        }
    }
}
#App Evaluations
If ($LocalResult -eq 0 -and $UserResult -eq 0) {
    # Write-Output 'User & Device are both 0'
    $result = 0
}
If ($LocalResult -eq 0 -and $Null -eq $UserResult) {
    # Write-Output 'Device teams compliant, no user or hotdesk'
    $result = 0
}
If ($LocalResult -eq 1 -and $UserResult -eq 0) {
    # Write-Output 'Device is not compliant = 1 User is 0'
    $result = 1
}
If ($LocalResult -eq 0 -and $UserResult -eq 1) {
    # Write-Output 'Device is compliant but User is not = 1'
    $result = 1
}
If ($LocalResult -eq 1 -and $UserResult -eq 1) {
    # Write-Output 'Device & User are not complaint = 1'
    $result = 1
}
If ($Housekeep -eq 1) {
    # Write-Output 'User teams left over to clean =1'
    $result = 1
}
Switch ($result) {
    0 { 0 }
    1 { 1 }
}
