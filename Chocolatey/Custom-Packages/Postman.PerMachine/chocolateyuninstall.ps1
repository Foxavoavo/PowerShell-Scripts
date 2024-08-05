###################################################
$ApplicationName = $PackageName # <<<=== Your Application Name here
###################################################
# Functions
Function Remove-LocalPostman {
    param($UserList)
    ForEach ($User in $UserList) {
        $UserPath = $User.FullName
        $Username = $User.Name
        $PostmanUserPath = "$UserPath\AppData\Local\$PackageName\update.exe"
        #Evaluation
        If ((Test-Path $PostmanUserPath) -eq $True) {
            & $PostmanUserPath --uninstall -s
            Start-Sleep -Seconds 10
            Remove-Item "${env:SystemDrive}\Users\$Username\AppData\Local\Postman" -Recurse -Force 
        }
    }
}
$HousekeepUsers = Get-ChildItem "${env:SystemDrive}\users" | Select-Object FullName, Name
# Housekeep 
Remove-LocalPostman -UserList $HousekeepUsers
# Post   
Remove-Item "${env:SystemDrive}\$ApplicationName" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "${env:Public}\Desktop\$ApplicationName.lnk" -Recurse -Force -ErrorAction SilentlyContinue 
Remove-Item  "${env:AllUsersProfile}\Microsoft\Windows\Start Menu\Programs\$ApplicationName.lnk" -Recurse -Force -ErrorAction SilentlyContinue
