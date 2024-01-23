<#Re-Synch devices on Intune
If you have new policies or remediations or you need to sync devices, this is the quickes way to synch policies in bulk on Intune.
you need the PS Module for MS Graph, the list of devices that you want to re-synch 
#>
Connect-MSGraph
#
remove-item 'C:\Scripts_Gus\Azure\Intune_MDM\Results\deviceresults.csv' -ErrorAction SilentlyContinue
Add-Content 'C:\Scripts_Gus\Azure\Intune_MDM\Results\deviceresults.csv' "DeviceName, Id, LastSyncDateTime, Status"
$Result = 'C:\Scripts_Gus\Azure\Intune_MDM\Results\deviceresults.csv'
$RAW = Import-Csv 'C:\Scripts_Gus\Azure\Intune_MDM\RAW\devices_re-synch_MDM.csv'
#
foreach ($Device in $RAW) {
    $DeviceName = $Device.device
                        
    $Details = Get-IntuneManagedDevice | Where-Object { $_.DeviceName -eq "$DeviceName" }
    $LastSync = $details.lastSyncDateTime
    $ID = $Details.id
    if ($Null -ne $Details) {
        $Details | Invoke-IntuneManagedDeviceSyncDevice -ea SilentlyContinue
                                               
        "===>>> $DeviceName is set to re-synch the MDM Policy"
        Start-Sleep -s 1
        Add-Content $result "$DeviceName,$ID,$LastSync,re-synch" 
    }
    else {
        "==========>>>>$DeviceName  not located in MDM"
        Add-Content $Result "$DeviceName,,,Not_In_MDM"
    } 
}
