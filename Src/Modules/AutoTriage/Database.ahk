#Requires AutoHotkey v2.0
#Include ../../Lib/_JXON.ahk


ErrorLog(msg) {
	FileAppend A_Now ": " msg "`n", A_ScriptDir "\ErrorLog.txt"
}

class Database {

    static _host := "https://cogent-script-128909-default-rtdb.firebaseio.com/"
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

    ; static p :="Modules/AutoTriage/labels.json"
    ; static _labels := Jxon_Load(&LABELS_JSON)

    static GetExams(modality, searchStr := "") {
        exams := this.exams[modality]
        ; query := "SELECT code, examination.name, body_part.name AS body_part FROM examination JOIN body_part ON examination.body_part = body_part.id WHERE modality = " modalityId
		if StrLen(searchStr) {
            newExams := Map()
            for code, data in exams {
                if (InStr(data[2], searchStr) || InStr(code, searchStr)) {
                    newExams[code] := data
                }
            }
            return newExams
			; query .= " AND (examination.name LIKE '%" searchStr "%' OR code LIKE '%" searchStr "%')"
		}
		; query .= " ORDER BY examination.body_part, examination.name"
        return exams
        ; return this._db.Exec(query).rows
    }

    static GetBodyPartForCode(modality, code) =>
        this.exams[modality][code][1]
        ; result := this.ReadSync('examination/' modality '/' code)
        ; if (result == "null") {
        ;     return false
        ; }
        ; data := Jxon_Load(&result)
        ; return data["bodyPart"]

    ; static GetAliases(searchStr := "") {
    ;     query := "SELECT label.name, code, examination.name AS canonical FROM label JOIN examination ON label.examination = examination.id"
    ;     if StrLen(searchStr) {
	; 		query .= " WHERE label.name LIKE '%" searchStr "%' OR examination.name LIKE '%" searchStr "%' OR code LIKE '%" searchStr "%'"
	; 	}
	; 	query .= " ORDER BY modality, body_part, examination.name"
    ;     return []
    ;     ; return this._db.Exec(query).rows
    ; }

    static Tokenise(s) {
        static pattern := 'i)([^\w+-]|(?<!\bC)[+-]|\b(and|or|with|by|left|right|please|GP|CT|MRI?|US|ultrasound|scan|study|protocol|contrast)\b)'
        s := RegExReplace(StrLower(s), pattern, " ") ; Remove unwanted chars/words (case-insensitive)
        s := RegExReplace(Trim(s), "\s+", " ") ; Replace multiple spaces with a single space
        return Sort(s, "D U") ; Sort the string in ascending order with space as delimiter, removing duplicates
    }

    static GetExamMatch(modality, name) =>
        this.labels[modality].Get(this.Tokenise(name), false)
        ; result := this.ReadSync('label/' modality '/' this.Tokenise(name))
        ; if (result == "null") {
        ;     return false
        ; }
        ; data := Jxon_Load(&result)
        ; return {bodyPart: data["bodyPart"], code: data["code"]}
    

    static Write(path, body, push := false, async := false) {
        bodyJson := jxon_dump(body, 0)
        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open(push ? "POST" : "PUT", this._host path ".json", async)
            whr.SetRequestHeader("Content-Type", "application/json")
            whr.Send(bodyJson)
            return whr
            ; if async {
            ;     whr.WaitForResponse(2) ; timeout in 2 seconds
            ; }
            ; return whr.ResponseText
        } catch Error as err {
            ErrorLog(err.Message ", Request body: '" bodyJson "'")
        }
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

    ; static ReadSync(path) {
    ;     try {
    ;         whr := ComObject("WinHttp.WinHttpRequest.5.1")
    ;         whr.Open("GET", Database._host path ".json", false) ; sync
    ;         whr.Send()
    ;         return whr.ResponseText
    ;     } catch Error as err {
    ;         ErrorLog(err.Message)
    ;     }
    ; }

    ; RememberAlias(alias, canonical, modalityId) => this._db.Exec("INSERT INTO label (name, examination) VALUES ('" alias "', (SELECT id FROM examination WHERE name = '" canonical "' and modality = '" modalityId "'))")
    ; static RememberAlias(user, modality, alias, code) => this.Write(
    ;     "alias",
    ;     Map("user",user,"modality",modality,"label",this.Tokenise(alias),"code",code,"timestamp",this._timestamp),
    ;     true
    ; )

    ; static ForgetAliases(aliases) {
    ;     query := "DELETE FROM label WHERE name IN ("
    ;     for alias in aliases {
    ;         if A_Index > 1
	; 			query .= ","
    ;         query .= "'" alias "'"
    ;     }
    ;     query .= ")"
    ;     ; this._db.Exec(query)
    ; }

}