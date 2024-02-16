# gather AD DS Users, line managers and Departments. 
import-module activedirectory
#
#housekeep
Remove-Item 'D:\scripts_Gus\Report_Results\Users&LineManagers.csv' -ea SilentlyContinue
#logs
Add-Content 'D:\scripts_Gus\Report_Results\Users&LineManagers.csv' "DisplayName, Manager, Department"
$result = 'D:\scripts_Gus\Report_Results\Users&LineManagers.csv'
#
$err = "No LineManager in AD"
$err1 = "No Department in AD"
#
Get-ADUser -searchbase 'your distinguished name here' -Filter { Enabled -eq $True } -Properties DisplayName, Manager, Department | Select-Object DisplayName, Manager, Department | Export-Csv 'D:\scripts_Gus\RAW\list.csv'
# Add 0 to Null on csv
$csv = import-csv 'D:\scripts_Gus\RAW\list.csv'
$csv | ForEach-Object {
    if ($_.Manager -eq "") { $_.Manager = "0" }
    if ($_.Department -eq "") { $_.Department = "0" }
}
$csv | export-csv 'D:\scripts_Gus\RAW\list_0.csv' -NoTypeInformation
#import 0 csv
$raw = import-csv 'D:\scripts_Gus\RAW\list_0.csv'
foreach ($employee in $raw) {
    $n = $employee.DisplayName 
    $m = $employee.Manager 
    $d = $employee.Department
    Start-Sleep -s 1
    if ($m -eq 0 -and $d -eq 0) {
        " ===>>> $n does not have LineManager or Department in AD"
        Add-Content $result "$n, $err, $err1"
    }
    elseif ($m -eq 0 -and $d -ne 0) {
        " ===>>> $n does not have LineManager"
        Add-Content $result "$n, $err, $d"
    }
    elseif ($null -ne $m -and $null -eq $d) {
        " ===>>> $n does not have Department"
        $mt = $m.Substring(0, $m.IndexOf(',')).trim('CN=')
        Add-Content $result "$n, $mt, $err1"
    }
    elseif ($null -ne $m -and $null -ne $d) {
        " ===>>> $n have both"
        $mt = $m.Substring(0, $m.IndexOf(',')).trim('CN=')
        Add-Content $result "$n, $mt, $d"
    }
}
Remove-Item 'D:\scripts_Gus\RAW\list.csv' -ea SilentlyContinue
Remove-Item 'D:\scripts_Gus\RAW\list_0.csv' -ea SilentlyContinue
