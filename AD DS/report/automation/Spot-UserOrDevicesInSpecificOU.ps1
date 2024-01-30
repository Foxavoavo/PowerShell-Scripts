# lookup for devices and users in specific OU's
# run as scheduled script in a Domain controller to spot devices or Users in specific OU's. 
#
Import-Module activedirectory
#
#email config
#Email config here
$EmailParams = @{
    EnableNotification = $True
    SMTPServer         = "smtp.domain.local" # your SMTP server here
    EmailFrom          = "Alerts@domain.co.uk" # your source email here
    time               = get-date -Format hh:mm dd_MMMM_yyyy
    EmailTo            = "gustavo.parrasanguineti@domain.co.uk" # your recipient here 
    Subject            = "$time - Object in OU found!" 
}
#checkers in multiple OU's
$User1 = get-aduser -filter * -searchbase "Some OU= to scan" -pro * | Select-Object name, Modified -ErrorAction SilentlyContinue # provide the distiguished OU name
$Device1 = get-adcomputer -filter * -searchbase "Some OU= to scan" -pro * | Select-Object name, Modified -ErrorAction SilentlyContinue # provide the distiguished OU name here
#
$User2 = get-aduser -filter * -searchbase "Some other OU= to scan" -pro * | Select-Object name, Modified -ErrorAction SilentlyContinue # provide the distiguished OU name here
$Device2 = get-adcomputer -filter * -searchbase "Some other OU= to scan" -pro * | Select-Object name, Modified -ErrorAction SilentlyContinue # provide the distiguished OU name here
#
#
If ($Null -ne $User1) {
    $name = $User1.name 
    $addtime = $User1.modified
    $path = "ppf.local/PPFP/EDU's/Troubleshooting"
    $BodyMSG = "An object called $name is been modified @ $addtime and is located in this path: $path"
}
If ($null -ne $Device1) {
    $name = $Device1.name 
    $addtime = $Device1.modified
    $path = "ppf.local/PPFP/EDU's/Troubleshooting"
    $BodyMSG1 = "An object called $name is been modified @ $addtime and is located in this path: $path"
}
If ($null -ne $User2) {
    $name = $User2.name 
    $addtime = $User2.modified
    $path = "ppf.local/PPFP/Users/Troubleshooting"
    $BodyMSG2 = "An object called $name is been modified @ $addtime and is located in this path: $path"
}
If ($null -ne $Device2) {
    $name = $Device2.name 
    $addtime = $Device2.modified
    $path = "ppf.local/PPFP/Users/Troubleshooting"
    $BodyMSG3 = "An object called $name is been modified @ $addtime and is located in this path: $path"
}
Else { $notfounds = "The troubleshooting OU's are all empty" }
#msg out here 
If ($null -ne $BodyMSG -or $null -ne $BodyMSG1 -or $null -ne $BodyMSG2 -or $null -ne $BodyMSG3) {
    $Gathered = "Devices-User Object Found in troubleshoot OU! 
                                                  Please verify the object in the path:
                                                                                         $BodyMSG
                                                                                         $BodyMSG1
                                                                                         $BodyMSG2
                                                                                         $BodyMSG3"
    Send-MailMessage @EmailParams -body $Gathered
}
Else { Send-MailMessage @EmailParams -body $notfounds }
