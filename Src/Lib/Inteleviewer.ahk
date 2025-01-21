#include ../Common.ahk

class InteleviewerApp {
    static WinTitle_Viewer := ".* InteleViewer.* ahk_exe InteleViewer.exe"
    static WinTitle_Viewer_Exclude := "^(Search.*)|(Chat.*)"
    static WinTitle_Search := "Search Tool"
    static WinTitle_Login := "INTELEPACS - InteleViewer Login"
    static RE_Dragged_Uid := "Drag started for thumbnail dataset PersistentImageId \[mSeriesInstanceUid=(?P<Uid>[0-9.]+),"
    static RE_Protocol_Match_Acc := "Loading matched prior study: Study \[[A-Za-z0-9-]+ Acc (?P<ACC>" RE_ACC ")"
    static RE_ACC_PID := "Acc\[(?P<ACC>[A-Z0-9-_]+)\] Pid\[(?P<NHI>[A-Z0-9-_]+)\]"
    static LogFilePath := A_Temp "\CViewer.log"

    static ActivateViewer() {
        SetTitleMatchMode "RegEx"
        WinActivate ".* InteleViewer.* ahk_exe InteleViewer.exe", , "^(Search.*)|(Chat.*)"
    }

    static ActivateSearchPage() {
        this.ActivateViewer()
        Send "/"
    }

    static ActivateReportPage() {
        this.ActivateViewer()
        Send "v"
    }

    static SearchActive() {
        return WinActive(this.WinTitle_Search)
    }

    static ViewerActive() {
        prev := SetTitleMatchMode("RegEx")
        result := WinActive(this.WinTitle_Viewer, , this.WinTitle_Viewer_Exclude)
        SetTitleMatchMode(prev)
        return result
    }

    static WinExist() {
        return WinExist("ahk_exe InteleViewer.exe")
    }

    static LogFile() {
        ;; The entire log file, can be very big in size in a long session
        ;; Therefore only the last byte will be returned
        file := FileOpen(this.LogFilePath, "r")
        IsMoved := file.Seek(-1024 * 512)
        content := file.Read()
        file.Close()
        return content
    }

    static TrimmedLogFile() {
        /*
        Subset of the log file from when the current study was opened
        The current study is determined by most recent Comrad integration log
        
        Prior arts:
        1. Comrad log file - however sometimes this log occurs too late, and results in metadata loss
        2. Use 'loading order' line, but does not work if study is opened from draft
        
        ;; TODO: use the server query instead
        */
        Log := this.LogFile()
        CurrentStudy := this.SessionHistory()[-1]
        Result := SubStr(Log, CurrentStudy.Pos)
        return Result
    }

    static SessionHistory() {
        Log := this.LogFile()
        Result := []
        spo := 1

        while fpo := RegExMatch(Log, this.RE_ACC_PID, &Match, spo) {
            spo := fpo + StrLen(Match[0])

            Study := {
                Acc: Match.Acc,
                NHI: Match.NHI,
                Pos: Match.Pos
            }

            If (Result.Length > 0) and Study.Acc = Result.Get(-1).Acc
                continue
            Else
                Result.Push(Study)
        }

        return Result
    }

    static CurrentPatient() {
        ;; Inteleviewer logs a lot of events in the format of "Acc[*.] Pid[*.]", corresponding to the current patient
        ;; Search for the last occurence of Acc and Pid
        ;; Because the logfile may get huge after periods of idling, we look it up in reverse in small chunks
        ChunkSize := 64 * 1024
        LogFile := FileOpen(this.LogFilePath, "r")
        LogFile.Seek(-ChunkSize) ;; Search the last 256kB of the log file
        Log := LogFile.Read()
        Needle := "s).*" . this.RE_ACC_PID
        while !(Pos := RegExMatch(Log, Needle, &match)) {
            success := LogFile.Seek(-ChunkSize * 2, 1) ;; Search backwards for two chunks
            if not success {
                ;; If we are approaching the start of the file, the leftover space may not be enough
                ppos := LogFile.Pos
                LogFile.Seek(0)
                Log := LogFile.Read(ppos)
                if !(Pos := RegExMatch(Log, Needle, &match)) {
                    ;; Do one last search of the remainder chunk, if not found, then NULL
                    null_result := { NHI: "NULL_PATIENT_ID", ACC: "NULL_ACCESSION_NUMBER" }
                    MsgBox null_result.NHI " " null_result.ACC
                    return null_result
                }
            }
            Log := LogFile.Read(ChunkSize)
        }
        return match
    }

    static GetLastDraggedAccession() {
        Content := this.TrimmedLogFile()
        Needle := "s).*" . this.RE_Dragged_Uid
        Pos := RegExMatch(Content, Needle, &match)
        if Pos {
            Accession := this.GetAccessionFromUid(match.Uid)
            return Accession
        }
    }

    static GetStudyDate(Acc) {
        try {
            ;; Try using InteleBrowser first
            PriorStudies := this.QueryPriorStudies(this.CurrentPatient().NHI)
            For Study in PriorStudies {
                If Study.ACC = Acc
                    return this.FormatDate(Study.Date)
            }
        } catch {
            ;; Acc CA-00000000-CR Pid ABC0001 Dated 2023-03-20]
            Content := this.TrimmedLogFile()
            RE_DATE := "Acc " Acc " Pid " RE_NHI " Dated (?P<Date>[0-9-]{10})]"
            RegExMatch(Content, RE_DATE, &Match)
            if Match
                return this.FormatDate(Match.Date)
        }
    }

    static GetMatchedProtocolAccession() {
        ;; Get the accession of the image retrieved by the hanging protocol
        content := this.TrimmedLogFile()
        NHI := this.CurrentPatient().NHI
        RE_prior := "Loading matched prior study: Study \[[-A-Za-z]+ Acc (?P<ACC>" RE_ACC ") Pid " nhi
        RegExMatch(content, RE_prior, &match)
        if match {
            return match.ACC
        } else
            return ""
    }

    static GetLatestAccession() {
        ;; Get the last touched image accession within the current study
        ;; This include last dragged image and auto-matched image from hanging protocol
        currentAccession := this.CurrentPatient().Acc
        lastDragged := this.GetLastDraggedAccession()
        matchedPrior := this.GetMatchedProtocolAccession()
        if (lastDragged && (lastDragged != currentAccession)) {
            return lastDragged
        } else if matchedPrior {
            return matchedPrior
        }
    }

    static CurrentSearchResultsRow() {
        ;; Successfully loaded detailed history and impressions in <CriticalResultPanel-38> for accession num: CA-17473925-CT
        ;; Successfully retrieved order notes for accession number: CA-2134393-CT
    }

    static GenerateComparisonLine(Acc) {
        ;; Returns a string of Study Description and Date of Study, for use in reports
        PriorStudies := this.QueryPriorStudies(this.CurrentPatient().NHI)
        For Study in PriorStudies {
            If HasVal(["DX", "CR"], Study.Mod)
                StudyDesc := "X-RAY " . Study.Desc
            Else
                StudyDesc := Study.Desc

            If Study.Acc = Acc {
                return StudyDesc " " this.FormatDate(Study.Date) ". "
            }
        }
    }

    static GatherTouchedAccessions() {
        ;; Gather all studies that has been selected, dragged and matched
        ;; Return an array of accession numbers
        RelevantLog := this.TrimmedLogFile()
        Result := Array()
        spo := 1

        while fpo := RegExMatch(RelevantLog, this.RE_Protocol_Match_Acc, &Match, spo) {
            ;; Get Accession Number
            Acc := Match.Acc
            ;; Append if not present already
            If not HasVal(Result, Acc)
                Result.Push(Acc)
            ;; Update StartingPos
            spo := fpo + StrLen(Match[0])
        }

        spo := 1
        while fpo := RegExMatch(RelevantLog, this.RE_Dragged_Uid, &Match, spo) {
            ;; Get Accession Number from Uid
            Acc := this.GetAccessionFromUid(Match.Uid)
            ;; Add if not previously added
            If not HasVal(Result, Acc)
                Result.Push(Acc)
            ;; Update StartingPos
            spo := fpo + StrLen(Match[0])
        }

        Return Result
    }

    static ShowReport() {
        WinActivate "ahk_group RadiologyGroup"
        Send "v"
    }

    static GetAuthConfig() {
        ;; Returns last used baseUrl, username, session ID
        content := this.LogFile()
        baseUrl := "(?P<baseUrl>https?:\/\/.+)" . "\/InteleViewerService\/InteleViewerService"
        username := "\?username=(?P<username>[A-Za-z0-9]+)"
        sid := "&sessionId=(?P<sid>[a-z0-9]{32})"
        needle := baseUrl . username . sid
        f := RegExMatch(content, needle, &config)
        return config
    }


    static FormatDate(Date) {
        if ( not Date)
            Return ""
        if InStr(Date, "/") {
            Date := strReplace(Date, "/", "")
        } else if InStr(Date, "-") {
            Date := strReplace(Date, "-", "")
        }
        return FormatTime(Date, "dd/MM/yyyy")
    }

    static PriorStudiesListView() {
        PriorStudies := this.QueryPriorStudies(this.CurrentPatient().NHI)
        Touched := this.GatherTouchedAccessions()

        g := Gui()
        LV := g.Add("ListView", "r20 w500 Checked", ["Mod", "Study", "Date", "Acc"])
        For Study in PriorStudies {
            LV.Add(, Study.Mod, Study.Desc, Study.Date, Study.Acc)
        }

        LV.ModifyCol(3, "SortDesc")
        LV.OnEvent("DoubleClick", LV_DoubleClick)
        g.OnEvent("Escape", g.Destroy)
        LV.ModifyCol ;; Auto-sizes all columns
        g.Show()

        setTimer () => LV_UpdateTouchedRow(LV)

        LV_UpdateTouchedRow(LV) {
            Touched := this.GatherTouchedAccessions()

            try {
                Loop LV.GetCount() {
                    Acc := LV.GetText(A_Index, 4)
                    if HasVal(Touched, Acc)
                        LV.Modify(A_Index, "Check")
                }
            } catch {
                ;; Delete timer if Gui was destroyed
                SetTimer , 0
            }
        }

        LV_DoubleClick(LV, RowNumber) {
            Mod := LV.GetText(RowNumber, 1)
            Desc := LV.GetText(RowNumber, 2)
            Date := LV.GetText(RowNumber, 3)

            Result := ReformatDescription(Mod, Desc) " " this.FormatDate(Date)
            ControlSend(Result, PowerScribeApp.GetEditorCtrl(), PowerScribeApp.WinTitle)
        }

        ReformatDescription(Mod, Desc) {
            if (Mod = "CR") {
                return Desc " radiograph"
            } else {
                return Desc
            }
        }
    }

    static AccessionToStudy(Acc) {
        PriorStudies := this.QueryPriorStudies(this.CurrentPatient().NHI)
        For Study in PriorStudies {
            If Study.Acc = Acc
                return Study
        }
    }

    static QueryPriorStudies(NHI) {
        ;; Queries the Intelerad server for a string of prior studies
        ;; Caches the result for the current NHI
        formattedNHI := this._BuildRelatedNHIQueryString(nhi)
        match := this.GetAuthConfig()
        baseUrl := match.baseUrl
        username := match.username
        sessionId := match.sid
        url := baseUrl "/InteleBrowser/InteleBrowser.Search"

        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-type", "application/x-www-form-urlencoded")
        whr.Send("UserName=" username "&SID=" sessionId "&sf0=" formattedNHI "&comparator0=EQUALS&searchScope=internal&Action=appletsearch&searchProtocolVersion=4")
        whr.WaitForResponse()
        Response := whr.ResponseText

        return this._ParsePriorStudiesResponse(Response)
    }

    static _BuildRelatedNHIQueryString(NHI) {
        ;; todo: include other matches
        ;; [2023-07-18 13:57:04.301 InteleViewer R19348 (TRACE) {26}] Setting candidate patients info: [Candidate Patient: BBG355ZCRG[95%], Candidate Patient: BPM1488CRG[95%]]
        log := this.TrimmedLogFile()
        try {
            RegExMatch(log, "s).*Build the task to search related series for \[(?P<NHIs>[A-Z0-9,-\s]+)\]", &match)
            result := StrReplace(match.NHIs, ", ", "%5C")
            If InStr(result, NHI)
                Return result
            else {
                Return NHI
            }
        }
        catch
            Return NHI
    }

    static _ParsePriorStudiesResponse(Response) {
        ;; Parse the response string and return an array of studies
        ;; A study contains Accession Number, Date, Modality, Description and an array of UID

        Result := Array()

        Loop Parse, Response, "`n" {
            if (A_Index = 1 or A_Index = 2) {
                ;; Skip the first 2 header rows
                continue
            }

            if RegExMatch(A_LoopField, RE_NHI) {
                ;; If a row specifying a Study
                Loop Parse, A_LoopField, "|" {
                    switch A_Index {
                        case 6:
                            Acc := A_LoopField
                        case 7:
                            Date := A_LoopField
                        case 8:
                            Mod := A_LoopField
                        case 10:
                            Desc := A_LoopField
                    }
                }
                Study := { Acc: Acc, Date: Date, Mod: Mod, Desc: Desc, Uids: [] }
            }

            if RegExMatch(A_LoopField, "^[0-9.]+") {
                ;; If a row specifying an series Uid
                UidRow := StrSplit(A_LoopField, "|")
                Study := Result.Pop()
                Study.Uids.Push(UidRow[1])
            }
            Result.Push(Study)
        }
        Return Result
    }

    static GetCurrentTool() {
        ;; User selected tool : DRAG-AND-SWAP, ZOOM, 3D-CURSOR
        Content := this.TrimmedLogFile()
        Needle := "s).*User selected tool : (?P<Tool>[0-9A-Z-]+)"
        Pos := RegExMatch(Content, Needle, &Match)
        If Pos
            Tool := Match.Tool
        Else
            Tool := "Default"

        Return Tool
    }

    static GetCurrentWindowLevel() {
        ;;  DefaultKeyHandler: processing keystroke [pressed F5] and executing action [WINDOW-LEVEL-PRESET-3]
        Content := this.TrimmedLogFile()
        Needle := "s).*DefaultKeyHandler: processing keystroke \[pressed ..\] and executing action \[(?P<Window>[A-Z0-9-]+)\]"
        Pos := RegExMatch(Content, Needle, &Match)
        If Pos
            Tool := Match.Window
        Else
            Tool := "Default"

        Return Tool
    }

    static GetAccessionFromUid(Uid) {
        ;; Find the Acc from InteleBrowser
        ;; If can't, use the log as fallback
        try {
            PriorStudies := this.QueryPriorStudies(this.CurrentPatient().NHI)
            For Study in PriorStudies {
                For _Uid in Study.Uids {
                    If Uid = _Uid
                        Return Study.ACC
                }
            }
        } catch {
            ;; Acc [CA-1234578-CT], series UID [1.1.11.1.1.1.1.1.11.3]
            Content := this.TrimmedLogFile()
            Needle := "Acc \[(?P<Acc>" RE_ACC ")\], series UID \[" Uid "\]"
            RegExMatch Content, Needle, &Match
            Return Match.Acc
        }
    }

    static login(username, password) {
        If WinExist(username " ahk_exe InteleViewer.exe") {
            TransientTrayTip "Inteleviewer is already running"
            return
        }
        Else If WinExist("INTELEPACS - InteleViewer Login") {
            this._send_cred(username, password)
            return
        }
        Else {
            Run "C:\Program Files\Intelerad Medical Systems\InteleViewer\CViewer\StartInteleViewer.exe"
            WinWait "INTELEPACS - InteleViewer Login"
            this._send_cred(username, password)
            return
        }
    }

    static _send_cred(username, password) {
        ;; Send username and password to the login window
        ;; Previously tried to use ControlSend, but it was unreliable
        BlockInput 1
        WinActivate this.WinTitle_Login
        Click 500, 330 ;; Select first server
        Click 500, 360 ;; Select username
        Sleep 100
        Send "^a"       ;; Clear saved username
        SendText username    ;; Type in username
        Send "{Tab}"
        Sleep 250
        SendText password  ;; Password
        Sleep 250
        Send "{Enter}"
        BlockInput 0
    }
}