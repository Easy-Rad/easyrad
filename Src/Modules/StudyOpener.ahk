#Include ../Common.ahk

class StudyOpener {
    ;; login to all COMS
    ;; save COMS to object

    __New() {
        ;; Save all Inteleviewer COM objects
        this.IV_COM_objs := Map()

        for site, in Config.InteleViewerSites
            if (url := Config.InteleViewer[site " URL"]) and (username := Config.InteleViewer[site " Username"]) and (password := Config.InteleViewer[site " Password"])
                this.IV_COM_objs[site] := InteleviewerCOM(url, username, password)
    }

    searchPatient(id) {
        ;; Show a table with all the studies performed in various vendors
        ;; Double click on a study opens the study using credentials from that vendor
        responses := Map()
        for vendor, obj in this.IV_COM_objs
            responses[vendor] := obj.GetPriorStudies(id)

        this._PriorStudiesListView(id, responses)
    }

    _PriorStudiesListView(NHI, priorStudiesResponsesMap) {
        g := Gui()
        g.Title := NHI . " | Linked Search | EasyRad"
        LV := g.Add("ListView", "r40 w800", ["Date", "Mod", "Study", "Acc", "Provider"])
        vendorPrefixes := Map("CDHB", "CA", "PRG", "PR", "Reform", "RR", "Beyond", "BE")
        For vendor, response in priorStudiesResponsesMap {
            priorsStudies := this._ParsePriorStudiesResponse(response)
            uniqueStudies := [] ;; array for deduplication

            For Study in priorsStudies {
                ;; Deduplicate studies: only keep the study with the matching prefix
                prefix := SubStr(Study.Acc, 1, 2)
                if not HasVal(uniqueStudies, Study.Acc) {
                    LV.Add(, Study.Date, Study.Mod, Study.Desc, Study.Acc, vendor)
                    uniqueStudies.Push(Study.Acc)
                }
            }
        }

        LV.ModifyCol(1, "150 SortDesc")
        LV.ModifyCol(2, "50")
        LV.ModifyCol(3, "200")
        LV.ModifyCol(4, "150")
        LV.ModifyCol(5, "AutoHdr Center")

        LV.OnEvent("DoubleClick", LV_DoubleClick)
        g.OnEvent("Escape", g.Destroy)
        g.Show("AutoSize")

        LV_DoubleClick(LV, RowNumber) {
            Provider := LV.GetText(RowNumber, 5)
            Acc := LV.GetText(RowNumber, 4)
            this.IV_COM_objs[Provider].OpenViaAccession(Acc)
        }

        ReformatDescription(Mod, Desc) {
            if (Mod = "CR") {
                return Desc " radiograph"
            } else {
                return Desc
            }
        }
    }

    _ParsePriorStudiesResponse(Response) {
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

    _FormatDate(Date) {
        if ( not Date)
            Return ""
        if InStr(Date, "/") {
            Date := strReplace(Date, "/", "")
        } else if InStr(Date, "-") {
            Date := strReplace(Date, "-", "")
        }
        return FormatTime(Date, "dd/MM/yyyy")
    }

    openStudy(id) {
        ;; Opens a study using the default vendor
        id := Trim(id)
        if RegExMatch(id, RE_ACC) {
            TransientToolTip("Acc: " id)
            this.IV_COM_objs["CDHB"].OpenViaAccession(id)
        } else if RegExMatch(id, RE_NHI) {
            TransientToolTip("NHI: " id)
            this.IV_COM_objs["CDHB"].OpenViaNHI(id)
        } else {
            MsgBox "No valid ID selected"
        }
    }

    OpenHighlightedText() {
        oldClip := A_Clipboard
        A_Clipboard := ""
        Send "^c"
        ClipWait 1
        this.OpenStudy(A_Clipboard)
        A_Clipboard := oldClip
    }
}