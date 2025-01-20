#Requires AutoHotkey v2.0

class Request {
	__New(copiedStr) {
        if !RegExMatch(copiedStr, "\[(.*)\]", &match) {
            TrayTip "No match"
            Exit
        }
		Loop Parse StrReplace(match[1], ", ", "�"), "�"
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
					this.exam := StrReplace(this.exam, "(GP)")
					this.exam := RegExReplace(this.exam, "\bAND\b", " ")
					this.exam := Trim(this.exam)
					this.exam := RegExReplace(this.exam, "\s+", " ")
				case "rf_original_priority":
					this.priority := keyVal[2]
			}
		}
        switch {
            case !this.HasOwnProp("priority"):
                TrayTip "Object missing 'rf_original_priority'"
                Exit
            case !this.HasOwnProp("exam"):
                TrayTip "Object missing 'rf_reason'"
                Exit
            case !this.HasOwnProp("modalityId"):
                TrayTip "Object missing 'rf_exam_type'"
                Exit
        }
	}

	toString() => "ModalityId: " this.modalityId "`nExam requested: " this.exam "`nPriority: " this.priority

}