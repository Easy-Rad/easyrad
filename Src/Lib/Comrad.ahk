#Include ../Common.ahk

class ComradApp {
    static MainAppWinTitle := "COMRAD Medical Systems Ltd"
    static LoggedInWinTitle := this.MainAppWinTitle . ".*Client ID"
    static SelectInterfaceWinTitle := "COMRAD Login - Select Network Interface"
    static ahk_exe := " ahk_exe javaw.exe"

    static WinActivate() {
        WinActivate this.MainAppWinTitle
    }

    static WinActive() {
        return WinActive(this.MainAppWinTitle)
    }

    static WinExist() {
        return WinExist(this.MainAppWinTitle)
    }

    static LoggedIn() {
        PrevMatchMode := SetTitleMatchMode("RegEx")
        loggedIn := WinExist(this.MainAppWinTitle . ".*Client ID")
        SetTitleMatchMode(PrevMatchMode)
        return loggedIn
    }

    static OpenOrder(accession) {
        ;; Write to I:/AccessionNumber.ims
        ;; File contains the accession number only
        FileDelete "V:\*.ims"
        FileAppend accession, "V:\AccessionNumber.ims"
    }

    static login(username, password, interface := 1) {
        EnvSet "use_proxy", "off"
        EnvSet "http_proxy"
        EnvSet "https_proxy"
        If ComradApp.LoggedIn() {
            TransientTrayTip "Comrad is already running"
            return
        } Else If WinExist(this.MainAppWinTitle) {
            this._send_cred(username, password)
            return
        } Else If WinExist(this.SelectInterfaceWinTitle) {
            this._select_interface(interface)
            this._send_cred(username, password)
            return
        } Else {
            Run A_ComSpec ' /c c:\comrad_java\cdhb.bat'
            WinWait "Wget"
            WinWaitClose "Wget"
            PrevMatchMode := SetTitleMatchMode("RegEx")
            If WinWait("(" this.SelectInterfaceWinTitle ")|(" this.MainAppWinTitle ")", , 10)
                If WinExist(this.SelectInterfaceWinTitle) {
                    this._select_interface(interface)
                    If WinWait(this.MainAppWinTitle)
                        this._send_cred(username, password)
                }
            this._send_cred(username, password)
            SetTitleMatchMode(PrevMatchMode)
            return
        }
    }

    static _send_cred(username, password) {
        BlockInput 1
        Sleep 500
        SetKeyDelay 10, 10
        ControlSend username "{Tab}" password "{Enter}", , this.MainAppWinTitle
        WinWaitClose this.MainAppWinTitle
        BlockInput 0
    }

    static _select_interface(interface) {
        WinActivate this.SelectInterfaceWinTitle
        BlockInput 1
        Loop interface
            ControlSend "{Tab}", , this.SelectInterfaceWinTitle
        ControlSend "{Space}", , this.SelectInterfaceWinTitle
        BlockInput 0
    }
}