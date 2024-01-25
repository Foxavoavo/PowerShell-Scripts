<#
I code this migration tool in PowerShell to migrate Microsoft Exchange on-premises Distribution Groups for a customer to their Exchange online, there was once a similar tool but I guess was retired.

requirements:

a) This tool needs to run from your Exchange server on-premises, does needs to be able to access you Exchange online from the same place too.
create the folders called:
C:\ScriptFolder\MigrationTool <<<=== (save here this code onto a .ps1 file in this folder)
C:\ScriptFolder\Raw
C:\ScriptFolder\Completed

skipped groups will be listed here:
C:\ScriptFolder\MigrationTool\skipgroups.csv
the activity log will be here: 
C:\ScriptFolder\MigrationTool\Activity.log


b) You need to have administrative rights in both (Exchange on-premises and EOL too)
c) You need to add your credentials to an object in lines #142,#143 and you on-premises exchange uri in line #146
the link to pass credentials:
https://sysadminguides.org/2017/05/02/how-to-pass-credentials-in-powershell/
For line 146:
https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell?view=exchange-ps
Connect to a remote Exchange server.
For line #305 & 306
Replace *@YourDomainName.com with your email domain in use.

the cmdlets I used:
https://learn.microsoft.com/en-us/powershell/module/exchange/set-distributiongroup?view=exchange-ps
https://learn.microsoft.com/en-us/powershell/module/exchange/new-distributiongroup?view=exchange-ps

#################################################
The 1st part of the tool: 
a) Exports to a .csv the configuration details from the distribution groups.
b) Also gathers the members and managers and SMTP addresses too.
c) Change the name of the distribution groups on-premises to 'DROPPED_DistributionGroupName' and also renames the SMTP addresses as 'DROPPED_SMTPAddresses'.

In line 177, the tool waits for 30' to allow the sync of the changed 'DROPPED_DistributionGroupNames' in between AD DS and AAD (New Entra ID).

*** Will recommend if you have access to the ADSync tool to run a delta sync on these 30'time window or wait 30'.
to do a Delta sync:
https://learn.microsoft.com/en-us/azure/active-directory/hybrid/connect/how-to-connect-sync-feature-scheduler

I did lots of Error Handling as well, the tool will skip Distribution Groups that don’t contain SMTP's or was unable to gather the details from the 1st part.

#################################################
The 2nd part of the tool:
a) Connects to Exchange online, will ask you for creds in line 211.
b) Run an array and compare the distribution group with the Skip list, if the group is in the list will be skip.
c) Creates the Distribution group and add all the details: Managers, Members, Configuration details.
    *** If the on-premises Distribution group name did not update in Exchange Online, the tool will add '_' while creating the Distribution group in Exchange Online. 
also here, lots of Error handling 

#################################################
the 3rd part of the tool:
a) attempt to change the exchange online distribution group names to the original names (try to remove the '_' from the distribution group name)
b) move the Distribution groups configuration files to the Completed folder.

***In case there is Distribution groups configuration files in the RAW folder, visit those groups, they might not be created in EOL.

#>

Function Set-Array {
    param($Name,
        $EmailAddresses,
        $ManagedBy
    )
    If ($Name) { $Value = "DROPPED_$Name" }
    If ($Null -ne $EmailAddresses) {
        $Value = New-Object System.Collections.ArrayList
        ForEach ($EmailAddress in $EmailAddresses) {
            $DropAddIt = ($EmailAddress.replace('smtp:', 'smtp:DROPPED_')).replace('SMTP:', 'SMTP:DROPPED_')
            $Value.add($DropAddIt) | Out-Null
        }
    }
    If ($Null -ne $ManagedBy) {
        $Value = New-Object System.Collections.ArrayList
        [regex]$regex = '(?<=\/)\w*\s\w*.*\S'
        ForEach ($Manager in $ManagedBy) {
            $tailor = $regex.Matches($Manager).Value | Select-Object -First 1
            $Value.add($tailor) | Out-Null
        }
    }    
    Write-Output $Value
}
Function Get-Boolean {
    param($Setting)
    If ($Setting -like 'True' -or $Setting -like 'Always' -or $Setting -like 'Open') { [bool]$True }
    If ($Setting -like 'False' -or $Setting -like 'Never' -or $Setting -like 'Close') { [bool]$False }
}
Function Start-CountdownTimer {
    <#
    https://www.powershellgallery.com/packages/start-countdowntimer/1.0/Content/Start-CountdownTimer.psm1
    #>
    param (
        [int]$Days = 0,
        [int]$Hours = 0,
        [int]$Minutes = 0,
        [int]$Seconds = 0,
        [int]$TickLength = 1
    )
    $t = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $Seconds
    $origpos = $host.UI.RawUI.CursorPosition
    $spinner = @('|', '/', '-', '\')
    $spinnerPos = 0
    $remain = $t
    $d = (get-date) + $t
    $remain = ($d - (get-date))
    while ($remain.TotalSeconds -gt 0) {
        Write-Host (" {0} " -f $spinner[$spinnerPos % 4]) -BackgroundColor White -ForegroundColor Black -NoNewline
        write-host (" {0}D {1:d2}h {2:d2}m {3:d2}s " -f $remain.Days, $remain.Hours, $remain.Minutes, $remain.Seconds)
        $host.UI.RawUI.CursorPosition = $origpos
        $spinnerPos += 1
        Start-Sleep -seconds $TickLength
        $remain = ($d - (get-date))
    }
    $host.UI.RawUI.CursorPosition = $origpos
    Write-Host " * "  -BackgroundColor White -ForegroundColor Black -NoNewline
    " Countdown finished"
}
#logging
$Time = get-date -Format 'dd/MM/yyyy hh:mm'
$StartTimes = "===>>> $Time"
Remove-Item 'C:\ScriptFolder\Raw\*' -Force -Recurse
Remove-Item 'C:\ScriptFolder\MigrationTool\Activity.log' -Force -Recurse -ea SilentlyContinue
Remove-Item 'C:\ScriptFolder\MigrationTool\skipgroups.csv' -Force -Recurse -ea SilentlyContinue
#
Add-Content 'C:\ScriptFolder\MigrationTool\Activity.log' $StartTimes
$Activitylog = 'C:\ScriptFolder\MigrationTool\Activity.log'
Add-Content 'C:\ScriptFolder\MigrationTool\skipgroups.csv' "GroupName"
$SkipGroups = 'C:\ScriptFolder\MigrationTool\skipgroups.csv'
#target groups
$DistributionGroupNames = Import-Csv 'C:\ScriptFolder\MigrationTool\DistributionGroupList.csv'

#On-premise exchange PSSession
<#
https://sysadminguides.org/2017/05/02/how-to-pass-credentials-in-powershell/
#>
$username = # your ADDS Admin UserName here.
$password = Get-Content "Your Password file here" | ConvertTo-SecureString # your password here.
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password
Try {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "your Exhange On-premise URI here" -Authentication Kerberos -Credential $creds # your Exchange on-prem uri here.
    Import-PSSession $Session -AllowClobber | Out-Null
}
Catch {
    $_.Exception
}
#on prem task
ForEach ($DistributionGroup in $DistributionGroupNames) {
    $DGroupName = $DistributionGroup.GroupName
    #Error evaluations
    $Evaluations = Get-DistributionGroup -identity $DGroupName -ea SilentlyContinue -wa SilentlyContinue | Where-Object { $_.DisplayName -notlike "DROPPED_$DGroupName" } | Select-Object Name
    $DistributionGroupName = $Evaluations.Name
    If ($Null -ne $Evaluations) {
        #Settings here
        $EmailAddresses = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty EmailAddresses
        $ManagedBy = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty ManagedBy
        $MemberJoinRestriction = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty MemberJoinRestriction
        $MemberDepartRestriction = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty MemberDepartRestriction
        $Alias = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty Alias
        $HiddenFromAddressListsEnabled = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty HiddenFromAddressListsEnabled
        $ModerationEnabled = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty ModerationEnabled
        $RequireSenderAuthenticationEnabled = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty RequireSenderAuthenticationEnabled
        $SendModerationNotifications = Get-DistributionGroup $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object -ExpandProperty SendModerationNotifications
        $DistributionGroupMembers = Get-DistributionGroupMember $DistributionGroupName -ea silentlycontinue -wa silentlycontinue | Select-Object PrimarySmtpAddress
        $Members = $DistributionGroupMembers.PrimarySmtpAddress
        #Tailor
        $EmailEvaluation = $EmailAddresses | Select-String -Pattern 'SMTP:*' -CaseSensitive
        If ($EmailEvaluation.count -eq 0) {
            Write-Output "===>>>(Warning) $DistributionGroupName doesnt have an active SMTP address,group excluded on C:\ScriptFolder\MigrationTool\skipgroups.csv"
            Add-Content $Activitylog "===>>>(Warning) $DistributionGroupName doesnt have an active SMTP address,group excluded on C:\ScriptFolder\MigrationTool\skipgroups.csv"
            Add-Content $SkipGroups "$DistributionGroupName"
            #Continue
        }
        Else {
            $EmailAddressesForImport = $EmailAddresses | Where-Object { $_ -like 'smtp*' }
            $Managers = Set-Array -ManagedBy $ManagedBy
            $DroppedDisplayName = Set-Array -Name $DistributionGroupName
            $DroppedAlias = Set-Array -Name $Alias
            $DroppedEmailAddresses = Set-Array -EmailAddresses $EmailAddresses
            #Logging
            $DistributionGroupDetailsPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Details.csv"
            $ManagersPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Managers.log"
            $MembersPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Members.log"
            $EmailAddressesForImportPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_EmailAddresses.log"
            Add-Content $DistributionGroupDetailsPath "DistributionGroupName,Alias,HiddenFromAddressListsEnabled,MemberJoinRestriction,MemberDepartRestriction,ModerationEnabled,RequireSenderAuthenticationEnabled,SendModerationNotifications"
            $DistributionGroupDetails = $DistributionGroupDetailsPath
            Add-Content $ManagersPath $Managers
            Add-Content $DistributionGroupDetails "$DistributionGroupName,$Alias,$HiddenFromAddressListsEnabled,$MemberJoinRestriction,$MemberDepartRestriction,$ModerationEnabled,$RequireSenderAuthenticationEnabled,$SendModerationNotifications"
            Add-Content $MembersPath $Members
            Add-Content $EmailAddressesForImportPath $EmailAddressesForImport
            #Commit settings
            Try {
                Set-DistributionGroup -Identity $DistributionGroupName -Name $DroppedDisplayName -DisplayName $DroppedDisplayName -Alias $DroppedAlias -EmailAddressPolicyEnabled $False -EmailAddresses $DroppedEmailAddresses -HiddenFromAddressListsEnabled:$True -ErrorAction silentlycontinue
                Start-Sleep -Seconds 1
                #Evaluations
                $LocalEvaluations = Get-Recipient $DistributionGroupName -erroraction SilentlyContinue | Where-Object { $_.Name -notlike "DROPPED_$DistributionGroupName" } | Select-Object name
                If ($LocalEvaluations.name.count -gt 0) {
                    Add-Content $Activitylog "===>>>(Warning) Unable to set DROPPED_$DGroupName the group is excluded on C:\ScriptFolder\MigrationTool\skipgroups.csv"
                    Add-Content $SkipGroups "$DGroupName"    
                }
                Else {
                    Write-Output "===>>> On-Prem $DistributionGroupName has been dropped."
                    Add-Content $Activitylog "===>>> On-Prem $DistributionGroupName has been dropped."
                }
            }
            Catch {
                $_.Exception
                Remove-PSSession $Session  
            }
        }
    }
    If ($Null -eq $Evaluations) {
        Write-Output "===>>> $DGroupName not detected"
        Add-Content $Activitylog "===>>>(Warning) $DGroupName not detected group excluded on C:\ScriptFolder\MigrationTool\skipgroups.csv"
        Add-Content $SkipGroups "$DGroupName"
        #Continue
    }   
}
$ContentSkipGroups = Get-Content $SkipGroups
If ($ContentSkipGroups.count -gt 1) {
    Write-Output "===>>> this distribution groups are excluded from the batch due to errors"
    Add-Content $Activitylog "===>>>(Warning) distribution groups are excluded from the batch due to problems group names reported on C:\ScriptFolder\MigrationTool\skipgroups.csv"
    Add-Content $Activitylog $SkipGroups
    Get-Content $SkipGroups

}
Start-CountdownTimer -Minutes 30
# Stage 2
$Time = get-date -Format 'dd/MM/yyyy hh:mm'
$StartTimes = "===>>> $Time"
$Activitylog = 'C:\ScriptFolder\MigrationTool\Activity.log'
Add-Content $Activitylog "$StartTimes ===>>> sync window completed."
$Confirmation = Read-Host "dl's on prem are drop, Please run the the AZ sync Pipeline. 
                               To proceed to the next step, choose(y or n)"
If ($Confirmation -eq 'y') {
    #online task
    Try {
        Import-Module ExchangeOnlineManagement
        Connect-ExchangeOnline  
    }
    Catch {
        $_.Exception
    }
    #target groups
    $DistributionGroupNames = Import-Csv 'C:\ScriptFolder\MigrationTool\DistributionGroupList.csv'
    #compares
    $SkipGroups = 'C:\ScriptFolder\MigrationTool\skipgroups.csv'
    $SkipGroupList = get-content $SkipGroups
    ForEach ($DistributionGroup in $DistributionGroupNames) {
        $DistributionGroupName = $DistributionGroup.GroupName
        $AvoidSkip = $SkipGroupList | Select-String -Pattern "$DistributionGroupName"   
        If ($Null -eq $AvoidSkip) {
            #Get settings 
            $DistributionGroupDetailsPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Details.csv"
            $DistributionGroupManagersPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Managers.log"
            $DistributionGroupMembersPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Members.log"
            $DistributionGroupEmailAddressesPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_EmailAddresses.log"
            If ((Test-Path $DistributionGroupDetailsPath) -eq $True -and (Test-Path $DistributionGroupManagersPath) -eq $True -and (Test-Path $DistributionGroupMembersPath) -eq $True -and (Test-Path $DistributionGroupEmailAddressesPath) -eq $True) {
                $DistributionGroupDetails = import-csv $DistributionGroupDetailsPath
                $DistributionGroupManagers = get-content $DistributionGroupManagersPath
                $DistributionGroupMembers = get-content $DistributionGroupMembersPath          
                $DistributionGroupEmailAddresses = get-content $DistributionGroupEmailAddressesPath | Where-Object { $_ -notlike "*.mail.onmicrosoft.com" } 
                # Compile function for new & set
                ForEach ($Detail in $DistributionGroupDetails) {
                    $Alias = $Detail.Alias
                    $MemberJoinRestriction = $Detail.MemberJoinRestriction
                    $MemberDepartRestriction = $Detail.MemberDepartRestriction
                    $SendModerationNotifications = $Detail.SendModerationNotifications
                    $Evaluation = Get-Recipient $DistributionGroupName -ErrorAction SilentlyContinue | Select-Object Name | Where-Object { $_.Name -match "$DistributionGroupName" }
                    If ($Evaluation.name.count -gt 0) {
                        $AlternativeAlias = '_' + (($Alias).replace(' ', ''))
                        $AlternativeGroupName = '_' + $DistributionGroupName
                        New-DistributionGroup -Name $AlternativeGroupName -DisplayName $AlternativeGroupName -Alias $AlternativeAlias -ErrorAction SilentlyContinue -ErrorVariable ErrorOutputMessage -WarningVariable WarningOutputMessage | Out-Null
                        $DistributionGroupName = $AlternativeGroupName
                        Add-Content $Activitylog "===>>> $DistributionGroupName created with additional character on the alias and DistributionGroupName."
                    }
                    Else {
                        New-DistributionGroup -Name $DistributionGroupName -DisplayName $DistributionGroupName -Alias $Alias -ErrorAction SilentlyContinue -ErrorVariable ErrorOutputMessage -WarningVariable WarningOutputMessage | Out-Null
                    }                
                    #Error evaluations
                    If ($ErrorOutputMessage.count -gt 0 -or $WarningOutputMessage.count -gt 0 -or $ErrorOutputMessage.count -eq 0 -or $WarningOutputMessage.count -eq 0) {
                        $ErrorEvaluations = $ErrorOutputMessage | Select-String -Pattern 'matches multiple entries*'
                        If ($Null -ne $ErrorEvaluations) {
                            Write-Output "===>>> $DistributionGroupName There are errors reported while creating the mailbox"
                            Add-Content $Activitylog "===>>> $DistributionGroupName There are errors reported while creating the mailbox"
                        }
                        If ($Null -ne $WarningOutputMessage) { Add-Content $Activitylog "===>>> $DistributionGroupName $WarningOutputMessage" }
                        If ($Null -eq $ErrorEvaluations) {
                            #EmailAddresses compares
                            $PresetSMTPAddresses = Get-DistributionGroup -Identity $DistributionGroupName | Select-Object -ExpandProperty EmailAddresses -ErrorAction SilentlyContinue
                            ForEach ($DistributionGroupEmailAddress in $DistributionGroupEmailAddresses) {
                                $Evaluation = $PresetSMTPAddresses | Select-String -Pattern "$DistributionGroupEmailAddress"
                                If ($Null -ne $Evaluation) { "==>>> $Evaluation already set" }
                                If ($Null -eq $Evaluation) {
                                    If ($DistributionGroupEmailAddress -clike 'SMTP*') {
                                        $NewPrimaryAddress = ($DistributionGroupEmailAddress).replace('SMTP:', '')
                                        Set-DistributionGroup -Identity $DistributionGroupName -PrimarySmtpAddress $NewPrimaryAddress -ErrorAction SilentlyContinue
                                        #SMTP Evaluation
                                        $SMTPEvaluation = Get-Recipient $DistributionGroupName -ErrorAction SilentlyContinue | Select-Object PrimarySMTPAddress
                                        If ($SMTPEvaluation.PrimarySMTPAddress -notlike '*@YourDomainName.co.uk') {
                                            $CustomSMTP = '_-' + (($DistributionGroupName).replace(' ', '')) + '@YourDomainName.co.uk'
                                            Set-DistributionGroup -Identity $DistributionGroupName -PrimarySmtpAddress $CustomSMTP -ErrorAction SilentlyContinue
                                            Write-Output "(!!!)===>>> Custom primary SMTP add it $DistributionGroupName, visit on post"
                                            Add-Content $Activitylog  "(!!!)===>>> Custom primary SMTP add it $DistributionGroupName, visit on post"
                                        }
                                        Else {
                                            Write-Output "===>>> $DistributionGroupEmailAddress Original Primary SMTP add it to $DistributionGroupName"
                                            Add-Content $Activitylog  "===>>> $DistributionGroupEmailAddress New Primary SMTP add it to $DistributionGroupName"
                                        }
                                    }
                                    If ($DistributionGroupEmailAddress -clike 'smtp*') {
                                        Set-DistributionGroup -Identity $DistributionGroupName -EmailAddresses @{Add = "$DistributionGroupEmailAddress" }
                                        "===>>> $DistributionGroupEmailAddress additional smtp add it"
                                        Add-Content $Activitylog "===>>> $DistributionGroupEmailAddress additional smtp add it"
                                    }
                                }
                            }
                            If ($Null -ne $DistributionGroupMembers) {
                                ForEach ($DistributionGroupMember in $DistributionGroupMembers) {
                                    $MemberEmail = Get-Recipient $DistributionGroupMember -ErrorAction SilentlyContinue | Select-Object primarysmtpaddress
                                    If ($Null -ne $MemberEmail) {
                                        $MemberAddress = $MemberEmail.primarysmtpaddress
                                        Try {
                                            Add-DistributionGroupMember -Identity $DistributionGroupName -Member $MemberAddress -ErrorAction SilentlyContinue
                                        
                                        }
                                        Catch {
                                            Add-Content $Activitylog "===>>> Unable to add $MemberAddress to $DistributionGroupName"
                                            Write-Output "===>>> Unable to add $MemberAddress to $DistributionGroupName"
                                        }
                                    }
                                }
                                Write-Output "===>>> Members Emailaddresses add it to $DistributionGroupName"
                                Add-Content $Activitylog "===>>> Members Emailaddresses add it to $DistributionGroupName"
                            }
                            If ($Null -ne $DistributionGroupManagers) {
                                $Values = New-Object System.Collections.ArrayList
                                Foreach ($DistributionGroupManager in $DistributionGroupManagers) {
                                    $ManagerEmail = Get-Recipient $DistributionGroupManager -ErrorAction SilentlyContinue | Select-Object primarysmtpaddress
                                    If ($Null -ne $ManagerEmail) { $Values.add($ManagerEmail.primarysmtpaddress) | Out-Null }
                                }
                                Try { Set-DistributionGroup -Identity $DistributionGroupName -ManagedBy $Values }
                                Catch { $_.Exception }
                                Write-Output "===>>> Managers add it to $DistributionGroupName"
                                Add-Content $Activitylog "===>>> Managers add it to $DistributionGroupName"
                            }
                            If ($Null -ne $MemberJoinRestriction) { 
                                Try {
                                    Set-DistributionGroup -Identity $DistributionGroupName -MemberJoinRestriction $MemberJoinRestriction -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
                                }
                                Catch { Write-Output "===>>> Unable to Set MemberJoinRestriction to ===>>> $DistributionGroupName" }
                                Write-Output "===>>> MemberJoinRestriction set to $MemberJoinRestriction for $DistributionGroupName"
                                Add-Content $Activitylog "===>>> MemberJoinRestriction set to $MemberJoinRestriction for $DistributionGroupName"
                            }
                            If ($Null -ne $MemberDepartRestriction) { 
                                Try { Set-DistributionGroup -Identity $DistributionGroupName -MemberDepartRestriction $MemberDepartRestriction -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null }
                                Catch { "===>>> Unable to Set MemberDepartRestriction to ===>>> $DistributionGroupName" }
                                "===>>> MemberDepartRestriction set to $MemberDepartRestriction for $DistributionGroupName"
                                Add-Content $Activitylog "===>>> MemberDepartRestriction set to $MemberDepartRestriction for $DistributionGroupName"
                            }
                            If ($Null -ne $SendModerationNotifications) { 
                                Try { Set-DistributionGroup -Identity $DistributionGroupName -SendModerationNotifications $SendModerationNotifications -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null }
                                Catch { Write-Output "===>>> Unable to Set SendModerationNotifications to ===>>> $DistributionGroupName" }
                                Write-Output "===>>> SendModerationNotifications set to $SendModerationNotifications for $DistributionGroupName"
                                Add-Content $Activitylog "===>>> SendModerationNotifications set to $SendModerationNotifications for $DistributionGroupName"
                            }
                            #Get boolean
                            If ($Null -ne $HiddenFromAddressListsEnabled) {
                                $HiddenFromAddressListsEnabled = Get-Boolean -Setting $Detail.HiddenFromAddressListsEnabled
                                Try { Set-DistributionGroup -Identity $DistributionGroupName -HiddenFromAddressListsEnabled $HiddenFromAddressListsEnabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null }
                                Catch { Write-Output "===>>> Unable to Set HiddenFromAddressListsEnabled to ===>>> $DistributionGroupName" }
                                Write-Output "===>>> HiddenFromAddressListsEnabled set to $HiddenFromAddressListsEnabled  for $DistributionGroupName"
                                Add-Content $Activitylog "===>>> HiddenFromAddressListsEnabled set to $HiddenFromAddressListsEnabled  for $DistributionGroupName"
                            }            
                            If ($Null -ne $ModerationEnabled) {
                                $ModerationEnabled = Get-Boolean -Setting $Detail.ModerationEnabled
                                Try { Set-DistributionGroup -Identity $DistributionGroupName -ModerationEnabled $ModerationEnabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null }
                                Catch { Write-Output "===>>> Unable to Set ModerationEnabled to ===>>> $DistributionGroupName" }
                                Write-Output "===>>> ModerationEnabled set to $ModerationEnabled for $DistributionGroupName"
                                Add-Content $Activitylog "===>>> ModerationEnabled set to $ModerationEnabled for $DistributionGroupName"
                            }
                            If ($Null -ne $RequireSenderAuthenticationEnabled) {
                                $RequireSenderAuthenticationEnabled = Get-Boolean -Setting $Detail.RequireSenderAuthenticationEnabled 
                                Try { Set-DistributionGroup -Identity $DistributionGroupName -RequireSenderAuthenticationEnabled $RequireSenderAuthenticationEnabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null }
                                Catch { Write-Output "===>>> Unable to Set RequireSenderAuthenticationEnabled to ===>>> $DistributionGroupName" }
                                Write-Output "===>>> RequireSenderAuthenticationEnabled set to $RequireSenderAuthenticationEnabled for $DistributionGroupName"
                                Add-Content $Activitylog "===>>> RequireSenderAuthenticationEnabled set to $RequireSenderAuthenticationEnabled for $DistributionGroupName"
                            }
                        }
                    }
                }
            }
            Else {
                Write-Output "===>>> $DistributionGroupName (!!!) has no details to import to exchange online"
                Add-Content $Activitylog  "===>>> $DistributionGroupName (!!!) has no details to import to exchange online"
            }
        }
        If ($Null -ne $AvoidSkip) {
            Write-Output "===>>> (!!!) $DistributionGroupName has been excluded from the batch due to errors"
            Add-Content $Activitylog "===>>> (!!!) $DistributionGroupName has been excluded from the batch due to errors reported on C:\ScriptFolder\MigrationTool\skipgroups.csv"
        }
    }
    Write-Output '===>>> taking the '_ ' from the distribution groups names in EOL'
    # Stage3
    #try to change names to original names
    ForEach ($DistributionGroup in $DistributionGroupNames) {
        $DistributionGroupName = $DistributionGroup.GroupName
        $AvoidSkip = $SkipGroupList | Select-String -Pattern "$DistributionGroupName"   
        If ($Null -eq $AvoidSkip) {
            $AlternativeGroupName = '_' + $DistributionGroupName
            $Evaluation = Get-Recipient $AlternativeGroupName -ErrorAction SilentlyContinue | Select-Object Name | Where-Object { $_.Name -match "$AlternativeGroupName" }
            If ($Evaluation.name.count -gt 0) {
                Try {
                    Set-DistributionGroup -Identity $AlternativeGroupName -Name $DistributionGroupName -DisplayName $DistributionGroupName -ErrorAction SilentlyContinue
                    Write-Output "===>>> Name changed from $AlternativeGroupName to ===>>> $DistributionGroupName"
                    Start-Sleep -Seconds 1
                }
                Catch { Write-Output "===>>> Unable to rename $AlternativeGroupName to ===>>> $DistributionGroupName, you will need to do this on the GUI" }
            }
        }
        If ($Null -ne $AvoidSkip) {
            Write-Output "===>>> (!!!) $DistributionGroupName has been excluded from the batch due to errors"
            Add-Content $Activitylog "===>>> (!!!) $DistributionGroupName has been excluded from the batch due to errors reported on C:\ScriptFolder\MigrationTool\skipgroups.csv"
        }
    }
    # move config files
    ForEach ($DistributionGroup in $DistributionGroupNames) {
        $DistributionGroupName = $DistributionGroup.GroupName
        #Move-Settings
        $DistributionGroupDetailsPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Details.csv"
        $DistributionGroupManagersPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Managers.log"
        $DistributionGroupMembersPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_Members.log"
        $DistributionGroupEmailAddressesPath = "C:\ScriptFolder\Raw\" + $DistributionGroupName + "_EmailAddresses.log"
        #Housekeep
        Move-Item $DistributionGroupDetailsPath -Destination 'C:\ScriptFolder\Completed' -Force -ea SilentlyContinue
        Move-Item $DistributionGroupManagersPath -Destination 'C:\ScriptFolder\Completed' -Force -ea SilentlyContinue
        Move-Item $DistributionGroupMembersPath -Destination 'C:\ScriptFolder\Completed' -Force -ea SilentlyContinue
        Move-Item $DistributionGroupEmailAddressesPath -Destination 'C:\ScriptFolder\Completed' -Force -ea SilentlyContinue
    
    }
    #Disconnect-ExchangeOnline -Confirm:$false
}
If ($Confirmation -eq 'n') {
    Disconnect-ExchangeOnline -Confirm:$false    
    Return
}
