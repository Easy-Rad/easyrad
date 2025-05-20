#Requires AutoHotkey v2.0
#Include Database.ahk
#Include ../AutoTriage.ahk
#Include ../../Lib/Comrad.ahk

class SelectStudyGui extends Gui {

    __New(){
        this.modality := false
        super.__New(,"Select study to protocol")
        this.AddText("Section w100", "Requested study:")
        this.RequestedStudy := this.AddEdit("ys w300")
        this.RequestedStudy.Opt("ReadOnly")

        ; this.RememberChoice := this.AddCheckBox("xs", "Remember alias")

        ; Tabs := this.AddTab3("Section xs", ["Search", "Choose"])
        ; Tabs.UseTab(1)
        this.AddText("Section xs w100", "Filter:")
        this.FilterText := this.AddEdit("ys w300")
        this.ListView := this.AddListView("xs w500 r20", ["Code", "Description"])
        ; Tabs.UseTab(2)
        ; this.TreeView := this.AddTreeView("w500 r24")
        this.ListView.OnEvent("DoubleClick", LV_DoubleClick)
        this.FilterText.OnEvent("Change", OnSearchChange)
        ; this.TreeView.OnEvent("DoubleClick", TV_DoubleClick)

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
        ; TV_DoubleClick(TV, ID)
        ; {
        ;     if TV.GetParent(ID) { ; do not trigger on top level items
        ;         this.OnExamSelected(TV.GetText(ID))
        ;     }
        ; }
    }

    OnExamSelected(code) {
        this.Hide()
        FillOutExam(this.modality, this.RequestedStudy.Value, code, false)
	}

    Launch(modality, examRequested){
        this.modality := modality
        this.RequestedStudy.Value := examRequested
        ; this.RememberChoice.Value := false
        this.FilterText.Value := ""
		this.ListView.Delete()
        ; currentBodyPart := ""
        for code, data in Database.GetExams(modality) {
            this.ListView.Add(,code, data[2])
            ; if data[1] != currentBodyPart {
            ;     currentBodyPart := data[1]
            ;     currentBodyPartBranchId := this.TreeView.Add(currentBodyPart)
            ; }
            ; this.TreeView.Add(data[2], currentBodyPartBranchId)
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