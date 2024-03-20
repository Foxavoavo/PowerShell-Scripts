#Remove Windows 11 APPX unwanted apps.
$Apps = @{}
$Apps.Add('Microsoft.WindowsStore', '')                 
$Apps.Add('Microsoft.XboxIdentityProvider', '')
$Apps.Add('Microsoft.ZuneMusic', '')
$Apps.Add('Microsoft.XboxGameCallableUI', '')   
$Apps.Add('Microsoft.MicrosoftEdgeDevToolsClient', '')
$Apps.Add('Microsoft.Windows.ParentalControls', '')
$Apps.Add('Microsoft.windowscommunicationsapps', '')        
$Apps.Add('Microsoft.WindowsAlarms', '')       
$Apps.Add('Microsoft.WebMediaExtensions', '')               
$Apps.Add('Microsoft.VP9VideoExtensions', '')    
$Apps.Add('Microsoft.ZuneVideo', '')              
$Apps.Add('Microsoft.YourPhone', '')                       
$Apps.Add('Microsoft.XboxSpeechToTextOverlay', '')          
$Apps.Add('Microsoft.XboxGamingOverlay', '')         
$Apps.Add('Microsoft.XboxGameOverlay', '')               
$Apps.Add('Microsoft.Xbox.TCUI', '')                 
$Apps.Add('Microsoft.WindowsTerminal', '')                  
$Apps.Add('Microsoft.WindowsSoundRecorder', '')             
$Apps.Add('Microsoft.WindowsMaps', '')            
$Apps.Add('Microsoft.WindowsFeedbackHub', '')  
$Apps.Add('Microsoft.WebpImageExtension', '')              
$Apps.Add('Microsoft.Todos', '')              
$Apps.Add('Microsoft.StorePurchaseApp', '')    
$Apps.Add('Microsoft.RawImageExtension', '')                
$Apps.Add('Microsoft.PowerAutomateDesktop', '')             
$Apps.Add('Microsoft.People', '')
$Apps.Add('Microsoft.MicrosoftSolitaireCollection', '')   
$Apps.Add('Microsoft.MicrosoftOfficeHub', '')    
$Apps.Add('Microsoft.HEVCVideoExtension', '')              
$Apps.Add('Microsoft.HEIFImageExtension', '')                 
$Apps.Add('Microsoft.GetHelp', '')                            
$Apps.Add('Microsoft.GamingApp', '')          
#Functions
Function Remove-AppxApp {
    Param($App, $PackageFullName)
    Try { remove-AppxPackage -package $PackageFullName -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next command' }
    Start-Sleep -Seconds 5
    Try { remove-AppxPackage -package $PackageFullName -AllUsers -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next command' }
    Start-Sleep -Seconds 5
    Try { Get-AppxPackage -AllUsers | where-object { $_.Name -like $App } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next command' }
    Start-Sleep -Seconds 5
    Try { Get-AppxPackage -AllUsers | where-object { $_.Name -like $App } | Remove-AppxPackage -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next windowsapp' }
}
Function Remove-AppxProvisionedApp {
    param($App, $ProPackageFullName)
    Try { Remove-AppxProvisionedPackage -Online -packagename $ProPackageFullName -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next command' }
    Start-Sleep -Seconds 5
    Try { Remove-AppxProvisionedPackage -Online -Packagename $ProPackageFullName -AllUsers -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next command' }
    Start-Sleep -Seconds 5
    Try { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Remove-AppxProvisionedPackage -AllUsers -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next command' }
    Start-Sleep -Seconds 5
    Try { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Remove-AppxProvisionedPackage  -ErrorAction SilentlyContinue }
    Catch { 'This command didnt work, running next windowsapp' }
}
#Loop Here
ForEach ($App in $Apps.Keys) {
    $PackageFullName = (Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $App }).PackageFullName
    start-sleep -s 1
    $ProPackageFullName = (Get-AppxProvisionedPackage -Online | Where-Object { $_.Displayname -eq $App }).PackageName
    $packages = @($PackageFullName, $ProPackageFullName)                          
    #Executions   
    ForEach ($Package in $Packages) {
        If ($Null -ne $PackageFullName) {
            Remove-AppxApp -App $App -PackageFullName $PackageFullName 
        }
        If ($Null -ne $ProPackageFullName) {
            Remove-AppxProvisionedApp -App $App -ProPackageFullName $ProPackageFullName  
        }                                                                                                       
    }                   
}   
