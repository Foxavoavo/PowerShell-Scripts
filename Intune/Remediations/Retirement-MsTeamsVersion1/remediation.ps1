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
        Write-Output 'MSTeams Wide Install present in device, trying to remove now'
        & msiexec.exe /x'{731F6BAA-A986-45A4-8936-7C3AAAAA760B}' /qn /norestart
    }
    $False {
        # Evaluate local disk users for Teams leftovers
        $Users = Get-ChildItem "${env:SystemDrive}\users" | Select-Object FullName, Name
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
                                    Write-output ".dead Teams file found in $Username profile,attempting to remove the leftover folder"
                                    Remove-Item "$UserPath\AppData\Local\Microsoft\Teams" -Force -Recurse -ErrorAction SilentlyContinue 
                                }
                                $False { 
                                    # Scan for leftovers
                                    $Files = Get-ChildItem "$UserPath\AppData\Local\Microsoft\Teams"
                                    Switch ($Files) {
                                        { $_.Count -gt 0 } { 
                                            Write-Output 'Left over files in the folder found, attempting to remove files'
                                            & "$UserPath\AppData\Local\Microsoft\Teams\Update.exe" --uninstall -s 
                                            Remove-Item "$UserPath\AppData\Local\Microsoft\Teams\*" -Force -Recurse -ErrorAction SilentlyContinue 
                                        }
                                        { $_.Count -eq 0 } { 
                                            Write-Output 'Empty Teams folder found, attempting to remove empty folder'
                                            Remove-Item "$UserPath\AppData\Local\Microsoft\Teams" -Force -Recurse -ErrorAction SilentlyContinue 
                                        }
                                    }
                                    Write-output ".dead Teams file not found in $Username profile"
                                }
                            }
                            
                        }
                    }
                }
                $False { 
                    Write-output "Teams folder not found in Users profile"
                }
            }
        }
    }
}
