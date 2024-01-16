<#
https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/dell-command-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
https://www.dell.com/support/kbdoc/en-uk/000187573/bios-password-is-not-included-in-the-exported-configuration-of-dell-command-update
https://www.dell.com/support/kbdoc/en-uk/000187573/bios-password-is-not-included-in-the-exported-configuration-of-dell-command-update?lang=en
#>
Function Initialize-DellUpdates {
    Param($dcucli)
    Function Update-DellStack {
        Param($dcucli)
        $Evaluations = & $dcucli /scan
        If ($lastexitcode -ne 0) {
            Stop-Process -ProcessName DellCommandUpdate.exe -ErrorAction SilentlyContinue
            Stop-Process -ProcessName dcu-cli.exe -ErrorAction SilentlyContinue
            Restart-Service -Name DellClientManagementService -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 10
            $Evaluations = & $dcucli /scan
        }
        If (($Evaluations | Select-String -Pattern 'BIOS*').count -gt 0) {
            & Choco install 'dcu-cli.file' -r --no-progress
            $sp = Get-Content "c:\encryptedPassword.txt" #### <<<=== your encrypted password file here 
            
            $k = 'generated key' ##### <<<=== Your generated key here
            
            & $dcucli /applyupdates -encryptionkey=""$k"" -encryptedpassword=""$sp"" -silent -outputlog=""C:\DCU_ApplyUpdates.log"" -reboot=disable -autoSuspendBitLocker=enable
            & Choco uninstall 'dcu-cli.file' -r --no-progress
        }
        If (($Evaluations | Select-String -Pattern 'BIOS*').count -eq 0) {
            & $dcucli /applyUpdates -silent -outputlog=""C:\DCU_ApplyUpdates.log"" -reboot=disable
        }
    }
    #task
    Update-DellStack -dcucli $dcucli
    Exit 0
}
#Evaluations
$DCUPath = "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"
Switch (Test-Path $DCUPath) {
    $True {
        Initialize-DellUpdates -dcucli $DCUPath
    }
    $False {
        Write-Output '===>>> dellcommandupdate not installed'
        & Choco upgrade 'dellcommandupdate' -r --no-progress -y
        If ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE 
        }
        Else {
            Initialize-DellUpdates -dcucli $DCUPath
            Exit 0
        }
    }
}
