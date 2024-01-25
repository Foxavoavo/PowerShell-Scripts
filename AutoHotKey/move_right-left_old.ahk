#Persistent

SetTimer, CheckTime, 5000 ; Time in Miliseconds (1000 = 1s)

CheckTime:	; The timer's label
TheTime := A_Hour A_Min
If (TheTime = "1552")
{
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}
Sleep 1000
Send {RIGHT Down}{RIGHT UP}

Sleep 60000 ;Sleep 12960000000

Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000
Send {LEFT Down}{LEFT UP}
Sleep 1000

exitapp
}
Return	; Remember to use "Return" at the end of label

Exit