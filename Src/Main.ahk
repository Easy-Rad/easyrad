#Include Common.ahk
#Include Modules\Emacs.ahk
#Include Modules\Keyboard.ahk
#Include Modules\Dictation.ahk
#Include Modules\StudyOpener.ahk
#Include keyboard_custom.ahk

Config := UserConfig(A_MyDocuments . "\EasyRad.ini")
inteleviewer := InteleviewerApp()
opener := StudyOpener(config)
radwhere := RadWhereCOM()
powermic := Dictaphone(radwhere)

class MainGui extends Gui {

    __New() {
        ;; Set the icon for the tray and task bar
        TraySetIcon("..\Static\icon.ico")

        super.__new(, "EasyRad", this) ;; set the event sink to this object

        ;; Override the close button event, to minimize window
        this.OnEvent("Close", "Close")

        tab := this.Add("Tab3", "W500 vTab", ["Dashboard", "Shortcuts", "Settings"])

        tab.UseTab(1)
        this.Add("GroupBox", "Section w475 h110", "Quick Launch")
        startAllBtn := this.Add("Button", "w300 h67 xp+10 yp+25", "Start All")
        startAllBtn.SetFont("s12 bold")
        startAllBtn.OnEvent("Click", "StartAllBtn_Click")
        startIVBtn := this.Add("Button", "w150 h30 yp vstartIVBtn", "Start Inteleviewer")
        startIVBtn.SetFont("s10")
        startIVBtn.OnEvent("Click", this.Launch_IV_Btn_Click)
        startComradBtn := this.Add("Button", "w150 h30 xp vstartComradBtn", "Start Comrad")
        startComradBtn.SetFont("s10")
        startComradBtn.OnEvent("Click", this.Launch_Comrad_Btn_Click)
        this.CheckLaunchButtons()

        this.Add("GroupBox", "Section w475 h120 xs", "Linked Search")
        this.Add("Text", "w400 xp20 yp30 Center", "Search for a patient across radiology providers")
        searchEdit := this.Add("Edit", "w200 h40 xp+80 yp25 Limit8 -Multi WantReturn Uppercase vSearchEdit")
        searchEdit.SetFont("s18")
        this.Add("Button", "Default w50 h40 yp vSearchBtn", "Go").OnEvent("Click", "SearchBtn_Click")


        tab.UseTab("Settings")
        fieldWidth := 100
        fieldOpts := "w" fieldWidth " xs10 yp25 Right"
        editWdith := 200
        editOpts := "w" editWdith " xp120 yp r1"

        this.Add("GroupBox", "w475 h80 Section", "Comrad Settings")
        this.Add("Text", fieldOpts " yp20", "Username:")
        this.Add("Edit", editOpts " vComradUsernameEdit Uppercase", Config.Comrad["Username"])
        this.Add("Text", fieldOpts, "Password:")
        this.Add("Edit", editOpts " Password vComradPWEdit", Config.Comrad["PW"])

        this.Add("GroupBox", "w475 h480 Section xs", "Inteleviewer Settings")
        this.Add("Text", "wp-20 xp+10 yp20 Center", "Christchurch Hospital").SetFont("s8 bold underline")
        this.Add("Text", fieldOpts " yp20", "Server URL:")
        this.Add("Edit", editOpts " w300 vIVCDHBURLEdit", Config.IV["CDHB"]["Url"])
        this.Add("Text", fieldOpts, "Username:")
        this.Add("Edit", editOpts " vIVCDHBUsernameEdit", Config.IV["CDHB"]["Username"])
        this.Add("Text", fieldOpts, "Password:")
        this.Add("Edit", editOpts " Password vIVCDHBPWEdit", Config.IV["CDHB"]["PW"])

        this.Add("Text", "wp-20 xp+10 yp40 Center", "Pacific Radiology Group (PRG)").SetFont("s8 bold")
        this.Add("Text", fieldOpts " yp20", "Server URL:")
        this.Add("Edit", editOpts " w300 vIVPRGURLEdit", Config.IV["PRG"]["Url"])
        this.Add("Text", fieldOpts, "Username:")
        this.Add("Edit", editOpts " vIVPRGUsernameEdit", Config.IV["PRG"]["Username"])
        this.Add("Text", fieldOpts, "Password:")
        this.Add("Edit", editOpts " Password vIVPRGPWEdit", Config.IV["PRG"]["PW"])

        this.Add("Text", "wp-20 xp+10 yp40 Center", "Reform Radiology").SetFont("s8 bold")
        this.Add("Text", fieldOpts " yp20", "Server URL:")
        this.Add("Edit", editOpts " w300 vIVReformURLEdit", Config.IV["Reform"]["Url"])
        this.Add("Text", fieldOpts, "Username:")
        this.Add("Edit", editOpts " vIVReformUsernameEdit", Config.IV["Reform"]["Username"])
        this.Add("Text", fieldOpts, "Password:")
        this.Add("Edit", editOpts " Password vIVReformPWEdit", Config.IV["Reform"]["PW"])

        this.Add("Text", "wp-20 xp+10 yp40 Center", "Beyond Radiology").SetFont("s8 bold")
        this.Add("Text", fieldOpts " yp20", "Server URL:")
        this.Add("Edit", editOpts " w300 vIVBeyondURLEdit", Config.IV["Beyond"]["Url"])
        this.Add("Text", fieldOpts, "Username:")
        this.Add("Edit", editOpts " vIVBeyondUsernameEdit", Config.IV["Beyond"]["Username"])
        this.Add("Text", fieldOpts, "Password:")
        this.Add("Edit", editOpts " Password vIVBeyondPWEdit", Config.IV["Beyond"]["PW"])

        this.Add("Button", "Default w100 yp30 xp40", "Save").OnEvent("Click", "SettingsSaveBtn_Click")
        ;; Add a + button to add a group of controls
        tab.Choose(1)
    }

    Close() {
        this.Minimize()
        return true ;; Prevents the window from closing
    }

    Launch_IV_Btn_Click(*) {
        InteleviewerApp.login(Config.IV["CDHB"]["Username"], Config.IV["CDHB"]["PW"])
    }

    Launch_Comrad_Btn_Click(*) {
        ComradApp.login(Config.Comrad["Username"], Config.Comrad["PW"])
    }

    StartAllBtn_Click(*) {
        this.Launch_IV_Btn_Click()
        this.Launch_Comrad_Btn_Click()
    }

    SearchBtn_Click(*) {
        id := this["SearchEdit"].Value
        opener.searchPatient(id)
    }

    CheckLaunchButtons() {
        If Config.Comrad["Username"] and Config.Comrad["PW"]
            this['startComradBtn'].Enabled := true
        Else
            this['startComradBtn'].Enabled := false

        If Config.IV["CDHB"]["Username"] and Config.IV["CDHB"]["PW"]
            this['startIVBtn'].Enabled := true
        Else
            this['startIVBtn'].Enabled := false
    }

    AddIVGroupBtn_Click(*) {
        ;; Add a group of controls to the settings tab
        tab := this["Tab"]
        tab.UseTab(3)
        this.Add("Text", "vTest", "Test")
        ;; Resize Tab to accommodate new control
        tab.GetPos(, , , &h)
        this["Tab"].Move(, , , h + 20)
        this.Show("AutoSize")
    }

    SettingsSaveBtn_Click(*) {
        Config.Comrad["Username"] := this['ComradUsernameEdit'].Value
        Config.Comrad["PW"] := this['ComradPWEdit'].Value

        Config.IV["CDHB"]["URL"] := this['IVCDHBURLEdit'].Value
        Config.IV["CDHB"]["Username"] := this['IVCDHBUsernameEdit'].Value
        Config.IV["CDHB"]["PW"] := this['IVCDHBPWEdit'].Value

        Config.IV["PRG"]["URL"] := this['IVPRGURLEdit'].Value
        Config.IV["PRG"]["Username"] := this['IVPRGUsernameEdit'].Value
        Config.IV["PRG"]["PW"] := this['IVPRGPWEdit'].Value

        Config.IV["Reform"]["URL"] := this['IVReformURLEdit'].Value
        Config.IV["Reform"]["Username"] := this['IVReformUsernameEdit'].Value
        Config.IV["Reform"]["PW"] := this['IVReformPWEdit'].Value

        Config.IV["Beyond"]["URL"] := this['IVBeyondURLEdit'].Value
        Config.IV["Beyond"]["Username"] := this['IVBeyondUsernameEdit'].Value
        Config.IV["Beyond"]["PW"] := this['IVBeyondPWEdit'].Value

        Config.saveConfig()
        this.CheckLaunchButtons()

    }
}

Main := MainGui().Show()