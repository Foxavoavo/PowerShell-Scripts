<# Remove Intune devices in bulk.
*you need the appropriate administrative rights on Intune.
create the files and folders.
create your list of devices to remove.
connect to MDM usgin MSGraph.
execute the script.
#>
Connect-MSGraph
#log
Remove-Item 'C:\Scripts_Gus\Azure\Intune_MDM\Results\deviceresults.csv' -ErrorAction SilentlyContinue
Add-Content 'C:\Scripts_Gus\Azure\Intune_MDM\Results\deviceresults.csv' "DeviceName, Id, Status"
$Result = 'C:\Scripts_Gus\Azure\Intune_MDM\Results\deviceresults.csv'
#
$RAW = Import-Csv 'C:\Scripts_Gus\Azure\Intune_MDM\RAW\devices_R.csv'
#
Foreach ($Device in $RAW) {
    $DeviceName = $Device.device
                        
    $DeviceDetails = Get-IntuneManagedDevice | Where-Object { $_.DeviceName -eq "$DeviceName" } | Select-Object devicename, id -ErrorAction SilentlyContinue
    If ($Null -ne $DeviceDetails) {
        $ID = $DeviceDetails.id
        Remove-IntunemanagedDevice -manageddeviceID $ID -ErrorAction SilentlyContinue
        "===>>> $DeviceName is been remove from Intune"
        Start-Sleep -s 1
        Add-Content $Result "$DeviceName,$ID,removed" 
    }
    Else {
        "===>>>$DeviceName  not located in intune"
        Add-Content $Result "$DeviceName,,Not_In_Intune"
    } 
}
