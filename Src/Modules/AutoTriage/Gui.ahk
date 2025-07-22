#Requires AutoHotkey v2.0
#Include Database.ahk
#Include ../AutoTriage.ahk
#Include ../../Lib/Comrad.ahk

class SelectStudyGui extends Gui {

    __New(){
        this.user := false
        this.modality := false
        super.__New(,"Select study to protocol")
        this.AddText("Section w100", "Requested study:")
        this.RequestedStudy := this.AddEdit("ys w300")
        this.RequestedStudy.Opt("ReadOnly")

        this.RememberChoice := this.AddCheckBox("xs", "Remember choice")

        this.AddText("Section xs w100", "Filter:")
        this.FilterText := this.AddEdit("ys w300")
        this.ListView := this.AddListView("xs w500 r20", ["Code", "Description"])
        this.ListView.OnEvent("DoubleClick", LV_DoubleClick)
        this.FilterText.OnEvent("Change", OnSearchChange)

        OnSearchChange(ctrlObj, *) {
            this.ListView.Opt("-Redraw")
            this.ListView.Delete()
            for code, data in Database.GetExams(this.modality, ctrlObj.Value) {
                this.ListView.Add(,code, data[2])
            }
            this.ListView.Opt("+Redraw")
        }
        LV_DoubleClick(LV, RowNumber)
        {
            if RowNumber { ; do not trigger on header row
                this.OnExamSelected(LV.GetText(RowNumber))
            }
        }
    }

    OnExamSelected(code) {
        this.Hide()
        if this.RememberChoice.Value {
            whr := Database.Post("autotriage/remember", Map(
                    "user", this.user,
                    "exam", this.RequestedStudy.Value,
                    "modality", this.modality,
                    "code", code,
                ), true)
        }
        FillOutExam(Database.GetBodyPartForCode(this.modality, code), code)
        if (this.RememberChoice.Value) {
            try {
                whr.WaitForResponse()
            } catch Error as e {
		        TrayTip("No response, unable to save choice", "Network autotriage unresponsive", 0x13)
            } else if whr.Status == 400 {
                result := whr.ResponseText
                data := Jxon_Load(&result)
                TrayTip(data["error"],"Autotriage error", 0x3)
            } else if whr.Status != 204 {
                TrayTip("Unable to save choice", "Network autotriage server error", 0x3)
            }
        }
	}

    Launch(user, modality, examRequested){
        this.user := user
        this.modality := modality
        this.RequestedStudy.Value := examRequested
        this.RememberChoice.Value := false
        this.FilterText.Value := ""
		this.ListView.Delete()
        for code, data in Database.GetExams(modality) {
            this.ListView.Add(,code, data[2])
        }
        this.Show()
        this.FilterText.Focus()
    }
}

; class ForgetGui extends Gui {
    
;     __New(){
;         super.__New(,"Forget aliases")
;         this.AddText("Section", "Filter:")
;         this.FilterText := this.AddEdit("ys")
;         this.FilterText.OnEvent("Change", OnSearchChange)
;         this.ListView := this.AddListView("xs w500 r20", ["Alias", "Code", "Description"])
;         this.ListView.OnEvent("ItemSelect", OnItemSelect)
;         this.ForgetBtn := this.AddButton("Default w120")
;         this.ForgetBtn.OnEvent("Click", OnForgetButtonClick)

;         OnItemSelect(ctrlObj, item, selected){
;             this.UpdateForgetButton(ctrlObj.GetCount("S"))
;         }

;         OnForgetButtonClick(ctrlObj, *) {
;             this.Hide()
;             aliases := Array()
;             RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
;             While RowNumber := this.ListView.GetNext(RowNumber) {  ; Resume the search at the row after that found by the previous iteration.
;                 aliases.Push(this.ListView.GetText(RowNumber))
;             }
;             Database.ForgetAliases(aliases)
;         }
    
;         OnSearchChange(ctrlObj, *) {
;             this.ListView.Opt("-Redraw")
;             this.ListView.Delete()
;             for alias in Database.GetAliases(ctrlObj.Value) {
;                 this.ListView.Add(, alias.name, alias.code, alias.canonical)
;             }
;             this.ListView.Opt("+Redraw")
;             this.UpdateForgetButton(0)
;         }    
    
;     }

;     UpdateForgetButton(count){
;         this.ForgetBtn.Text := "Forget " count " alias" (count = 1 ? "" : "es")
;         this.ForgetBtn.Enabled := count > 0
;     }

;     Launch(*){
;         this.FilterText.Value := ""
;         this.ListView.Opt("-Redraw")
;         this.ListView.Delete()
;         for alias in Database.GetAliases() {
;             this.ListView.Add(, alias.name, alias.code, alias.canonical)
;         }
;         this.ListView.ModifyCol()
;         this.ListView.Opt("+Redraw")
;         this.UpdateForgetButton(0)
;         this.Show()
;         this.FilterText.Focus()
;     }

; }