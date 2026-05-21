#Requires AutoHotkey v2.0
#Include ../../Lib/_JXON.ahk


class Database {

    static _host := "https://api.easyrad.duckdns.org/"
    
    static __New() {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", this._host "autotriage/config", true)
        whr.Send()
        if whr.WaitForResponse(2) {
            if (whr.Status == 200) {
                result := whr.ResponseText
                data := Jxon_Load(&result)
                this.exams := data["exams"]
                this.labels := data["labels"]
                return
            } else {
                MsgBox("Failed to fetch configuration from server (status code " . whr.Status . ")`n`Exiting AutoTriage", "AutoTriage server error", 0x10)
            }
        } else {
            MsgBox("No response from server`n`Exiting AutoTriage", "AutoTriage server error", 0x10)
        }
        ExitApp
    }

    static GetExams(modality, searchStr := "") {
        exams := this.exams[modality]
		if StrLen(searchStr) {
            newExams := Map()
            for code, data in exams {
                if (InStr(data[2], searchStr) || InStr(code, searchStr)) {
                    newExams[code] := data
                }
            }
            return newExams
		}
        return exams
    }

    static GetBodyPartForCode(modality, code) =>
        this.exams[modality][code][1]

    static Tokenise(s) {
        static pattern := 'i)([^\w+-]|(?<!\bC)[+-]|\b(and|or|with|by|left|right|please|GP|CT|MRI?|US|ultrasound|scan|study|protocol|contrast)\b)'
        s := RegExReplace(StrLower(s), pattern, " ") ; Remove unwanted chars/words (case-insensitive)
        s := RegExReplace(Trim(s), "\s+", " ") ; Replace multiple spaces with a single space
        return Sort(s, "D U") ; Sort the string in ascending order with space as delimiter, removing duplicates
    }

    static GetExamMatch(modality, name) =>
        this.labels[modality].Get(this.Tokenise(name), false)

    static Post(path, body, async := false) {
        bodyJson := jxon_dump(body, 0)
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", this._host path, async)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(bodyJson)
        return whr
    }

}