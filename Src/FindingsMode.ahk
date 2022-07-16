GetPowerScribeFindings() {
    findingsCtrl := GetPowerScribeFindingsCtrl()
    ControlGetText, Findings, %findingsCtrl%, %POWERSCRIBE%
    Return StrSplit(Findings, "`n")
}

SetPowerScribeFindings(lines) {
    findingsCtrl := GetPowerScribeFindingsCtrl()
    text := JoinLines(lines) 
    ControlSetText, %findingsCtrl%, %text%, %POWERSCRIBE%
    Return lines
}

ExtractPowerScribeImpressions() {
    reportCtrl := GetPowerScribeEditorCtrl()
    ControlGetText, report, %reportCtrl%, %POWERSCRIBE%
    needle := "O)(?P<Impression>\[.*\])"
    Pos := 1, Matches := []
    while(Pos := RegExMatch(report, needle, M, Pos + StrLen(M.Impression))) {
        Matches.Push(M.Impression)
    }
    Return JoinLines(Matches)
}

PopLine(lines, n) {
    Results := []
    Selected := ""
    for index, value in lines {
        if (index == n) {
            Selected := RegexReplace(value, "^[0-9 ]+\s>\s+")
            continue
        }
        Results.Push(value)

    }
    Return {lines: Results, selected: Selected}
}

SplitLines(text) {
    text := Trim(text, " `t`n`r")
    Return StrSplit(text, "`n")
}

JoinLines(lines) {
    Result := ""
    for index, value in lines
        Result .= value "`n"
    Result := Trim(Result, " `t`n`r")
    Return Result
}

AddNumbering(lines) {
    Results := []
    for index, value in lines {
        Results.Push(index . " > " . value)
    }
    Return Results
}

RemoveNumbering(lines) {
    Results := []
    for index, value in lines {
        newValue := RegexReplace(value, "^[0-9 ]+\s>\s+")
        Results.Push(newValue)
    }
    Return Results
}

