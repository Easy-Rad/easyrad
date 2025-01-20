#Requires AutoHotkey v2.0
#Include ../Lib/Config.ahk
#Include ../Lib/_JXON.ahk
#Include AutoTriage/Gui.ahk
#Include AutoTriage/Database.ahk
#Include AutoTriage/Request.ahk
#Include ../Common.ahk
; #Include AutoTriage/AutoTriageConfig.ahk

SetTitleMatchMode 1

MyForgetGui := ForgetGui()
MySelectStudyGui := SelectStudyGui()

^+f::
ForgetAliases(*)
{
	MyForgetGui.Launch()
}

#HotIf WinActive("COMRAD Medical Systems Ltd. ahk_class SunAwtFrame")
MButton::
Numpad0::
Numpad1::
Numpad2::
Numpad3::
Numpad4::
Numpad5::
{
	if ThisHotkey = "MButton" {
		MouseGetPos ,,&win
		if (win != WinGetID()) { ; cursor outside window
			Click "M"
			Exit
		}
	}
	SendEvent "!c" ; Close any AMR popup with Alt+C
	; Click on the left panel
	; DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
	; DllCall("Shcore.dll\GetDpiForMonitor", "ptr", DllCall("MonitorFromWindow", "ptr", WinGetID(), "int", 2, "ptr"), "int", 0, "uint*", &dpiX := 0, "uint*", &dpiY := 0)
	; ClickLocation := {x: 16, y: 114}
	; Click ClickLocation.x*dpiX//A_ScreenDPI, ClickLocation.y*dpiY//A_ScreenDPI
	; MouseMove x, y ; restore mouse position

	; OR

	; https://www.ibm.com/docs/en/sdk-java-technology/8?topic=applications-default-swing-key-bindings
	; Automatically moves focus if on triage
	; F8 Move to splitter bar
	; F6 Move between panes (need to do this twice to get out of the pdf viewer)
	;~ SendEvent "^{Up}{F8}{F6}{Tab}" ; Move from page to tab (escapes from pdf)
	; OR
	; SendEvent "{F6}{F8}{F6}{Tab}"
	; OR
	; if (ThisHotkey = "MButton") {
	; 	SendEvent "{Click}" ; Relies on the mouse position being over the middle pane or the pdf viewer to return focus to it and avoid a problem where the chat window is launched if the focus is higher than the main panes in the hierarchy, e.g. if Autonext has just been toggled and focus has not been returned to the panes
	; }

	
	SendEvent "{F6}{Tab}" ; Focus on tree
	RestoreClipboard := A_Clipboard
	A_Clipboard := ""
	SendEvent "^c" ; Copy
	if !ClipWait(0.1) { ; maybe the focus was orignally on the pdf viewer, try again
		SendEvent "{F6}{Tab}^c"
		if !ClipWait(0.1) {
			TrayTip "No request found"
			A_Clipboard := RestoreClipboard
			Exit
		}
	}
	r := Request(A_Clipboard)
	A_Clipboard := RestoreClipboard

	SendEvent "{Tab}" ; Tab to "Radiology Category"
	switch {
		case r.priority == "null": ; No "Clinical category" copied
			TrayTip "No clinical category",,2
		case InStr(r.priority, "Immediate", 0): ; STAT
			SendEvent "{Home}S"
		case InStr(r.priority, "24 hours", 0): ; 24 hours
			SendEvent "{Home}2"
		case InStr(r.priority, "4 hours", 0): ; 4 hours (this line has to be after the line matching 24 hours)
			SendEvent "{Home}4"
		case InStr(r.priority, "days", 0): ; 2(-3) days
			SendEvent "{Home}22"
		case InStr(r.priority, "2 weeks", 0): ; 2 weeks
			SendEvent "{Home}222"
		case InStr(r.priority, "4 weeks", 0): ; 4 weeks
			SendEvent "{Home}44"
		case InStr(r.priority, "6 weeks", 0): ; 6 weeks - never used
			SendEvent "{Home}6"
		default: ; Planned
			SendEvent "{Home}P"
	}
	
	SendEvent "{Tab 7}" ; Tab to "Rank"
	switch ThisHotkey {
		case "Numpad0": TriageRank := 0 ; skips rank entry
		case "Numpad1": TriageRank := 1
		case "Numpad2": TriageRank := 2
		case "Numpad3": TriageRank := 3
		case "Numpad4": TriageRank := 4
		case "Numpad5": TriageRank := 5
		default: TriageRank := Integer(Config.AutoTriage["DefaultTriageRank"]) ; 0 if disabled
	}
	if TriageRank {
		SendEvent "^a" ; Select all
		SendEvent TriageRank ; Set rank
	}

	SendEvent "{Tab 2}" ; Tab to "Body Part"
	if r.modalityId {
		db := Database(false)
		result := db.GetExamMatch(r.modalityId, r.exam)
		db.Close()
		if (result.count) {
			FillOutExam(result[1,"body_part"], result[1,"code"])
		} else if (Config.AutoTriage["UseStudySelector"]) {
			MySelectStudyGui.Launch(r.modalityId, r.exam)
		}
	}
}

FillOutExam(bodyPart, code) { 	; Fill out "Body Part" and "Code"
	switch bodyPart {
		case "CHEST/ABDO": SendEvent "{Home}CC"
		case "CHEST": SendEvent "{Home}C"
		default:
			firstLetter := SubStr(bodyPart, 1,  1)
			switch firstLetter {
				case "A","N","O","S": SendEvent SubStr(bodyPart, 1,  2)
				default: SendEvent firstLetter
			}
	}
	SendEvent "{Tab 7}" ;  Tab to table (need 7 rather than 6 if CONT_SENST is showing)
	SendEvent "{Home}{Tab}" code "{Tab}" ; Navigate to "Code" cell, enter code, tab out of cell
}

RButton::
NumpadEnter::
{
	MouseGetPos &x, &y, &win
	if (win = WinGetID()) {
		SendEvent "!s" ; "Save as Complete" with Alt+S
		;~ SendEvent "!k" ; "Skip" with Alt+K (for testing)
	} else if ThisHotkey = "RButton" {
		Click "R"
	}
}
