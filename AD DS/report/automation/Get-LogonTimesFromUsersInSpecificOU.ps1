# Last logon time target specific OU's
# the report is put in a shared folder.
# I also select from specific OU's listed in the variables.
#
Remove-Item 'C:\scripts_Gus\AD\Report_Results\ADUsers_LastLogon_ALL_TargetOUs.csv' -ErrorAction SilentlyContinue     
#
#Email config here
$EmailParams = @ {
    EnableNotification = $True
    SMTPServer      = "smtp.domain.local" # your SMTP server here
    EmailFrom       = "Alerts@domain.co.uk" # your source email here
    time            = get-date -Format MMMM_yyyy
    EmailTo         = "gustavo.parrasanguineti@domain.co.uk" # your recipient here 
    Subject         = "ADReports $time"
    BodyMSG         = "This Report is ready.
            
            The Report contains: 
                      - The last logon date of all users in the listed OUs.
                      - We search in the domain PPF.local in OU's:
                                                     
            This report is ready for collection from path: \\someshare.domain.com\ADUsers_LastLogon_ALL_TargetOUs.csv  <<<=== your share path
                    
            If the report is not there or there is issues with the report, please let us know.
         
            Regards
            Gus
          "
}
# AD module
Import-Module activedirectory
# export data
Add-Content 'C:\scripts_Gus\AD\Report_Results\ADUsers_LastLogon_ALL_TargetOUs.csv' 'LastLogon, Date, Name, SamAccount, Manager, OU'
$result1 = 'C:\scripts_Gus\AD\Report_Results\ADUsers_LastLogon_ALL_TargetOUs.csv'
#time
$time = (Get-Date)
#
#RAW
#provide the distiguished OU name:
get-aduser -filter { Enabled -eq $true } -SearchBase "Some OU= to scan" -properties LastLogonDate, Name, Manager, SamAccountName, DistinguishedName | Sort-Object | Select-Object LastLogonDate, Name, Manager, SamAccountName, DistinguishedName | Export-Csv 'C:\scripts_Gus\AD\RAW\LastLogonALLUsers.csv' -ErrorAction SilentlyContinue
#
# Add 0 to Null on csv
$csv = import-csv 'C:\scripts_Gus\AD\RAW\LastLogonALLUsers.csv'
$csv | ForEach-Object {
    if ($_.LastLogonDate -eq "") { $_.LastLogonDate = "0" }
    if ($_.Date -eq "") { $_.Date = "0" }
    if ($_.Name -eq "") { $_.Name = "0" }
    if ($_.SamAccount -eq "") { $_.SamAccount = "0" }
    if ($_.Manager -eq "") { $_.Manager = "0" }
}
$csv | export-csv 'C:\scripts_Gus\AD\RAW\LastLogonALLUsers_0.csv' -NoTypeInformation
#import 0 csv
$ADUSERS = import-csv 'C:\scripts_Gus\AD\RAW\LastLogonALLUsers_0.csv'
foreach ($user in $ADUSERS) {
    $u = $user.name
    $v = $user.manager
    $s = $user.SamAccountName
    $lastlogon = $user.LastLogonDate
    $StartDate = $time.ToString("dd/MM/yyyy hh:mm:ss")
    # OU's and checkers
    $OU1 = $user.DistinguishedName | Select-String -Pattern 'OU=OU1*' -ErrorAction SilentlyContinue
    if ($null -ne $OU1) { $OU1 = "OU1" }
    $OU2 = $user.DistinguishedName | Select-String -Pattern 'OU=OU2*' -ErrorAction SilentlyContinue
    if ($null -ne $OU2) { $OU2 = "OU2" }
    $OU3 = $user.DistinguishedName | Select-String -Pattern 'OU=OU3*' -ErrorAction SilentlyContinue
    if ($null -ne $OU3) { $OU3 = "OU3" }
    $OU4 = $user.DistinguishedName | Select-String -Pattern 'OU=OU4*' -ErrorAction SilentlyContinue
    if ($null -ne $OU4) { $OU4 = "OU4" }
    $OU5 = $user.DistinguishedName | Select-String -Pattern 'OU=OU5*' -ErrorAction SilentlyContinue
    if ($null -ne $OU5) { $OU5 = "OU5" }
    if ($OU1.count -eq 0 -and $OU2.count -eq 0 -and $OU3.count -eq 0 -and $OU4.count -eq 0 -and $OU5.count -eq 0) { "Not in specific OUs, Nothing to do with $u" }
    else {
        $a = @($OU1, $OU2, $OU3, $OU4, $OU5)
        #checkers
        if ($v -eq 0) { $nv = $v }
        elseif ($v -ne 0) { $nv = $v.Substring(0, $v.IndexOf(',')).trim('CN=') }
        if ($lastlogon -eq 0) {
            $lastlogon = $user.LastLogonDate
            $DaysAgo = "0"
        }
        elseif ($lastlogon -ne 0) {
            $compare = New-TimeSpan -Start $StartDate -End $lastlogon -ErrorAction SilentlyContinue
            $DaysOffline = $compare.Days.ToString('d').trim('-')
            $DaysAgo = $DaysOffline + ' Days ago'
        }
        #record
        write-host '===>>>  ' $u, $DaysAgo 
        Add-Content $result1 "$lastlogon,$DaysAgo,$u,$s,$nv,$a"
        start-sleep -s 1
    }                                                                                          
}
Move-Item -Path $result1 -Destination '\\someshare.domain.com\'                   
#housekeep
Remove-Item 'C:\scripts_Gus\AD\RAW\LastLogonALLUsers.csv' -ErrorAction SilentlyContinue
Remove-Item 'C:\scripts_Gus\AD\RAW\LastLogonALLUsers_0.csv'   -ErrorAction SilentlyContinue 
#send email
Send-MailMessage @EmailParams
