##########################################
##                                      ##
##           Custom VEEAM               ##
##                                      ##
##########################################

###############################
####        V1             ####
###############################

## This is the custom VEEAM auto backup script

# does the follow :^)

# Delete the previous backup file from the vm backup path.
# Runs the VeeamPSSnapin to take snapshots from the VM's. 
# Email you once the task is completed.
# Does loop for all VMS in the CSV.
#csv here

$VMS = import-csv "C:\Scripts\batch_VEEAM_Backups\VMS.csv"

#Logs here

$logtime = Get-Date -Format "dd_MM_yyyy_HHmm"
$logpath1 = "C:\Scripts\batch_VEEAM_Backups\VEEAM_Backup_Backup_Errors.txt"
$logpath2 = "C:\Scripts\batch_VEEAM_Backups\VEEAM_Backup_Results.txt"

##################################################################
######                  Tasks Here                          ###### 
##################################################################


foreach ($VMServer in $VMS) {
    $VM = $VMServer.vmnames
    $Directory = $VMServer.Directory
    $HostName = $VMServer.HostName
    $EnableQuiescence = $VMServer.EnableQuiescence
    $removetxt = "Deletion of prev backup completed for $VM in $Directory"
    #$removetxt1 = "No previous backup found for $VM in $Directory"
    #$EmailSubject = "VEEAM Backup Task status from $VM"
    $remdir = $Directory + "\*"
    $Retention = "Never"
    $CompressionLevel = "5"
    #Email configuration here
    #$EnableNotification = $True
    $SMTPServer = "smtphub.server.local" #smtp server here
    $EmailFrom = "ittechteam@domain.com" #source email address here 
    $EmailTo = "destination@domain.com" #destination email address here
    #$MesssagyBody = @()
    $SubjectER = "$VM $logtime -Fail to Delete Previous Backup File"
    $BodyER = "$logtime $VM -Fail to Delete snapshot in path $Directory, Check why did not deleted the .vbk file."
    $SubjectER2 = "$VM $logtime -Fail to create Backup VEEAM File"
    #$BodyER3 = "$logtime $VM -Fail to create Backup VEEAM File in path $Directory, check why it didnt load VEEAM snapin correctly"
    $BodyER2 = "$logtime $VM -Fail to create Backup VEEAM File in path $Directory, Check why did not run the backup task."
    #Here deletion of previous snapshot tasks.
    try {
        $prevbkp = Get-ChildItem -Path $Directory | Where-Object { $_.Name -match $VM } | Select-Object -First 1 
        Start-Sleep -s 1
        remove-item -path $remdir -include $prevbkp -Recurse -ErrorAction SilentlyContinue
        Start-Sleep -s 1
        Add-Content -path $logpath2 $removetxt, $logtime, "Going to VEEAM Backup Module now for $VM", "-------------------------"
        Write-Host "delete previous shapshot completed, continue to snappin for $VM"
    }
    catch {
        Add-Content -path $logpath1 $BodyER, "-------------------------"
        Send-MailMessage -to $EmailTo -From $EmailFrom -smtpserver $SMTPServer -Subject $SubjectER -body $BodyER
        Write-Host "break because something broke while trying to delete the snapshot for $VM"
    }
    #Here starts the backup task.
    try {
        Add-PSSnapIn VeeamPSSnapin -ErrorAction SilentlyContinue
        #Here the switches for backup task
        $Server = Get-VBRServer -name $HostName
        $VM = Find-VBRViEntity -Name $VM -Server $Server
        Write-Host "load VEEAMPSSnapin okay" 
    }
    catch {
        Add-Content -path $logpath1 $VM, "Fail to delete snapshot", $logtime, "-------------------------"
        Send-MailMessage -to $EmailTo -From $EmailFrom -smtpserver $SMTPServer -Subject $SubjectER2 -body $BodyER2
        Write-Host "break because something broke while loading the snapin in the backup server"
    }
    try {
        Start-Sleep -s 1
        Start-VBRZip -Entity $VM -Folder $Directory -Compression $CompressionLevel -DisableQuiesce:(!$EnableQuiescence) -AutoDelete $Retention | out-null
    }
    catch {
        Add-Content $logpath1 $VM, "fail", $logtime
        Send-MailMessage -to $EmailTo -From $EmailFrom -smtpserver $SMTPServer -Subject $SubjectER2 -body $BodyER2
        Write-Host "break because something broke while running the backup task for $VM"
    }
    Write-Host "-----------------------------------------$VM task completed-----------------------------------------------------"  
}