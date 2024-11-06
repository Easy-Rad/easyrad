#Requires AutoHotkey v2.0
#Include <_JXON>
#Include "Gui.ahk"
#Include "Database.ahk"
#Include "Config.ahk"

SetTitleMatchMode 1

MyForgetGui := ForgetGui()

MySelectStudyGui := SelectStudyGui()

class Request {
	__New(strToParse) {
		Loop Parse StrReplace(strToParse, ", ", "�"), "�"
		{
			keyVal := StrSplit(A_LoopField, "=",,2)
			switch keyVal[1] {
				case "rf_exam_type":
					switch keyVal[2] {
						case "CT": this.modalityId := 1
						case "MR": this.modalityId := 2
						case "US": this.modalityId := 3
						case "SC": this.modalityId := 4
						default:
							this.modalityId := 0
							TrayTip 'Modality "' keyVal[2] '" not supported'
					}
				case "rf_reason":
					this.exam := keyVal[2]
					this.exam := StrReplace(this.exam, "LEFT")
					this.exam := StrReplace(this.exam, "RIGHT")
					this.exam := StrReplace(this.exam, "PLEASE") ; no special treatment for politeness
					this.exam := RegExReplace(this.exam, "\bAND\b", " ")
					this.exam := Trim(this.exam)
					this.exam := RegExReplace(this.exam, "\s+", " ")
				case "rf_original_priority":
					this.priority := keyVal[2]
			}
		}
		if !this.HasOwnProp("priority") || !this.HasOwnProp("exam") || !this.HasOwnProp("modalityId") {
			TrayTip "Click on the referral in the left pane and try again"
			Exit
		}
	}
	Print() {
		TrayTip "ModalityId: " this.modalityId "`nExam requested: " this.exam "`nPriority: " this.priority
	}
}

GetRequest(str) {
	if RegExMatch(str, "\[(.*)\]", &match) {
		return Request(match[1])
	} else {
		TrayTip "No match"
		Exit
	}
}

FillOutExam(bodyPart, code) {
	; Fill out body part with minimal keystrokes
	switch bodyPart {
		case "CHEST/ABDO": SendEvent "CHEST/"
		case "CHEST": SendEvent "{Home}C"
		default:
			firstLetter := SubStr(bodyPart, 1,  1)
			switch firstLetter {
				case "A","N","O","S": SendEvent SubStr(bodyPart, 1,  2)
				default: SendEvent firstLetter
			}

	}
	SendEvent "{Tab 7}{Home}{Tab}" code "+{Tab}" ;  Tab to "Code" cell (need 7 rather than 6 if CONT_SENST is showing), enter code, Shift-tab out of cell

}

; HOTKEYS

^+f::
ForgetAlias(*)
{
	MyForgetGui.Launch()
}


#HotIf WinActive("COMRAD Medical Systems Ltd. ahk_class SunAwtFrame")

;~ t:: ; test clipboard 
;~ {
	;~ A_Clipboard := ""
	;~ SendEvent "^c" ; Copy
	;~ if !ClipWait(0.25)
		;~ ToolTip "No request found"
	;~ else if RegExMatch(A_Clipboard, "\[.*\]")
		;~ ToolTip "Success!"
	;~ else
		;~ ToolTip "Failure, copied: " A_Clipboard
;~ }

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
		if (win != WinGetID()) {
			Click "M"
			Exit
		}
	}
	SendEvent "!c" ; Close any AMR popup with Alt+C

	; Click on the left panel

	MouseGetPos ,, &win
	; if click method used: MouseGetPos &x, &y, &win 

	if ThisHotkey = "MButton" && win != WinGetID() {
		Click "M"
		Exit
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
	if (ThisHotkey = "MButton") {
		SendEvent "{Click}" ; Relies on the mouse position being over the middle pane or the pdf viewer to return focus to it and avoid a problem where the chat window is launched if the focus is higher than the main panes in the hierarchy, e.g. if Autonext has just been toggled and focus has not been returned to the panes
	}
	SendEvent "{F6}{Tab}"
	RestoreClipboard := A_Clipboard
	A_Clipboard := ""
	SendEvent "^c" ; Copy
	if !ClipWait(0.1) { ; the focus may have orignally been on the pdf viewer
		SendEvent "{F6}{Tab}^c"
		if !ClipWait(0.1) {
			TrayTip "No request found"
			Exit
		}
	}

	r := GetRequest(A_Clipboard)
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
		case "Numpad0": TriageRank := 0
		case "Numpad1": TriageRank := 1
		case "Numpad2": TriageRank := 2
		case "Numpad3": TriageRank := 3
		case "Numpad4": TriageRank := 4
		case "Numpad5": TriageRank := 5
		default: TriageRank := Integer(Config.DefaultTriageRank) ; 0 if disabled
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
		} else if (Config.EnableStudySelector) {
			MySelectStudyGui.Launch(r.modalityId, r.exam)
		}
	}
	A_Clipboard := RestoreClipboard
}

RButton::
NumpadEnter::
{
	MouseGetPos &x, &y, &win
	if (win = WinGetID()) {
		SendEvent "!s" ; "Save as Complete" with Alt+S
		;~ SendEvent "!k" ; "Skip" with Alt+K - for testing
	} else if ThisHotkey = "RButton" {
		Click "R"
	}
}
