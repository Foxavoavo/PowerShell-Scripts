<#
Remove old Ms Teams - combined

 - Look and remove MS Teams wide install and uninstall from device.
 - Runs an array in users profiles looking for leftover teams Files in path => USERNAME\AppData\Local\Microsoft
 - While running the array, the remediation will run conditions such as:
 
 a) The update.exe file is there to remove uninstall from the profile (line 34).
 b) If there is leftovers, in the teams folder, remove the leftover files (line 48).
 c) Remove the leftover empty teams folder (line 52)
 d) check for user in session and delete teams v1 left over keys on user registry.
 e) load users reg hives for those users not in session and delete teams v1 left over registry keys.
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
# Remove old wide-installed Teams
Switch (Test-Path "${Env:ProgramFiles(x86)}\Teams Installer\Teams.exe") {
    $True { 
        #Write-Output 'MSTeams Wide Install present in device'    
        $Results = 1
    }
    $False {
        # Preps to evaluate left over reg keys
        New-PSDrive HKU Registry HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
        # Evaluate local disk users for Teams left overs
        $Users = Get-ChildItem "${env:SystemDrive}\users" -Exclude 'defaultuser0', 'public' | Select-Object FullName, Name
        ForEach ($User in $Users) {
            $UserPath = $User.FullName
            $Username = $User.Name
            # Path evaluations
            Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams") {
                $True {
                    Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams\Update.exe") {
                        $True { 
                            #Write-Output "Teams stack files present in $Username profile"
                            $Results = 1
                        }
                        $False {
                            # Check for dead files in the user profile Teams folder
                            Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams\.dead") { 
                                $True { 
                                    #Write-Output ".dead Teams file present in $Username profile"
                                    $Results = 1
                                }
                                $False { 
                                    $Files = Get-ChildItem "$UserPath\AppData\Local\Microsoft\Teams"
                                    Switch ($Files) {
                                        { $_.Count -gt 0 } { 
                                            #Write-Output 'Left over files in the folder'
                                            $Results = 1
                                        }
                                        { $_.Count -eq 0 } { 
                                            #Write-Output 'Empty Teams folder'
                                            $Results = 0
                                        }
                                    }
                                    #Write-Output ".dead Teams file not present in $Username profile"
                                    $Results = 0
                                }
                            }
                        }
                    }
                }
                $False { 
                    #Write-Output "Teams folder not present in user profiles"
                    $Results = 0
                }
            }
            # Evaluate for left over registry keys
            $UserOnSession = Get-UserOnSession
            If (($UserOnSession | Select-String -Pattern $Username).count -ne 1) {
                #Write-Output "$username not on session, loading reg now"
                & reg.exe load "HKEY_Users\$username" "c:\users\$username\ntuser.dat" | Out-Null
            } 
            Switch (Test-Path "HKU:\$username\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams") { 
                $True { 
                    #Write-Output "Left over reg key found on $username"
                    $Results = 1
                }
                $False { 
                    #Write-Output "No left over reg key found on $username"
                    $Results = 0
                }
            }
            If (($UserOnSession | Select-String -Pattern $Username).count -ne 1) {
                #Write-Output "$username not on session, unloading reg now"
                [gc]::Collect()
                [gc]::WaitForPendingFinalizers()
                & reg.exe unload "HKU\$username" | Out-Null
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
                        #Write-Output "Teams in $UserSID" 
                        $Results = 1
                    }
                    $False { 
                        #Write-Output "No teams in $UserSID"  
                    }
                }
            }
        }
        # Detach HKU drive post the user array
        Remove-PSDrive HKU -ErrorAction SilentlyContinue | Out-Null
        #Write-Output 'HKU detach'
    }
}
#Results
Switch ($Results) {
    0 { 0 }
    1 { 1 }
}
