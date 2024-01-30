# Does pull a list of users from AD DS without login for >30 days 
# change NULL to 0 in cells and Import back to trim dates/times and others if need it.
#
# I also select from specific OU's listed in the variables.
#
Remove-Item 'C:\scripts_Gus\AD\Report_Results\LastLogonUsers_30Days.csv' -ErrorAction SilentlyContinue     
#Email config here
$EmailParams = @{
    EnableNotification = $True
    SMTPServer         = "smtp.domain.local" # your SMTP server here
    EmailFrom          = "Alerts@domain.co.uk" # your source email here
    time               = get-date -Format MMMM_yyyy
    EmailTo            = "gustavo.parrasanguineti@domain.co.uk" # your recipient here 
    Subject            = "ADReports $time"
    BodyMSG            = "This Report is ready.
            
            The Report contains: 
                      - Enable AD accounts not logged into domain.local for more than 30 days.
                      - Last known logon date.
                      - We search in the domain domain.local the OU's:
                                                     
            This report is ready for collection from path: \\someshare.domain.com\LastLogonUsers_30Days.csv  <<<=== your share path
                    
            If the report is not there or there is issues with the report, please let us know.
         
            Regards
            Gus
          "
}
# AD module
Import-Module activedirectory
# export data
Add-Content 'C:\scripts_Gus\AD\Report_Results\LastLogonUsers_30Days.csv' 'LastLogon, Date, Name, SamAccount, Manager, OU'
$result1 = 'C:\scripts_Gus\AD\Report_Results\LastLogonUsers_30Days.csv'
#time
$time = (Get-Date)
$tunetime = ($time).AddDays(-30)
#
#RAW
get-aduser -filter { Enabled -eq $true } -SearchBase "Some OU= to scan" -properties SamAccountName, Name, LastLogonDate, Manager, DistinguishedName | Where-Object { $_.LastLogonDate -lt $tunetime } | Sort-Object | Select-Object LastLogonDate, Name, Manager, SamAccountName, DistinguishedName | Export-Csv 'C:\scripts_Gus\AD\RAW\LastLogonUsers_30Days.csv' -ErrorAction SilentlyContinue
#
# Add 0 to Null on csv
$csv = import-csv 'C:\scripts_Gus\AD\RAW\LastLogonUsers_30Days.csv'
$csv | ForEach-Object {
    if ($_.LastLogonDate -eq "") { $_.LastLogonDate = "0" }
    if ($_.Date -eq "") { $_.Date = "0" }
    if ($_.Name -eq "") { $_.Name = "0" }
    if ($_.SamAccount -eq "") { $_.SamAccount = "0" }
    if ($_.Manager -eq "") { $_.Manager = "0" }
}
$csv | export-csv 'C:\scripts_Gus\AD\RAW\LastLogonUsers_30Days_0.csv' -NoTypeInformation
#import 0 csv
$ADUSERS = import-csv 'C:\scripts_Gus\AD\RAW\LastLogonUsers_30Days_0.csv'
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
    if ($OU1.count -eq "0" -and $OU2.count -eq "0" -and $OU3.count -eq "0" -and $OU4.count -eq "0") { "Nothing to do with $u" }
    else {
        $a = @($OU1, $OU2, $OU3, $OU4)
        #checkers
        if ($v -eq "0") { $nv = $v }
        elseif ($v -ne "0") { $nv = $v.Substring(0, $v.IndexOf(',')).trim('CN=') }
        if ($lastlogon -eq "0") {
            $lastlogon = $user.LastLogonDate
            $DaysAgo = "0"
        }
        elseif ($lastlogon -ne "0") {
            $compare = New-TimeSpan -Start $StartDate -End $lastlogon -ErrorAction SilentlyContinue
            $DaysOffline = $compare.Days.ToString('d').trim('-')
            $DaysAgo = $DaysOffline + ' Days ago'
        }
        #record
        write-host '===>>>' $u, $DaysAgo 
        Add-Content $result1 "$lastlogon,$DaysAgo,$u,$s,$nv,$a"
        start-sleep -s 1
    }                                                                                          
}                 
Move-Item -Path $result1 -Destination '\\someshare.domain.com\'  
#housekeep
Remove-Item 'C:\scripts_Gus\AD\RAW\LastLogonUsers_30Days_0.csv' -ErrorAction SilentlyContinue
Remove-Item 'C:\scripts_Gus\AD\RAW\LastLogonUsers_30Days.csv'   -ErrorAction SilentlyContinue
#send MSG
Send-MailMessage @EmailParams
