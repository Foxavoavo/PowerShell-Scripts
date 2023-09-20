<#
Compare versions of Ms Teams in program files & on the user profiles.
for my customer, I use a custom MS Teams package to compare the version to.

the paths to compare:
"C:\Users\Username\AppData\Local\Microsoft\Teams\current\Teams.exe" with an array 
and C:\Program Files (x86)\Teams Installer -- looks for x64 too.
#>
Function Get-TeamsObjects {
    param(
        $Usage,
        $Version,
        $RepoAvailablePackage,
        $Username
    )
    #tailor
    $Package = $RepoAvailablePackage | Select-String -Pattern '\w*Microsoft-Teams-Update.PerMachine*'
    [regex]$regex = '(?<=\s).*'
    $RepoAvailableVersion = $regex.Matches($Package).Value
    $ToReview = New-Object System.Collections.ArrayList
    $UsersToReview = New-Object System.Collections.ArrayList  
    If ($Usage -eq 'App') {
        Switch ($Version) {
            { $Null -eq $_ } {
                #Write-Output 'Local Teams Not Found'
                #$ToReview.add(1) | Out-Null
            }
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                #Write-Output 'Local Teams needs update'
                $ToReview.add('1') | Out-Null
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {
                #Write-Output 'Local Teams at glance'
                $ToReview.add('0') | Out-Null
            }
        }
        Write-Output $ToReview
    }
    If ($Usage -eq 'User') {
        Switch ($Version) {
            { $Null -eq $_ } {
                #Write-Output "===>>> Local Teams Not Found for $User"
                #$UsersToReview.add('0') | Out-Null
            }
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                #Write-Output "===>>> Local Teams needs update for $User"
                $UsersToReview.add('1') | Out-Null
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {
                #Write-Output "===>>> Local Teams at glance for $User"
                $UsersToReview.add('0') | Out-Null
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
$Paths = @($Teams32Path, $Teams64Path)
Foreach ($Path in $Paths) {
    Switch (Test-Path $Path) {
        $True { $LocalTeams = "$Path\Teams.exe" }
        $False {}
    }
}
#Local drive application version validation
Switch(Test-Path $LocalTeams){
    $True{
        $LocalTeamsVersion = (Get-Item $LocalTeams).VersionInfo.ProductVersion
        $LocalResult = Get-TeamsObjects -Version $LocalTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Usage 'App'
    }
    $False {}
}
#User profile version validation
$Users = Get-ChildItem "${env:SystemDrive}\users" -Exclude 'defaultuser0', 'public' | Select-Object FullName, Name
ForEach ($User in $Users) {
    $UserPath = $User.FullName
    $Username = $User.Name
    $TeamsUserPath = "$UserPath\AppData\Local\Microsoft\Teams\current\Teams.exe"
    #Evaluation
    Switch (Test-Path $TeamsUserPath) {
        $True {
            $LocalUserTeamsVersion = (Get-Item $TeamsUserPath).VersionInfo.ProductVersion
            $UserResult = Get-TeamsObjects -Version $LocalUserTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Username $Username -Usage 'User'
            #Write-Output "$Username have Teams"
        }
        $False {
            #Write-Output "$Username doesn't have Teams"
        }
    }
}
If ($LocalResult -eq 0 -and $UserResult -eq 0) {
    #'both are 0'
    Exit 0
}
If ($LocalResult -eq 1 -and $UserResult -eq 0) {
    #'there is 1'
    Exit 1
}
If ($LocalResult -eq 0 -and $UserResult -eq 1) {
    #'there is 1'
    Exit 1
}
If ($LocalResult -eq 1 -and $UserResult -eq 1) {
    #'both are 1'
    Exit 1
}
