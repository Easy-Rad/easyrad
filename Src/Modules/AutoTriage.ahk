#Requires AutoHotkey v2.0
#Include ../Lib/Config.ahk
#Include AutoTriage/Gui.ahk
#Include AutoTriage/Database.ahk
#Include AutoTriage/Request.ahk
#Include AutoTriage/Response.ahk
#Include ../Common.ahk
#Include ../Lib/_JXON.ahk

SetTitleMatchMode 1

; MyForgetGui := ForgetGui()
MySelectStudyGui := SelectStudyGui()

; ^+f::
; ForgetAliases(*)
; {
; 	MyForgetGui.Launch()
; }

#HotIf WinActive("COMRAD Medical Systems Ltd. ahk_class SunAwtFrame")
MButton::
Numpad0::
Numpad1::
Numpad2::
Numpad3::
Numpad4::
Numpad5::
^MButton::
^Numpad0::
^Numpad1::
^Numpad2::
^Numpad3::
^Numpad4::
^Numpad5::
{
	if ThisHotkey = "MButton" or ThisHotkey = "^MButton" {
		MouseGetPos ,,&win
		if (win != WinGetID()) { ; cursor outside window
			Click "M"
			Exit
		}
	}
	if !ComradApp.getUser(&user) {
		TrayTip("No user found",,0x13)
		Exit
	}
	SendEvent "!c" ; Close any AMR popup with Alt+C
	SendEvent "{F6}{Tab}" ; Focus on tree
	RestoreClipboard := A_Clipboard
	A_Clipboard := ""
	SendEvent "^c" ; Copy
	if !ClipWait(0.1) { ; maybe the focus was orignally on the pdf viewer, try again
		SendEvent "{F6}{Tab}^c"
		if !ClipWait(0.1) {
			TrayTip("No request found",,0x13)
			A_Clipboard := RestoreClipboard
			Exit
		}
	}
	r := Request(A_Clipboard)
	A_Clipboard := RestoreClipboard

	if r.serial {
		whr := Database.Post("autotriage", Map(
				"user", user,
				"version", CodeVersion,
				"referral", r.serial,
			), true)
	}

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
		case "Numpad0", "^Numpad0": TriageRank := 0 ; skips rank entry
		case "Numpad1", "^Numpad1": TriageRank := 1
		case "Numpad2", "^Numpad2": TriageRank := 2
		case "Numpad3", "^Numpad3": TriageRank := 3
		case "Numpad4", "^Numpad4": TriageRank := 4
		case "Numpad5", "^Numpad5": TriageRank := 5
		default: TriageRank := Integer(Config.AutoTriage["DefaultTriageRank"]) ; 0 if disabled
	}
	if TriageRank {
		SendEvent "^a" ; Select all
		SendEvent TriageRank ; Set rank
	}

	SendEvent "{Tab 2}" ; Tab to "Body Part"
	manualStudySelect := SubStr(ThisHotkey, 1, 1) == "^"
	try {
		whr.WaitForResponse()
		result := whr.ResponseText
		data := Jxon_Load(&result)
	} catch Error as e {
		TrayTip("Falling back to local", "Network autotriage failed", 0x13)
		if !manualStudySelect {
			code := Database.GetExamMatch(r.modality, r.exam)
			if code {
				FillOutExam(Database.GetBodyPartForCode(r.modality, code), code, Array())
				Exit
			}
		}
		if manualStudySelect || Config.AutoTriage["UseStudySelector"] {
			MySelectStudyGui.Launch(user, r.modality, r.exam)
		}
	} else if data.Has("error") {
		TrayTip(data["error"],"Autotriage error", 0x13)
	} else {
		r := Response(data)
		if r.result && !manualStudySelect {
			FillOutExam(r.result.body_part, r.result.code, Array())
		} else if manualStudySelect || Config.AutoTriage["UseStudySelector"] {
			MySelectStudyGui.Launch(user, r.request.modality, r.request.exam)
		}
	}
}

FillOutExam(bodyPart, code, extraCodes) { 	; Fill out "Body Part" and "Code"
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
	For extraCode in extraCodes {
		SendEvent "!a{Tab}" extraCode "{Tab}"
	}
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
