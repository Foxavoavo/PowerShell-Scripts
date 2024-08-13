<#

https://docs.chocolatey.org/en-us/central-management/usage/api/examples/

Create or add your devices in the CCM group.
If the CCM group exist, the script will add the device to the group.
If the CCM group don't exits, the script will create the CCM group and add the devices to it.

- You need your CCM server name.
- You need credentials to access CCM via the API with the appropriate rights.
- You need to create a list of devices to upload to the CCM group. (I use a .csv file) in line 28.

#>

# Session server
#####################################
$CcmServerHostname = 'urCCMServer' ### <<<=== Your CCM server here.
#####################################
# Credentials
#$Credential = Get-Credential
$username = "UrUsername"
$password = "YourCCMPasswordHere" | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password
# Group values
###################################################################################
$GroupName = 'Devices From TEST API' ### <<<=== Your CCM Group name. 
$GroupDescription = 'Some test group from API' ### <<<=== your CCM Group description.
$SelectedDevices = Import-Csv "C:\Scripts_Gus\RAW\devices.csv" ### <<<=== Your device list.
###################################################################################
# Tailor devices params
[regex]$regex = '\;\s*\w*id\=(?<=)\d[0-9]*'
$Values = New-Object System.Collections.ArrayList
$Body = @{
    UsernameOrEmailAddress = $Credential.UserName
    Password               = $Credential.GetNetworkCredential().Password
}
# API GET Session 
$SwaggerSession = Invoke-WebRequest -Uri "https://$CcmServerHostname/Account/Login" -Method POST -ContentType 'application/x-www-form-urlencoded' -Body $body -SessionVariable Session -ErrorAction Stop
If ($SwaggerSession.count -gt 0) {

    # Get CM computer list
    $params = @{
        Uri        = "https://$CCmServerHostname/api/services/app/Computers/GetAll"
        Method     = 'GET'
        WebSession = $Session
    }
    $CCMComputerFullList = Invoke-RestMethod @params
    # Match you devices computer id
    ForEach ($Device in $SelectedDevices) {
        $DeviceName = $Device.Name 
        $Raw = $CCMComputerFullList.result | select-string -Pattern "$DeviceName.*" | Select-Object -Property * | Sort-Object -Descending | Select-Object -First 1
        $DeviceId = ($regex.Matches($Raw.line).Value) -replace ('\;\s\w*id\=', '')
        $Values.add($DeviceId) | Out-Null
    }
    # Array corresponding computer id 
    $Tailored = ForEach ($id in $Values) { [PSCustomObject]@{'computerid' = $id } }
    # Check if group exist and append.
    $params = @{
        Uri        = "https://$CcmServerHostname/api/services/app/Groups/GetAll"
        Method     = "GET"
        WebSession = $Session
    }
    #Action
    $Group = Invoke-RestMethod @params | Select-Object -ExpandProperty result | Where-Object { $_.Name -eq $GroupName }
    $GroupId = $Group.id 
    Switch ($GroupId) {
        { $_.count -gt 0 } {
            Write-Output "Existing group found with name: $GroupName ===>>> Adding devices to group"
            $params = @{
                Uri         = "https://$CcmServerHostname/api/services/app/ComputerGroup/GetAllByGroupId" + '?groupId=' + $GroupId 
                Method      = "GET"
                WebSession  = $Session
                contenttype = 'application/json' 
            }
            $GroupDetails = Invoke-RestMethod @params
            $GroupDevicesId = $GroupDetails.result.computerId
            $DeviceIdValues = New-Object System.Collections.ArrayList
            # Tailor device list, skipping duplicas
            ForEach ($Device in $Tailored) {
                $DeviceId = $Device.computerid
                If (($GroupDevicesId | Select-String -Pattern "$DeviceId.*").count -gt 0) { Write-Output "$DeviceId already in the csv list, skipping duplica" }
                If (($GroupDevicesId | Select-String -Pattern "$DeviceId.*").count -eq 0) {
                    Write-Output "$DeviceId not in the csv list, adding device to new list" 
                    $DeviceIdValues.add($DeviceId) | Out-Null
                }
            }
            # Put the group new members in array.
            If ($DeviceIdValues.Count -gt 0) {
                ForEach ($Id in $DeviceIdValues) {
                    $DeviceId = $Id
                    $Params = @{
                        Uri         = "https://$CcmServerHostname/api/services/app/ComputerGroup/CreateOrEdit"
                        Method      = 'POST'
                        WebSession  = $Session
                        ContentType = 'application/json'
                        Body        = @{
                            computerId = $DeviceId  
                            groupId    = $GroupId        
                        } | ConvertTo-Json
                    }
                    $Action = Invoke-RestMethod @params
                    $Result = $Action.Success  
                    Write-Output "Device $DeviceId  ==>>> add it to $GroupName  $Result"
                }
            }
            Else { Write-Output "Your device array to upload is empty" }
        }         
        { $_.count -eq 0 } {
            Write-Output "Group not found with name: $GroupName ===>>> Creating group now"
            #Onboard device list
            $Params = @{
                Uri         = "https://$CcmServerHostname/api/services/app/Groups/CreateOrEdit"
                Method      = 'POST'
                WebSession  = $Session
                ContentType = 'application/json'
                Body        = @{
                    name        = $GroupName
                    description = $GroupDescription
                    groups      = @()
                    computers   = @( $Tailored )
                } | ConvertTo-Json
            }
            #Action 
            $Action = Invoke-RestMethod @params
            $Result = $Action.Success  
            Write-Output "Created $GroupName ==>>> $Result"
        }
    }
}
Else { Write-Output "Swagger Session didn't load" }
