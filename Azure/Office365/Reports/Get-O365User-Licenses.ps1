
<# https://www.easy365manager.com/office-365-licenses-and-powershell/
     to grab a list of office 365 licenses in bulk.
     comes handy when yuo need to give a breakdown or feed a PowerBi report

     you need rights to ru nthe MSOLService PS module + rights in your Ms365 admin center.
     #>
Connect-MsolService
#Get-MsolAccountSku | ft SkuPartNumber,ActiveUnits,ConsumedUnits
#raw
Remove-Item 'C:\Scripts_Gus\Azure\RAW\o365Licenses_raw.csv' -Force -ErrorAction SilentlyContinue
add-content 'C:\Scripts_Gus\Azure\RAW\o365Licenses_raw.csv' 'DisplayName,UserPrincipalName,Licenses'
$raw = 'C:\Scripts_Gus\Azure\RAW\o365Licenses_raw.csv'
#results
Remove-Item 'C:\Scripts_Gus\Azure\Results\o365Licenses.csv' -Force -ErrorAction SilentlyContinue
add-content 'C:\Scripts_Gus\Azure\Results\o365Licenses.csv' 'DisplayName,UserPrincipalName,Licenses,FriendlyNames'
$result = 'C:\Scripts_Gus\Azure\Results\o365Licenses.csv'
#stats results
Remove-Item 'C:\Scripts_Gus\Azure\RAW\o365Licenses_STATS_RAW.csv' -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Scripts_Gus\Azure\Results\o365Licenses_STATS.csv' -Force -ErrorAction SilentlyContinue
add-content 'C:\Scripts_Gus\Azure\Results\o365Licenses_STATS.csv' 'SkuPartNumber,ActiveUnits,ConsumedUnits,FriendlyNames'
$resultstats = 'C:\Scripts_Gus\Azure\Results\o365Licenses_STATS.csv'
#loop
$bundle = Get-MsolAccountSku | Select-Object SkuPartNumber
$sku = $bundle.SkuPartNumber
Foreach ($skupartnumber in $sku) {
    $alletails = Get-MsolUser -All | Where-Object { ($_.licenses).AccountSkuId -match "$skupartnumber" } | Select-Object DisplayName, UserPrincipalName, Licenses | Sort-Object -ErrorAction silentlycontinue
    Foreach ($user in $alletails) {
        $displayname = $user.DisplayName
        $userprincipalname = $user.UserPrincipalName
        $license = $skupartnumber
        Start-Sleep -s 1
        "====>>> 1st stage =========>>> adding $displayname to list for $skupartnumber"
        add-content $raw "$displayname,$userprincipalname,$license"
    }
}
#stats
Get-MsolAccountSku | Select-Object SkuPartNumber, ActiveUnits, ConsumedUnits | export-csv 'C:\Scripts_Gus\Azure\RAW\o365Licenses_STATS_RAW.csv' -NoTypeInformation
#parsing cards
$in_ls_raw = Import-Csv 'C:\Scripts_Gus\Azure\RAW\o365Licenses_STATS_RAW.csv'
Foreach ($skupartn in $in_ls_raw) {
    $friendlycatch = $skupartn.SkuPartNumber 
    $ActiveUnits = $skupartn.ActiveUnits
    $ConsumedUnits = $skupartn.ConsumedUnits
                                          
    #friendlyname checker
    $VISIOCLIENT = $friendlycatch | Select-String -Pattern 'VISIOCLIENT' -ErrorAction SilentlyContinue
    If ($Null -ne $VISIOCLIENT) { $VISIOCLIENT = "VISIO Online Plan 2" }
    $STREAM = $friendlycatch | Select-String -Pattern 'STREAM' -ErrorAction SilentlyContinue
    If ($Null -ne $STREAM) { $STREAM = "Microsoft Stream" }
    $EMSPREMIUM = $friendlycatch | Select-String -Pattern 'EMSPREMIUM' -ErrorAction SilentlyContinue
    If ($Null -ne $EMSPREMIUM) { $EMSPREMIUM = "ENTERPRISE MOBILITY + SECURITY E5" }
    $ENTERPRISEPREMIUM = $friendlycatch | Select-String -Pattern 'ENTERPRISEPREMIUM' -ErrorAction SilentlyContinue
    If ($Null -ne $ENTERPRISEPREMIUM) { $ENTERPRISEPREMIUM = "OFFICE 365 ENTERPRISE E5" }
    $FLOW_PER_USER = $friendlycatch | Select-String -Pattern 'FLOW_PER_USER' -ErrorAction SilentlyContinue
    If ($Null -ne $FLOW_PER_USER) { $FLOW_PER_USER = "Power Automate per user plan" }
    $WINDOWS_STORE = $friendlycatch | Select-String -Pattern 'WINDOWS_STORE' -ErrorAction SilentlyContinue
    If ($Null -ne $WINDOWS_STORE) { $WINDOWS_STORE = "Windows Store Service" }
    $M365_E5_SUITE_COMPONENTS = $friendlycatch | Select-String -Pattern 'M365_E5_SUITE_COMPONENTS' -ErrorAction SilentlyContinue
    If ($Null -ne $M365_E5_SUITE_COMPONENTS) { $M365_E5_SUITE_COMPONENTS = "Microsoft 365 E5 Suite features" }
    $FLOW_FREE = $friendlycatch | Select-String -Pattern 'FLOW_FREE' -ErrorAction SilentlyContinue
    If ($Null -ne $FLOW_FREE) { $FLOW_FREE = "Microsoft Power Automate Free" }
    $POWERAPPS_VIRAL = $friendlycatch | Select-String -Pattern 'POWERAPPS_VIRAL' -ErrorAction SilentlyContinue
    If ($Null -ne $POWERAPPS_VIRAL) { $POWERAPPS_VIRAL = "Microsoft PowerApps Plan 2 Trial" }
    $CDS_FILE_CAPACITY = $friendlycatch | Select-String -Pattern 'CDS_FILE_CAPACITY' -ErrorAction SilentlyContinue
    If ($Null -ne $CDS_FILE_CAPACITY) { $CDS_FILE_CAPACITY = "Microsoft Dataverse storage capacity" }
    $DYN365_ENTERPRISE_CUSTOMER_SERVICE = $friendlycatch | Select-String -Pattern 'DYN365_ENTERPRISE_CUSTOMER_SERVICE' -ErrorAction SilentlyContinue
    If ($Null -ne $DYN365_ENTERPRISE_CUSTOMER_SERVICE) { $DYN365_ENTERPRISE_CUSTOMER_SERVICE = "Dynamics 365 for Customer Service Enterprise Edition" }
    $POWER_BI_STANDARD = $friendlycatch | Select-String -Pattern 'POWER_BI_STANDARD' -ErrorAction SilentlyContinue
    If ($Null -ne $POWER_BI_STANDARD) { $POWER_BI_STANDARD = "Power BI (free)" }
    $WIN_DEF_ATP = $friendlycatch | Select-String -Pattern 'WIN_DEF_ATP' -ErrorAction SilentlyContinue
    If ($Null -ne $WIN_DEF_ATP) { $WIN_DEF_ATP = "Microsoft Defender Advanced Threat Protection" }
    $SPE_E3 = $friendlycatch | Select-String -Pattern 'SPE_E3' -ErrorAction SilentlyContinue
    If ($Null -ne $SPE_E3) { $SPE_E3 = "Microsoft 365 E3" }
    $PROJECTPROFESSIONAL = $friendlycatch | Select-String -Pattern 'PROJECTPROFESSIONAL' -ErrorAction SilentlyContinue
    If ($Null -ne $PROJECTPROFESSIONAL) { $PROJECTPROFESSIONAL = "Project Online Professional" }
    $EXCHANGEENTERPRISE = $friendlycatch | Select-String -Pattern 'EXCHANGEENTERPRISE' -ErrorAction SilentlyContinue
    If ($Null -ne $EXCHANGEENTERPRISE) { $EXCHANGEENTERPRISE = "PExchange Online (Plan 2)" }
    $CDS_DB_CAPACITY = $friendlycatch | Select-String -Pattern 'CDS_DB_CAPACITY' -ErrorAction SilentlyContinue
    If ($Null -ne $CDS_DB_CAPACITY) { $CDS_DB_CAPACITY = "Dataverse for Apps Database Capacity" }
    $CDS_LOG_CAPACITY = $friendlycatch | Select-String -Pattern 'CDS_LOG_CAPACITY' -ErrorAction SilentlyContinue
    If ($Null -ne $CDS_LOG_CAPACITY) { $CDS_LOG_CAPACITY = "Dataverse for Apps Log Capacity" }
    #array                
    $friendlyname = @($VISIOCLIENT, $STREAM, $EMSPREMIUM, $ENTERPRISEPREMIUM, $FLOW_PER_USER,
        $FLOW_PER_USER, $WINDOWS_STORE, $M365_E5_SUITE_COMPONENTS, $FLOW_FREE,                    
        $POWERAPPS_VIRAL, $CDS_FILE_CAPACITY, $DYN365_ENTERPRISE_CUSTOMER_SERVICE,
        $POWER_BI_STANDARD, $WIN_DEF_ATP, $SPE_E3, $PROJECTPROFESSIONAL, $EXCHANGEENTERPRISE
        $CDS_DB_CAPACITY, $CDS_LOG_CAPACITY)
    Start-Sleep -s 1
    "====>>> 2nd stage =========>>> adding $friendlyname to list for $friendlycatch"
    add-content $resultstats "$friendlycatch,$ActiveUnits,$ConsumedUnits,$friendlyname"
}
#Adding FriendlyNames to Linceses result
$in_raw = Import-Csv 'C:\Scripts_Gus\Azure\RAW\o365Licenses_raw.csv'
Foreach ($frinedly in $in_raw) {
    $DisplayName = $frinedly.DisplayName 
    $UserPrincipalName = $frinedly.UserPrincipalName
    $friendlycatch = $frinedly.Licenses
    #friendlyname checker
    $VISIOCLIENT = $friendlycatch | Select-String -Pattern 'VISIOCLIENT' -ErrorAction SilentlyContinue
    If ($Null -ne $VISIOCLIENT) { $VISIOCLIENT = "VISIO Online Plan 2" }
    $STREAM = $friendlycatch | Select-String -Pattern 'STREAM' -ErrorAction SilentlyContinue
    If ($Null -ne $STREAM) { $STREAM = "Microsoft Stream" }
    $EMSPREMIUM = $friendlycatch | Select-String -Pattern 'EMSPREMIUM' -ErrorAction SilentlyContinue
    If ($Null -ne $EMSPREMIUM) { $EMSPREMIUM = "ENTERPRISE MOBILITY + SECURITY E5" }
    $ENTERPRISEPREMIUM = $friendlycatch | Select-String -Pattern 'ENTERPRISEPREMIUM' -ErrorAction SilentlyContinue
    If ($Null -ne $ENTERPRISEPREMIUM) { $ENTERPRISEPREMIUM = "OFFICE 365 ENTERPRISE E5" }
    $FLOW_PER_USER = $friendlycatch | Select-String -Pattern 'FLOW_PER_USER' -ErrorAction SilentlyContinue
    If ($Null -ne $FLOW_PER_USER) { $FLOW_PER_USER = "Power Automate per user plan" }
    $WINDOWS_STORE = $friendlycatch | Select-String -Pattern 'WINDOWS_STORE' -ErrorAction SilentlyContinue
    If ($Null -ne $WINDOWS_STORE) { $WINDOWS_STORE = "Windows Store Service" }
    $M365_E5_SUITE_COMPONENTS = $friendlycatch | Select-String -Pattern 'M365_E5_SUITE_COMPONENTS' -ErrorAction SilentlyContinue
    If ($Null -ne $M365_E5_SUITE_COMPONENTS) { $M365_E5_SUITE_COMPONENTS = "Microsoft 365 E5 Suite features" }
    $FLOW_FREE = $friendlycatch | Select-String -Pattern 'FLOW_FREE' -ErrorAction SilentlyContinue
    If ($Null -ne $FLOW_FREE) { $FLOW_FREE = "Microsoft Power Automate Free" }
    $POWERAPPS_VIRAL = $friendlycatch | Select-String -Pattern 'POWERAPPS_VIRAL' -ErrorAction SilentlyContinue
    If ($Null -ne $POWERAPPS_VIRAL) { $POWERAPPS_VIRAL = "Microsoft PowerApps Plan 2 Trial" }
    $CDS_FILE_CAPACITY = $friendlycatch | Select-String -Pattern 'CDS_FILE_CAPACITY' -ErrorAction SilentlyContinue
    If ($Null -ne $CDS_FILE_CAPACITY) { $CDS_FILE_CAPACITY = "Microsoft Dataverse storage capacity" }
    $DYN365_ENTERPRISE_CUSTOMER_SERVICE = $friendlycatch | Select-String -Pattern 'DYN365_ENTERPRISE_CUSTOMER_SERVICE' -ErrorAction SilentlyContinue
    If ($Null -ne $DYN365_ENTERPRISE_CUSTOMER_SERVICE) { $DYN365_ENTERPRISE_CUSTOMER_SERVICE = "Dynamics 365 for Customer Service Enterprise Edition" }
    $POWER_BI_STANDARD = $friendlycatch | Select-String -Pattern 'POWER_BI_STANDARD' -ErrorAction SilentlyContinue
    If ($Null -ne $POWER_BI_STANDARD) { $POWER_BI_STANDARD = "Power BI (free)" }
    $WIN_DEF_ATP = $friendlycatch | Select-String -Pattern 'WIN_DEF_ATP' -ErrorAction SilentlyContinue
    If ($Null -ne $WIN_DEF_ATP) { $WIN_DEF_ATP = "Microsoft Defender Advanced Threat Protection" }
    $SPE_E3 = $friendlycatch | Select-String -Pattern 'SPE_E3' -ErrorAction SilentlyContinue
    If ($Null -ne $SPE_E3) { $SPE_E3 = "Microsoft 365 E3" }
    $PROJECTPROFESSIONAL = $friendlycatch | Select-String -Pattern 'PROJECTPROFESSIONAL' -ErrorAction SilentlyContinue
    If ($Null -ne $PROJECTPROFESSIONAL) { $PROJECTPROFESSIONAL = "Project Online Professional" }
    $EXCHANGEENTERPRISE = $friendlycatch | Select-String -Pattern 'EXCHANGEENTERPRISE' -ErrorAction SilentlyContinue
    If ($Null -ne $EXCHANGEENTERPRISE) { $EXCHANGEENTERPRISE = "PExchange Online (Plan 2)" }
    $CDS_DB_CAPACITY = $friendlycatch | Select-String -Pattern 'CDS_DB_CAPACITY' -ErrorAction SilentlyContinue
    If ($Null -ne $CDS_DB_CAPACITY) { $CDS_DB_CAPACITY = "Dataverse for Apps Database Capacity" }
    $CDS_LOG_CAPACITY = $friendlycatch | Select-String -Pattern 'CDS_LOG_CAPACITY ' -ErrorAction SilentlyContinue
    If ($Null -ne $CDS_LOG_CAPACITY) { $CDS_LOG_CAPACITY = "Dataverse for Apps Log Capacity" }
    #array                
    $friendlyname = @($VISIOCLIENT, $STREAM, $EMSPREMIUM, $ENTERPRISEPREMIUM, $FLOW_PER_USER,
        $FLOW_PER_USER, $WINDOWS_STORE, $M365_E5_SUITE_COMPONENTS, $FLOW_FREE,                    
        $POWERAPPS_VIRAL, $CDS_FILE_CAPACITY, $DYN365_ENTERPRISE_CUSTOMER_SERVICE,
        $POWER_BI_STANDARD, $WIN_DEF_ATP, $SPE_E3, $PROJECTPROFESSIONAL, $EXCHANGEENTERPRISE
        $CDS_DB_CAPACITY, $CDS_LOG_CAPACITY)
    Start-Sleep -s 1
    "===>>> 3rd Stage ===>>> adding $friendlyname to list for $friendlycatch"
    Add-Content $result "$DisplayName,$UserPrincipalName,$friendlycatch,$friendlyname"
                                  
}
#left overs out
Remove-Item 'C:\Scripts_Gus\Azure\RAW\o365Licenses_STATS_RAW.csv' -Force -ErrorAction SilentlyContinue
Remove-Item 'C:\Scripts_Gus\Azure\RAW\o365Licenses_raw.csv' -Force -ErrorAction SilentlyContinue
"All completed"
