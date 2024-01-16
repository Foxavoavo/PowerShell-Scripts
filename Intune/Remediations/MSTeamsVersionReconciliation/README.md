This is an Intune remediation to reconcile all those left over MS Teams on your Windows devices and user profiles.
I create a custom chocolatey package to pass the teams .msi file to the devices & unpackage there, then copy/paste the files in the teams 'program files' folder
here: C:\Program Files (x86)\Teams Installer

you can use also Winget and replace the chocolatey package.

the detection returns based on the findings (Exit 1 or Exit 0)

the remediaiton will install the custom package & copy the teams files in C:\Program Files (x86)\Teams Installer
then, deletes the 'current' teams folder on the appData for the users like here: "C:\Users\Username\AppData\Local\Microsoft\Teams\current\Teams.exe"

the remediation evaluates if the user is in session, if so will skip that user and update next time the user is offline.

:^ )

Gus
