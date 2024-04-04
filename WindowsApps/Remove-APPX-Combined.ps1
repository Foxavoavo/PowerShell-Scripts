<#
combined APPX remover template, does works for one or more WindowsApps
#>
#Array
$apps = @{}
$apps.Add('MSTeams', '') ## your APPX package here
#Functions
Function Remove-AppxApp{
    Param($app,$PackageFullName)
    Try{remove-AppxPackage -package $PackageFullName -ea SilentlyContinue}
    Catch{}
    Start-Sleep -Seconds 5
    Try{remove-AppxPackage -package $PackageFullName -AllUsers -ea SilentlyContinue}
    Catch{}
    Start-Sleep -Seconds 5
    Try{Get-AppxPackage -AllUsers | where-object { $_.Name -like $app } | Remove-AppxPackage -AllUsers -ea SilentlyContinue}
    Catch{}
    Start-Sleep -Seconds 5
    Try{Get-AppxPackage -AllUsers | where-object { $_.Name -like $app } | Remove-AppxPackage -ea SilentlyContinue}
    Catch{}
}
function Remove-AppxProvisionedApp{
    Param($app,$ProPackageFullName)
    Try{Remove-AppxProvisionedPackage -online -packagename $ProPackageFullName -ea SilentlyContinue}
    Catch{}
    Start-Sleep -Seconds 5
    Try{Remove-AppxProvisionedPackage -Online -Packagename $ProPackageFullName -AllUsers -ea SilentlyContinue}
    Catch{}
    Start-Sleep -Seconds 5
    Try{Get-AppxProvisionedPackage -Online | where { $_.DisplayName -like $app } | Remove-AppxProvisionedPackage -AllUsers -ea SilentlyContinue}
    Catch{}
    Start-Sleep -Seconds 5
    Try{Get-AppxProvisionedPackage -Online | where { $_.DisplayName -like $app } | Remove-AppxProvisionedPackage  -ea SilentlyContinue}
    Catch{}
}
#loop
ForEach ($app in $apps.Keys) {
   $PackageFullName = (Get-AppxPackage -allusers | where { $_.Name -like $App }).PackageFullName
   start-sleep -s 1
   $ProPackageFullName = (Get-AppxProvisionedPackage -online | where { $_.Displayname -eq $App }).PackageName
   $packages = @($PackageFullName, $ProPackageFullName)                          
#executions   
    ForEach ($package in $packages) {
      If ($Null -ne $PackageFullName) {
         Remove-AppxApp -app $app -PackageFullName $PackageFullName 
      }
      If ($Null -ne $ProPackageFullName) {
         Remove-AppxProvisionedApp -app $app -ProPackageFullName $ProPackageFullName  
      }                                                                                                       
   }                   
}   
