I create a remediation which updates Bios, firmware and drivers on DELL devices with the utility Dell Command and Update CLI.
to cover the update of the BIOS, you need to create a key to use to encrypt the password in a file and passed to DCUCLI when needs to update the BIOS.
the documents I use to encrypt the BIOS password are here bellow on the links.

I use my chocolatey repository to install DELL command and update and also to pass the encrypted password when need it for updates.

https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/dell-command-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
https://www.dell.com/support/kbdoc/en-uk/000187573/bios-password-is-not-included-in-the-exported-configuration-of-dell-command-update
https://www.dell.com/support/kbdoc/en-uk/000187573/bios-password-is-not-included-in-the-exported-configuration-of-dell-command-update?lang=en

:^ )

Gus
