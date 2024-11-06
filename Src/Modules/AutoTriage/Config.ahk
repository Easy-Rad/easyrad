#Requires AutoHotkey v2.0

class Config {

    static __New() {
        DirCreate this.IniPath
    }

    static IniPath := A_AppData "\AutoTriage"
    static IniFilename := this.IniPath "\Settings.ini"

    static IniSettingsSectionName := "Settings"
    static IniKeySettingEnableStudySelector := "EnableStudySelector"
    static DefaultEnableStudySelector := 1

    static IniDefaultsSectionName := "Defaults"
    static IniKeyDefaultTriageRank := "TriageRank"
    static DefaultDefaultTriageRank := 3

    ; static ClickLocation := {x: 16, y: 114}

    static EnableStudySelector {
        get => IniRead(this.IniFilename, this.IniSettingsSectionName, this.IniKeySettingEnableStudySelector, this.DefaultEnableStudySelector)
        set => IniWrite(value, this.IniFilename, this.IniSettingsSectionName, this.IniKeySettingEnableStudySelector)
    }

    static DefaultTriageRank {
        get => IniRead(this.IniFilename, this.IniDefaultsSectionName, this.IniKeyDefaultTriageRank, this.DefaultDefaultTriageRank)
        set => IniWrite(value, this.IniFilename, this.IniDefaultsSectionName, this.IniKeyDefaultTriageRank)
    }

}