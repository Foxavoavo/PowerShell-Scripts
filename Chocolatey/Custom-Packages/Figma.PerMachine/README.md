To install the app for multiple windows devices and to be able to maintain the version, I create this custom package in my Chocolatey repo.

I did this: 

I download the figma latest installer from:
https://www.figma.com/
I extract the content of the installer and upload the .nupkg file in my Chocolatey repo.
create the custom package 'figma.permachine' to run the executables to install figma in the folder '${Env:ChocolateyInstall}\lib\figma' and add the user shortcuts.

I also create the uninstall script too.


:^ )

Gus
