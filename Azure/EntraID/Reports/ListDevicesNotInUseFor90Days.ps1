<# 
gather a list of devices without logins for 90 days in EntraID (ex Azure AD)
you need the AzureAD Ps module & the appropriate permissions
#>
Import-Module AzureAD
Connect-AzureAD
#
$Date = (Get-Date).AddDays(-90)
Get-AzureADDevice -All:$Objectrue | Where-Object { $_.ApproximateLastLogonTimeStamp -le $Date } | select-object -Property AccountEnabled, DeviceId, DeviceOSType, DeviceOSVersion, DisplayName, DeviceTrustType, ApproximateLastLogonTimestamp | export-csv 'C:\Scripts_Gus\Azure\RAW\devicelist-olderthan-90days-summary.csv' -NoTypeInformation
# raw
$CSV = Import-Csv 'C:\Scripts_Gus\Azure\RAW\devicelist-olderthan-90days-summary.csv'

# offline and duplicas
Add-Content 'C:\Scripts_Gus\Azure\RAW\duplicas_outof90days.csv' "device"
$Results = 'C:\Scripts_Gus\Azure\RAW\duplicas_outof90days.csv'
foreach ($Object in $CSV) {
    $DeviceDisplayName = $Object.displayname
                   
    if ($DeviceDisplayName -ne $nul) {
        "$DeviceDisplayName checking for duplicas"
        Get-azureaddevice | Where-Object { $_.Displayname -like "$DeviceDisplayName" } | Select-Object Displayname
        Add-Content $Results "$DeviceDisplayName"
        start-sleep -s 1
    }        
}
