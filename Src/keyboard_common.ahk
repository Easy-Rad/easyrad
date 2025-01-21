#Include Common.ahk

;; ===== Global =====
F1:: opener.OpenHighlightedText()


;; ===== Comrad =====
#HotIf WinActive("COMRAD")

F2:: ConcertoWeb.OpenHighlightedPatientProfile()


;; ===== InterleView or PowerScribe =====
#HotIf WinActive("ahk_group RadiologyGroup")

ESC::
CapsLock:: PowerscribeApp.ToggleRecording()

;; next fields
Tab:: PowerScribeApp.NextTabStop()

;; prev fields
+Tab:: PowerScribeApp.PrevTabStop()


;; ===== InterleView Viewer Only =====
#HotIf InteleviewerApp.ViewerActive()

F1:: {
    Acc := InteleviewerApp.CurrentPatient().Acc
    NHI := InteleviewerApp.CurrentPatient().NHI

    if (A_Clipboard == Acc) {
        A_Clipboard := NHI
        TransientToolTip("NHI copied: " A_Clipboard)
    } else if (A_Clipboard == NHI) {
        A_Clipboard := Acc
        TransientToolTip("Acc copied: " A_Clipboard)
    } else {
        A_Clipboard := Acc
        TransientToolTip("Acc copied: " A_Clipboard)
    }
}


;; ===== Powerscribe Only =====
#HotIf WinActive(PowerScribeApp.WinTitle)

F1::
openImageAnywhere(ThisHotkey) {
    AccessionNumber := PowerScribeApp.GetAccessionNumber()
    opener.openStudy(AccessionNumber)
}

F2:: {
    ;; Toggle between copying NHI and Accession number
    Acc := PowerScribeApp.GetAccessionNumber()
    NHI := PowerScribeApp.GetNHI()

    if (A_Clipboard == Acc && NHI) {
        A_Clipboard := NHI
        TransientToolTip("NHI copied: " A_Clipboard)
    }
    else if (A_Clipboard == NHI && Acc) {
        A_Clipboard := Acc
        TransientToolTip("Acc copied: " A_Clipboard)
    }
    else {
        A_Clipboard := Acc
        TransientToolTip("Acc copied: " A_Clipboard)
    }
}

#HotIf