#Include Common.ahk
#Include Keyboard_common.ahk

`:: toggleEmacs()

F13::
NumpadDiv:: {
  ;; Boss key
  ComradApp.WinActivate()
  PowerScribeApp.Activate()
  GroupActivate "RadiologyGroup"
  GroupActivate "RadiologyGroup"
}

;; ===== InterleView or PowerScribe =====

#HotIf WinActive("ahk_group RadiologyGroup")

^ESC::
^CapsLock:: {
  PowerscribeApp.ToggleFindingsMode()
}

NumpadDot::
NumpadDel:: {
  InteleviewerApp.ShowReport()
}

WheelLeft:: PowerScribeApp.Activate()
WheelRight:: InteleviewerApp.ActivateViewer()

^+t:: InteleviewerApp.PriorStudiesListView()

^+d:: {
  Acc := InteleviewerApp.GetLatestAccession()
  Output := InteleviewerApp.GenerateComparisonLine(Acc)
  EditPaste Output, PowerScribeApp.GetEditorCtrl(), PowerScribeApp.WinTitle
}


;; ===== InterleViewer =====

#HotIf InteleviewerApp.ViewerActive()

Numpad0::
NumpadIns:: Send "^{BackSpace}" ;; resets image

XButton2::
NumpadSub:: Send "{PgUp}"

XButton1::
NumpadAdd:: Send "{PgDn}"

XButton1 & WheelDown::
cycleIVWindow(ThisHotKey) {
  CurrentWindowName := InteleviewerApp.GetCurrentWindowLevel()
  Windows := [
    "WINDOW-LEVEL-RESET", ; Reset = F2
    "WINDOW-LEVEL-PRESET-3", ; Lung = F5
    "WINDOW-LEVEL-PRESET-4", ; Brain = F6
    "WINDOW-LEVEL-PRESET-5", ; Bone = F7
    "WINDOW-LEVEL-PRESET-6"  ; Head and neck = F8
  ]
  CurrentIndex := HasVal(Windows, CurrentWindowName) ; Returns 0 if not found
  CurrentIndex += 1

  switch Mod(Abs(CurrentIndex), Windows.Length) {
    case 0:
      Send "{F8}"
    case 1:
      Send "{F2}"
    case 2:
      Send "{F5}"
    case 3:
      Send "{F6}"
    case 4:
      Send "{F7}"
  }
}

XButton1 & WheelUp::
cycleIVMouseTool(ThisHotKey) {
  CurrentTool := InteleviewerApp.GetCurrentTool()
  Tools := [
    "ZOOM", ; Z
    "MAG-GLASS", ; G
    "STACK", ; S
    "DRAG-AND-SWAP", ; D
  ]
  CurrentIndex := HasVal(Tools, CurrentTool) ; Returns 0 if not found
  CurrentIndex += 1

  switch Mod(Abs(CurrentIndex), Tools.Length) {
    case 0:
      Send "z"
    case 1:
      Send "z"
    case 2:
      Send "g"
    case 3:
      Send "s"
    case 4:
      Send "d"
  }
}

Space:: TransientToolTip InteleviewerApp.GetCurrentTool()


^c:: {
  static toggle := 0
  A_Clipboard := ""
  if toggle = 0 {
    A_Clipboard := InteleviewerApp.CurrentPatient().Acc
    toggle := 1
  } else if toggle = 1 {
    A_Clipboard := InteleviewerApp.GetLatestAccession()
    toggle := 0
  }
  ClipWait 1
  TransientToolTip("Acc copied: " A_Clipboard)
}

;; Capture on-call template
^+c:: EmacsApp.CaptureByProtocol("C", InteleviewerApp.CurrentPatient().Acc, "", "")

;; Capture follow-ups
^+f:: EmacsApp.CaptureByProtocol("F", InteleviewerApp.CurrentPatient().Acc, "", "")

;; Capture a case to log
^+l:: EmacsApp.CaptureByProtocol("L", InteleviewerApp.CurrentPatient().Acc, "", "")


;; ===== InterleViewer Search =====

#HotIf WinActive(InteleviewerApp.SearchActive())

;; ===== Powerscribe =====
#HotIf WinActive(PowerscribeApp.WinTitle)

^i:: {
  currentAccession := InteleviewerApp.GetLatestAccession()
  Date := InteleviewerApp.GetStudyDate(currentAccession)
  TransientToolTip("Acc " currentAccession ": " Date)
  Send Date
}

^+i:: {
  InteleviewerApp.PriorStudiesListView()
}

XButton1:: PowerScribeApp.NextTabStop()
XButton2:: PowerScribeApp.PrevTabStop()

#c:: PowerScribeApp.ChangeConsultant()

#d:: PowerScribeApp.CheckRevisions()

;; ===== Comparing Revisions =====

#HotIf WinActive("Compare Report Revisions ahk_exe Nuance.PowerScribe360.exe")
/*
F1:: {
  visibleText := WinGetText
  RegExMatch(visibleText, "[A-Z]{3}[0-9]{4}", &NHI)
  Clipboard := NHI
}

F2:: {
  visibleText := WinGetText
  RegExMatch(visibleText, "[A-Z]{2}-[0-9]{8}-[A-Z]{2}", &AccessionNumber)
  Clipboard := AccessionNumber
  InteleviewerApp.ActivateSearch()
}
*/

Down:: {
  Control := PowerScribeApp._EditorFormClassNN("Window.8")
  ControlSend "{Down}", Control, PowerScribeApp.WinTitle
}

Up:: {
  Send "{Enter}"
  Send "{Up}"
  Sleep 500
}

/*
b:: ControlSend "{PgUp}", GetEditorFormClassNN("RichEdit20W")
j:: ControlSend "{Down}", GetEditorFormClassNN("RichEdit20W")
k:: ControlSend "{Up}", GetEditorFormClassNN("RichEdit20W")
*/


;; ===== COMRAD =====
#HotIf WinActive("COMRAD")

^s::!s

;; ===== Emacs =====
#HotIf EmacsApp.WinActive()

F1:: EmacsApp.OpenStudyByAccession()
!F1:: EmacsApp.OpenComradReport()

#HotIf