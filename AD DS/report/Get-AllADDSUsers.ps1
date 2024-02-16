# add AD objects to AD group
Import-Module activedirectory
#
get-aduser -filter * -SearchBase 'your distinguished name here' -Properties Department | select name, Department | Export-Csv C:\temp\liveusers.csv -NoTypeInformation
