#Requires AutoHotkey v2.0
#Include ../../Lib/_JXON.ahk


ErrorLog(msg) {
	FileAppend A_Now ": " msg "`n", A_ScriptDir "\ErrorLog.txt"
}

class Database {

    static _host := "https://api.easyrad.duckdns.org/"
    static _timestamp := Map(".sv", "timestamp")
    static _LabelsFilename := "Database/labels.json"
    static _ExamsFilename := "Database/exams.json"
    
    static __New() {
        if !FileExist(this._ExamsFilename) || !FileExist(this._LabelsFilename) {
            if (A_IsCompiled) {
                DirCreate "Database"
                FileInstall "Database/exams.json", this._ExamsFilename
                FileInstall "Database/labels.json", this._LabelsFilename
            } else {
                throw Error("Database files not found:", , this._ExamsFilename "," this._LabelsFilename)
            }
        }
        _j := FileRead(this._ExamsFilename)
        this.exams := Jxon_Load(&_j)
        _j := FileRead(this._LabelsFilename)
        this.labels := Jxon_Load(&_j)
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

    static LogLaunchEvent(user) => this.Write("log/launch", Map(
            "user", user,
            "version", CodeVersion,
            "timestamp", this._timestamp,
        ), true)

    static LogTriageEvent(user, modality, request, code, found) {
        body := Map(
            "user", user,
            "modality", modality,
            "request", request,
            "code", code,
            "timestamp", this._timestamp,
            )
        if !found {
            body["tokenised"] := this.Tokenise(request)
        }
        return this.Write("log/triage", body, true)
    }

}