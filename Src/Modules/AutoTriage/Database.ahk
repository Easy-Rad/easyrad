#Requires AutoHotkey v2.0
#Include ../../Lib/SQLite/SQLite.ahk

; todo - refactor to use Class_SQLiteDB and prepared statements https://www.autohotkey.com/boards/viewtopic.php?f=83&t=95389

class Database {

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