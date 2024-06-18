I create this baseline to remove Ms Teams V1 from my customer devices.

there is a couple of additional steps because the app spreads in multiple users and folders in the users folder stack.

there is a pair of functions to get users on sessions and to load & unload the user registy to get teams keys plus deleting any left over file from Ms Teams V1.

 - Look and remove MS Teams wide install and uninstall from device.
 - Runs an array in users profiles looking for leftover teams Files in path => USERNAME\AppData\Local\Microsoft
 - While running the array, the remediation will run conditions such as:
 
 a) The update.exe file is there to remove uninstall from the profile (line 34).
 b) If there is leftovers, in the teams folder, remove the leftover files (line 48).
 c) Remove the leftover empty teams folder (line 52)
 d) check for user in session and delete teams v1 left over keys on user registry.
 e) load users reg hives for those users not in session and delete teams v1 left over registry keys.
 
 Reference documents:

https://www.microsoft.com/en-gb/microsoft-teams/download-app
https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client

Gus

:^ )
