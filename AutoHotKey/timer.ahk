@echo off

%programfiles%\AutoHotkey\AutoHotkey.exe "c:\something.ahk"



CheckTime:	; The timer's label
TheTime := A_Hour A_Min
If (TheTime = "2100" && !Ran)
{
	MsgBox % "!"	; For testing purpose
	Run, C:\Test.txt
	Ran := 1
}
Return	; Remember to use "Return" at the end of label