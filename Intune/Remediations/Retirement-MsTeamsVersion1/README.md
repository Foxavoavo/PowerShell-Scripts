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

:^ )
