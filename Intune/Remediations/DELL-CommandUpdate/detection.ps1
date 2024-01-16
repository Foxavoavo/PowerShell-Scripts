<#
https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/dell-command-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
#>
Function Compare-DellItems {
    param(
        $dcucli     
    )
    $Evaluations = & $dcucli /scan
    If ($lastexitcode -ne 0) {
        Stop-Process -ProcessName DellCommandUpdate.exe -ErrorAction SilentlyContinue
        Stop-Process -ProcessName dcu-cli.exe -ErrorAction SilentlyContinue
        Restart-Service -Name DellClientManagementService -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
        $Evaluations = & $dcucli /scan
    }
    If (($Evaluations | Select-String -Pattern 'Number of applicable updates for the current system configuration: 0').count -eq 1) {
        Write-Output 0
    }
    If (($Evaluations | Select-String -Pattern 'Number of applicable updates for the current system configuration: 0').count -eq 0) {
        Write-Output 1
    }
}
#Evaluations
$DCUPath = "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"
Switch (Test-Path $DCUPath) {
    $True {
        $Results = Compare-DellItems -dcucli $DCUPath
        Switch ($Results) {
            0 {
                Write-Output '===>>> Nothing to update'
                Exit 0
            }
            1 {
                Write-Output '===>>> Something to update'
                Exit 1
            }
        }
    }
    $False {
        Write-Output '===>>> dellcommandupdate not installed'
        Exit 1
    }
}
