;@Ahk2Exe-SetVersion 0.0.4
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "Modules\AutoTriage\AutoTriage.ahk"
#Include "Modules\AutoTriage\Tray.ahk"

A_TrayMenu.Delete
AutoTriageTrayMenu.AddToMenu(A_TrayMenu)
A_TrayMenu.Add
A_TrayMenu.AddStandard()