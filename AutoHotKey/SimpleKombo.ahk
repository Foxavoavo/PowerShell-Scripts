;Home::
#Persistent

SetTimer, CheckTime, 5000 ; Time in Miliseconds (1000 = 1s)

CheckTime:	; The timer's label
TheTime := A_Hour A_Min
If (TheTime = "1655")
{
Sleep, 1000
Send, {ctrl down}{s}{ctrl up}
Sleep, 1000
Send, {Alt down}{F4}{Alt up}
Sleep, 5000
Run C:\Kiosk\someapp.exe
}
Return