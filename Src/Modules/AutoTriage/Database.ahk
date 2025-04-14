#Requires AutoHotkey v2.0
#Include ../../Lib/SQLite/SQLite.ahk

; todo - refactor to use Class_SQLiteDB and prepared statements https://www.autohotkey.com/boards/viewtopic.php?f=83&t=95389

class Database {

    static _host := "https://cogent-script-128909-default-rtdb.firebaseio.com/"
    static _DbFilename := "Database/AutoTriage.sqlite3"
    
    static __New() {
        if !FileExist(Database._DbFilename) {
            if (A_IsCompiled) {
                DirCreate "Database"
                FileInstall "Database/AutoTriage.sqlite3", Database._DbFilename
            } else {
                throw Error("Database file not found", , Database._DbFilename)
            }
        }
    }

    __New(writeable) {
        this._db := SQLite(Database._DbFilename, writeable ? SQLITE_OPEN_READWRITE : SQLITE_OPEN_READONLY)
    }

    GetExams(modalityId, searchStr := "") {
        query := "SELECT code, examination.name, body_part.name AS body_part FROM examination JOIN body_part ON examination.body_part = body_part.id WHERE modality = " modalityId
		if StrLen(searchStr) {
			query .= " AND (examination.name LIKE '%" searchStr "%' OR code LIKE '%" searchStr "%')"
		}
		query .= " ORDER BY examination.body_part, examination.name"
        return this._db.Exec(query).rows
    }

    GetAliases(searchStr := "") {
        query := "SELECT label.name, code, examination.name AS canonical FROM label JOIN examination ON label.examination = examination.id"
        if StrLen(searchStr) {
			query .= " WHERE label.name LIKE '%" searchStr "%' OR examination.name LIKE '%" searchStr "%' OR code LIKE '%" searchStr "%'"
		}
		query .= " ORDER BY modality, body_part, examination.name"
        return this._db.Exec(query).rows
    }

    GetExamMatch(modalityId, name) {
        result := this._db.Exec("SELECT body_part.name AS body_part, code FROM label JOIN examination ON label.examination = examination.id JOIN body_part ON examination.body_part = body_part.id WHERE modality = " modalityId " AND label.name = '" name "'")
        if (!result.count) {
            result := this._db.Exec("SELECT body_part.name AS body_part, code FROM examination JOIN body_part ON examination.body_part = body_part.id WHERE modality = " modalityId " AND examination.name = '" name "'")
        }
        return result
    }

    RememberAlias(alias, canonical, modalityId) => this._db.Exec("INSERT INTO label (name, examination) VALUES ('" alias "', (SELECT id FROM examination WHERE name = '" canonical "' and modality = '" modalityId "'))")

    static LiveDatabaseCall(path, body, method := "POST") {
        bodyJson := jxon_dump(body, 0)
        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open(method, this._host path ".json", true) ; async
            whr.SetRequestHeader("Content-Type", "application/json")
            whr.Send(bodyJson)
            whr.WaitForResponse(3) ; timeout in 3 seconds
            ; MsgBox whr.ResponseText
        } catch Error as err {
            ErrorLog(err.Message ", Request body: '" bodyJson "'")
        }
    }

    static RememberAliasLive(user, alias, canonical, modalityId) => this.LiveDatabaseCall(
        "alias",
        Map("user",user,"alias",alias,"canonical",canonical,"modalityId",modalityId,"timestamp",Map(".sv","timestamp"))
    )

    ForgetAliases(aliases) {
        query := "DELETE FROM label WHERE name IN ("
        for alias in aliases {
            if A_Index > 1
				query .= ","
            query .= "'" alias "'"
        }
        query .= ")"
        this._db.Exec(query)
    }

    Close() => this._db.Close()

}