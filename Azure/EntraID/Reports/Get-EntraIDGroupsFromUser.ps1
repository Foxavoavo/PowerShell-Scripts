<# get entraID user membership
# get all user Entra ID groups and write them in a Report.
#>
import-module AzureAD
Connect-AzureAD
#
remove-item -Path "C:\Scripts_Gus\Azure\Results\group_list.csv" -ea SilentlyContinue
Add-Content "C:\Scripts_Gus\Azure\Results\group_list.csv" "DisplayName, MailEnabled, Mail"
$Result = "C:\Scripts_Gus\Azure\Results\group_list.csv" 
#
$RAW_Users = Import-Csv 'C:\Scripts_Gus\Azure\RAW\LGUsers.csv'
foreach ($user in $RAW_Users) {
    $Usr = $user.Name
    #checks
    Start-Sleep -s 1
    $Object = get-azureADuser -SearchString $Usr | Select-Object ObjectId | Select-Object -First 1 -ea SilentlyContinue
    if ($Null -ne $Object) {
        $AzureGroups = Get-AzureADUserMembership -ObjectId $Object.ObjectId | Select-Object DisplayName, Mail, MailEnabled -ea SilentlyContinue
        foreach ($AzureGroup in $AzureGroups) {
            $AG = $AzureGroup.DisplayName
            $GT = $AzureGroup.MailEnabled
            $E = $AzureGroup.Mail 
            #report here
            Start-Sleep -s 1
            "===>>> $AG checked okay"
            Add-Content $Result "$AG,$GT,$e" 
        }
    }
    ElseiF ($Null -eq $Object) {
        "$Usr not in Azure"
    }
}
