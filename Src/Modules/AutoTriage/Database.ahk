#Requires AutoHotkey v2.0
#Include ../../Lib/_JXON.ahk

class Database {

    static _host := "https://cogent-script-128909-default-rtdb.firebaseio.com/"
    static _timestamp := Map(".sv", "timestamp")

    static GetExams(modalityId, searchStr := "") {
        query := "SELECT code, examination.name, body_part.name AS body_part FROM examination JOIN body_part ON examination.body_part = body_part.id WHERE modality = " modalityId
		if StrLen(searchStr) {
			query .= " AND (examination.name LIKE '%" searchStr "%' OR code LIKE '%" searchStr "%')"
		}
		query .= " ORDER BY examination.body_part, examination.name"
        return []
        ; return this._db.Exec(query).rows
    }

    static GetAliases(searchStr := "") {
        query := "SELECT label.name, code, examination.name AS canonical FROM label JOIN examination ON label.examination = examination.id"
        if StrLen(searchStr) {
			query .= " WHERE label.name LIKE '%" searchStr "%' OR examination.name LIKE '%" searchStr "%' OR code LIKE '%" searchStr "%'"
		}
		query .= " ORDER BY modality, body_part, examination.name"
        return []
        ; return this._db.Exec(query).rows
    }

    static Tokenise(name) {
         ; todo remove stub
        return name
        ; return "aaa acute aorta c+ cta"
    }

    static GetExamMatch(modality, name) {
        result := this.ReadSync('label/' modality '/' this.Tokenise(name))
        if (result == "null") {
            return false
        }
        data := Jxon_Load(&result)
        return {bodyPart: data["bodyPart"], code: data["code"]}
    }

    static WriteAsync(path, body, push := false) {
        bodyJson := jxon_dump(body, 0)
        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open(push ? "POST" : "PUT", Database._host path ".json", true) ; async
            whr.SetRequestHeader("Content-Type", "application/json")
            whr.Send(bodyJson)
            whr.WaitForResponse(3) ; timeout in 3 seconds
            return whr.ResponseText
        } catch Error as err {
            ErrorLog(err.Message ", Request body: '" bodyJson "'")
        }
    }

    static ReadSync(path) {
        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open("GET", Database._host path ".json", false) ; sync
            whr.Send()
            return whr.ResponseText
        } catch Error as err {
            ErrorLog(err.Message)
        }
    }

    ; RememberAlias(alias, canonical, modalityId) => this._db.Exec("INSERT INTO label (name, examination) VALUES ('" alias "', (SELECT id FROM examination WHERE name = '" canonical "' and modality = '" modalityId "'))")
    static RememberAlias(user, modality, alias, code) => this.WriteAsync(
        "alias",
        Map("user",user,"modality",modality,"label",this.Tokenise(alias),"code",code,"timestamp",Database._timestamp),
        true
    )

    static ForgetAliases(aliases) {
        query := "DELETE FROM label WHERE name IN ("
        for alias in aliases {
            if A_Index > 1
				query .= ","
            query .= "'" alias "'"
        }
        query .= ")"
        ; this._db.Exec(query)
    }

}