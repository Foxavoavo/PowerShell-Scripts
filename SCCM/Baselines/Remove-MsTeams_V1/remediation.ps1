<#
Remove old Ms Teams - combined

 - Look and remove MS Teams wide install and uninstall from device.
 - Runs an array in users profiles looking for leftover teams Files in path => USERNAME\AppData\Local\Microsoft
 - While running the array, the remediation will run conditions such as:
 
 a) The update.exe file is there to remove uninstall from the profile (line 34).
 b) If there is leftovers, in the teams folder, remove the leftover files (line 48).
 c) Remove the leftover empty teams folder (line 52)
 d) check for user on session and delete teams v1 left over keys.
 e) load users reg hives that are not on session and delete teams v1 left over keys.
 f) for those users in session, there is the last array to evaluate for teams v1 registry keys. 
 Reference documents:

https://www.microsoft.com/en-gb/microsoft-teams/download-app
https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client
#>
#Function
Function Get-UserOnSession {
    $RAWSessions = Get-Process -IncludeUserName | Select-Object Username -Unique  | Select-String -Pattern 'USER-PATTER-LIKE-1ST-DOMAIN-CHARACTERS'
    $UserSessions = New-Object System.Collections.ArrayList
    ForEach ($Object in $RAWSessions) {
        [Regex]$Regex = '(?<=\\)\w*'
        $UsernameOnSession = $Regex.Matches($Object).Value
        $UserSessions.add($UsernameOnSession) | Out-Null
    }
    Write-Output $UserSessions 
}
Function Remove-MSTeamsItems {
    param ($UserOnSession)
    # Preps to evaluate left over reg keys
    New-PSDrive HKU Registry HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
    # Evaluate local disk users for Teams leftovers
    $Users = Get-ChildItem "${env:SystemDrive}\users" -Exclude 'defaultuser0', 'public' | Select-Object FullName, Name
    ForEach ($User in $Users) {
        $UserPath = $User.FullName
        $Username = $User.Name
        # Path evaluations
        Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams") {
            $True {
                Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams\Update.exe") {
                    $True { 
                        # Check for dead files in the user profile Teams folder
                        Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams\.dead") { 
                            $True { 
                                #Write-output ".dead Teams file found in $Username profile,attempting to remove the leftover folder"
                                Remove-Item "$UserPath\AppData\Local\Microsoft\Teams" -Force -Recurse -ErrorAction SilentlyContinue 
                            }
                            $False { 
                                # Scan for leftovers
                                $Files = Get-ChildItem "$UserPath\AppData\Local\Microsoft\Teams"
                                Switch ($Files) {
                                    { $_.Count -gt 0 } { 
                                        #Write-Output 'Left over files in the folder found, attempting to remove files'
                                        & "$UserPath\AppData\Local\Microsoft\Teams\Update.exe" --uninstall -s 
                                        Remove-Item "$UserPath\AppData\Local\Microsoft\Teams\*" -Force -Recurse -ErrorAction SilentlyContinue
                                        Remove-Item "$UserPath\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams classic.lnk" -Force -ErrorAction SilentlyContinue
                                    }
                                    { $_.Count -eq 0 } { 
                                        #Write-Output 'Empty Teams folder found, attempting to remove empty folder'
                                        Remove-Item "$UserPath\AppData\Local\Microsoft\Teams" -Force -Recurse -ErrorAction SilentlyContinue
                                        Remove-Item "$UserPath\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams classic.lnk" -Force -ErrorAction SilentlyContinue
                                    }
                                }
                                #Write-output ".dead Teams file not found in $Username profile"
                            }
                        }
                                
                    }
                }
            }
            $False { 
                #Write-output "Teams folder not found in Users profile"
            }
        }
        # Evaluate for left over reg keys
        If (($UserOnSession | Select-String -Pattern $Username).count -ne 1) {
            #Write-Output "$username not on session, loading reg now"
            & reg.exe load "HKEY_USERS\$Username" "C:\Users\$Username\ntuser.dat" 2>$Null | Out-Null
        }
        Switch (Test-Path "HKU:\$Username\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams") { 
            $True { 
                #Write-Output "Left over reg key found on $username"
                Remove-Item -Path "HKU:\$Username\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams" -Force -Recurse -ErrorAction SilentlyContinue
            }
            $False { }
        }
        If (($UserOnSession | Select-String -Pattern $Username).count -ne 1) {
            #Write-Output "$username not on session, unloading reg now"
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            & reg.exe unload "HKU\$username" 2>$Null | Out-Null
        }
    }
    # Handle user in session
    If (($UserOnSession).count -gt 0) { 
        $Hashes = Get-ChildItem -path HKU: | Where-Object { $_.Name -notmatch "Classes" -and $_.Name -match 'S-1-' } | select-object name
        ForEach ($Hash in $Hashes) {
            $UserSID = $Hash.name
            $TeamsPath = "HKU:\$UserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
            Switch (Test-Path $TeamsPath) {
                $True { 
                    Write-Output "Teams in $UserSID" 
                    Remove-Item $TeamsPath -Force -Recurse -ErrorAction SilentlyContinue
                }
                $False { }
            }
        }
    }
    # Detach HKU drive post the user array
    Remove-PSDrive HKU -ErrorAction SilentlyContinue | Out-Null
    #Write-Output 'HKU detach'
}
# Remove old wide-installed Teams
Switch (Test-Path "${Env:ProgramFiles(x86)}\Teams Installer\Teams.exe") {
    $True { 
        #Write-Output 'MSTeams Wide Install present in device, trying to remove now'
        Try { & msiexec.exe /x'{731F6BAA-A986-45A4-8936-7C3AAAAA760B}' /qn /norestart }
        Catch { }
        Remove-Item "${Env:ProgramFiles(x86)}\Teams Installer" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{73F5EDDD-8C52-4F96-92E0-8204159D12C9}' -Force -Recurse -ErrorAction SilentlyContinue
        # Evaluate for left over reg keys
        $UserOnSession = Get-UserOnSession
        #Housekeep
        Remove-MSTeamsItems -UserOnSession $UserOnSession
    }
    $False {
        # Evaluate for left over reg keys
        $UserOnSession = Get-UserOnSession
        #Housekeep
        Remove-MSTeamsItems -UserOnSession $UserOnSession
    }
}
