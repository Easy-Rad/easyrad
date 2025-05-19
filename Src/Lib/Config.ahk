#Requires AutoHotkey v2.0

class Config {

    static _IniPath := A_MyDocuments ; hangs if network unavailable
    ; static _IniPath := A_AppData "\EasyRad"
    static _IniFilename := this._IniPath "\EasyRad.ini"

    static Comrad := Config.Section("Comrad")
    
    static InteleViewer := Config.Section("InteleViewer")
    static InteleViewerSites := Map(
        "CDHB", "http://app-inteleradha-p.healthhub.health.nz",
        "PRG", "https://pacs.pacificradiology.com",
        "Reform", "https://pacs.reformradiology.co.nz",
        "Beyond", "https://pacs.beyondradiology.co.nz",
    )

    static AutoTriage := Config.Section("AutoTriage", Map(
        "UseStudySelector", 1,
        "DefaultTriageRank", 3,
    ))

    static __New() {
        DirCreate this._IniPath
        for site, defaultUrl in this.InteleViewerSites
            this.InteleViewer._defaults[site " URL"] := defaultUrl
    }

    class Section {
        __New(sectionName, defaults := Map()) {
            this._sectionName := sectionName
            this._defaults := defaults
            this._defaults.Default := ""
        }
        __Item[key] {
            get => IniRead(Config._IniFilename, this._sectionName, key, this._defaults[key])
            set => IniWrite(value, Config._IniFilename, this._sectionName, key)
        }
    }

}