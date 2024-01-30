# AD Users wiht passwd set not to Expire
# I also select from specific OU's listed in the variables.
#
Remove-Item 'C:\scripts_Gus\AD\Report_Results\ADUsers_Passwd_Not2_Expire.csv' -ErrorAction SilentlyContinue  
#   
#Email config here
$EmailParams = @{
    EnableNotification = $True
    SMTPServer         = "smtp.domain.local" # your SMTP server here
    EmailFrom          = "Alerts@domain.co.uk" # your source email here
    time               = get-date -Format MMMM_yyyy
    EmailTo            = "gustavo.parrasanguineti@domain.co.uk" # your recipient here 
    Subject            = "ADReports $time"
    $BodyMSG           = "This Report is ready.
            
            The Report contains: 
                      - Enable AD accounts with passwords set to never expire.
                      - We search in the domain domain.local the OU's:
                                        
            This report is ready for collection from path:  \\someshare.domain.com\Report_Results\ADUsers_Passwd_Not2_Expire.csv
                    
            If the report is not there or there is issues with the report, please let us know.
         
            Regards
            Gus
          "
}
# AD module
Import-Module activedirectory
# export data
Add-Content 'C:\scripts_Gus\AD\Report_Results\ADUsers_Passwd_Not2_Expire.csv' 'PasswordNeverExpires, Name, SamAccount, LastLogon, Manager, OU'
$result1 = 'C:\scripts_Gus\AD\Report_Results\ADUsers_Passwd_Not2_Expire.csv'
#time
$time = (Get-Date)
#
#RAW
get-aduser -filter { Enabled -eq $true -and PasswordNeverExpires -eq $true } -SearchBase "Some OU= to scan" -properties SamAccountName, Name, LastLogonDate, Manager, DistinguishedName, PasswordNeverExpires | Sort-Object | Select-Object LastLogonDate, Name, Manager, SamAccountName, DistinguishedName, PasswordNeverExpires | Export-Csv 'C:\scripts_Gus\AD\RAW\ADUsers_Passwd_Not2_Expire.csv' -ErrorAction Stop
#
# Add 0 to Null on csv
$csv = import-csv 'C:\scripts_Gus\AD\RAW\ADUsers_Passwd_Not2_Expire.csv'
$csv | ForEach-Object {
    if ($_.LastLogonDate -eq "") { $_.LastLogonDate = "0" }
    if ($_.Name -eq "") { $_.Name = "0" }
    if ($_.SamAccount -eq "") { $_.SamAccount = "0" }
    if ($_.Manager -eq "") { $_.Manager = "0" }
}
$csv | export-csv 'C:\scripts_Gus\AD\RAW\ADUsers_Passwd_Not2_Expire_0.csv' -NoTypeInformation
#import 0 csv
$ADUSERS = import-csv 'C:\scripts_Gus\AD\RAW\ADUsers_Passwd_Not2_Expire_0.csv'
foreach ($user in $ADUSERS) {
    $u = $user.name
    $v = $user.manager
    $s = $user.SamAccountName
    $p = $user.PasswordNeverExpires
    $lastlogon = $user.LastLogonDate
    # OU's and checkers
    $OU1 = $user.DistinguishedName | Select-String -Pattern 'OU=OU1*' -ErrorAction SilentlyContinue
    if ($null -ne $OU1) { $OU1 = "OU1" }
    $OU2 = $user.DistinguishedName | Select-String -Pattern 'OU=OU2*' -ErrorAction SilentlyContinue
    if ($null -ne $OU2) { $OU2 = "OU2" }
    $OU3 = $user.DistinguishedName | Select-String -Pattern 'OU=OU3*' -ErrorAction SilentlyContinue
    if ($null -ne $OU3) { $OU3 = "OU3" }
    $OU4 = $user.DistinguishedName | Select-String -Pattern 'OU=OU4*' -ErrorAction SilentlyContinue
    if ($null -ne $OU4) { $OU4 = "OU4" }
    if ($OU1.count -eq "0" -and $OU2.count -eq "0" -and $OU3.count -eq "0" -and $OU4.count -eq "0") { "Nothing to do with $u" }
    else {
        $a = @($OU1, $OU2, $OU3, $OU4)
        #checkers
        if ($v -eq "0") { $nv = $v }
        elseif ($v -ne "0") { $nv = $v.Substring(0, $v.IndexOf(',')).trim('CN=') }
        #record
        write-host '===>>>' $u ' set with password not to expire' 
        Add-Content $result1 "$p,$u,$s,$lastlogon,$nv,$a"
        start-sleep -s 1
    }                                                                                          
}
Move-Item -Path $result1 -Destination '\\someshare.domain.com\'                   
#housekeep
Remove-Item 'C:\scripts_Gus\AD\RAW\ADUsers_Passwd_Not2_Expire_0.csv' -ErrorAction SilentlyContinue
Remove-Item 'C:\scripts_Gus\AD\RAW\ADUsers_Passwd_Not2_Expire.csv'   -ErrorAction SilentlyContinue 
#send email
Send-MailMessage @EmailParams
