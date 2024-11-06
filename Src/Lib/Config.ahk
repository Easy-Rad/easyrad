#include Utils.ahk

class UserConfig {
    __New(FileName) {
        if not FileExist(FileName)
            FileAppend "", FileName, "UTF-16-RAW"

        this.FileName := FileName
        this.Comrad := Map()
        this.IV := Map("CDHB", Map(), "PRG", Map(), "Reform", Map(), "Beyond", Map())
        this.AutoTriage := Map()
        this.loadConfig()
    }

    loadConfig() {
        this.Comrad["Username"] := IniRead(this.FileName, "Comrad", "Username", "")
        this.Comrad["PW"] := IniRead(this.FileName, "Comrad", "Password", "")

        this.IV["CDHB"]["Url"] := IniRead(this.FileName, "Inteleviewer", "CDHB URL", "http://app-inteleradha-p.healthhub.health.nz")
        this.IV["CDHB"]["Username"] := IniRead(this.FileName, "Inteleviewer", "CDHB Username", "")
        this.IV["CDHB"]["PW"] := IniRead(this.FileName, "Inteleviewer", "CDHB Password", "")
        this.IV["PRG"]["Url"] := IniRead(this.FileName, "Inteleviewer", "PRG URL", "https://pacs.pacificradiology.com")
        this.IV["PRG"]["Username"] := IniRead(this.FileName, "Inteleviewer", "PRG Username", "")
        this.IV["PRG"]["PW"] := IniRead(this.FileName, "Inteleviewer", "PRG Password", "")
        this.IV["Reform"]["Url"] := IniRead(this.FileName, "Inteleviewer", "Reform URL", "https://pacs.reformradiology.co.nz")
        this.IV["Reform"]["Username"] := IniRead(this.FileName, "Inteleviewer", "Reform Username", "")
        this.IV["Reform"]["PW"] := IniRead(this.FileName, "Inteleviewer", "Reform Password", "")
        this.IV["Beyond"]["Url"] := IniRead(this.FileName, "Inteleviewer", "Beyond URL", "https://pacs.beyondradiology.co.nz")
        this.IV["Beyond"]["Username"] := IniRead(this.FileName, "Inteleviewer", "Beyond Username", "")
        this.IV["Beyond"]["PW"] := IniRead(this.FileName, "Inteleviewer", "Beyond Password", "")
    }

    saveConfig() {
        IniWrite(this.Comrad["Username"], this.FileName, "Comrad", "Username")
        IniWrite(this.Comrad["PW"], this.FileName, "Comrad", "Password")

        IniWrite(this.IV["CDHB"]["Url"], this.FileName, "Inteleviewer", "CDHB URL")
        IniWrite(this.IV["CDHB"]["Username"], this.FileName, "Inteleviewer", "CDHB Username")
        IniWrite(this.IV["CDHB"]["PW"], this.FileName, "Inteleviewer", "CDHB Password")

        IniWrite(this.IV["PRG"]["Url"], this.FileName, "Inteleviewer", "PRG URL")
        IniWrite(this.IV["PRG"]["Username"], this.FileName, "Inteleviewer", "PRG Username")
        IniWrite(this.IV["PRG"]["PW"], this.FileName, "Inteleviewer", "PRG Password")

        IniWrite(this.IV["Reform"]["Url"], this.FileName, "Inteleviewer", "Reform URL")
        IniWrite(this.IV["Reform"]["Username"], this.FileName, "Inteleviewer", "Reform Username")
        IniWrite(this.IV["Reform"]["PW"], this.FileName, "Inteleviewer", "Reform Password")

        IniWrite(this.IV["Beyond"]["Url"], this.FileName, "Inteleviewer", "Beyond URL")
        IniWrite(this.IV["Beyond"]["Username"], this.FileName, "Inteleviewer", "Beyond Username")
        IniWrite(this.IV["Beyond"]["PW"], this.FileName, "Inteleviewer", "Beyond Password")
    }
}