<#
Remove old Ms Teams - combined

 - Look and remove MS Teams wide install and uninstall from device.
 - Runs an array in users profiles looking for leftover teams Files in path => USERNAME\AppData\Local\Microsoft
 - While running the array, the remediation will run conditions such as:
 
 a) The update.exe file is there to remove uninstall from the profile (line 34).
 b) If there is leftovers, in the teams folder, remove the leftover files (line 48).
 c) Remove the leftover empty teams folder (line 52)
 
 Reference documents:

https://www.microsoft.com/en-gb/microsoft-teams/download-app
https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client
#>
# Remove old wide-installed Teams
Switch (Test-Path "${Env:ProgramFiles(x86)}\Teams Installer\Teams.exe") {
    $True { 
        Write-Output 'MSTeams Wide Install present in device'    
        Exit 1 
    }
    $False {
        # Evaluate local disk users for Teams left overs
        $Users = Get-ChildItem "${env:SystemDrive}\users" | Select-Object FullName, Name
        ForEach ($User in $Users) {
            $UserPath = $User.FullName
            $Username = $User.Name
            # Path evaluations
            Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams") {
                $True {
                    Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams\Update.exe") {
                        $True { 
                            Write-output "Teams stack files present in $Username profile"
                            Exit 1
                        }
                        $False {
                            # Check for dead files in the user profile Teams folder
                            Switch (Test-Path "$UserPath\AppData\Local\Microsoft\Teams\.dead") { 
                                $True { 
                                    Write-output ".dead Teams file present in $Username profile"
                                    Exit 1
                                }
                                $False { 
                                    $Files = Get-ChildItem "$UserPath\AppData\Local\Microsoft\Teams"
                                    Switch ($Files) {
                                        { $_.Count -gt 0 } { 
                                            Write-Output 'Left over files in the folder'
                                            Exit 1
                                        }
                                        { $_.Count -eq 0 } { 
                                            Write-Output 'Empty Teams folder'
                                            Exit 0
                                        }
                                    }
                                    Write-output ".dead Teams file not present in $Username profile"
                                    Exit 0
                                }
                            }
                        }
                    }
                }
                $False { 
                    Write-output "Teams folder not present in user profiles"
                    Exit 0
                }
            }
        }
    }
}
