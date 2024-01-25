#Persistent

SetTimer, CheckTime, 5000 ; Time in Miliseconds (1000 = 1s)

CheckTime:	; The timer's label
TheTime := A_Hour A_Min
If (TheTime = "1655")
{
Loop, 20
{
Send, {Left}
Sleep, 1000
}
exitapp
}
Return	; Remember to use "Return" at the end of label

Exit