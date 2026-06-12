#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Version.ahk
#Include Modules/AutoTriage.ahk
#Include Lib/Config.ahk

A_TrayMenu.Delete
AutoTriageTrayMenu.AddToMenu(A_TrayMenu)
A_TrayMenu.Add
A_TrayMenu.AddStandard()

class AutoTriageTrayMenu {

    static DefaultRankMenuName := "Default rank"
    static StudySelectorMenuName := "Use study selector"
    static TriageRankDisabledMenuName := "Disabled"

    static AddToMenu(parentMenu) {
        parentMenu.Add(this.DefaultRankMenuName, DefaultTriageRankMenu := Menu())
        DefaultTriageRankMenu.Add(this.TriageRankDisabledMenuName, DefaultTriageRankMenuCallback)
        Loop 5 {
            DefaultTriageRankMenu.Add(A_Index, DefaultTriageRankMenuCallback)
        }
        this.UpdateDefaultTriageRankMenu(Config.AutoTriage["DefaultTriageRank"] || this.TriageRankDisabledMenuName, DefaultTriageRankMenu)
        parentMenu.Add(this.StudySelectorMenuName, ToggleEnableStudySelector)
        this.SetChecked(parentMenu, this.StudySelectorMenuName, Config.AutoTriage["UseStudySelector"])

        DefaultTriageRankMenuCallback(MenuItemSelected, ItemPos, myMenu) {
            Config.AutoTriage["DefaultTriageRank"] := this.TriageRankDisabledMenuName == MenuItemSelected ? 0 : MenuItemSelected
            this.UpdateDefaultTriageRankMenu(MenuItemSelected, myMenu)
        }

        ToggleEnableStudySelector(ItemName, ItemPos, menu) {
            this.SetChecked(menu, this.StudySelectorMenuName, Config.AutoTriage["UseStudySelector"] := !Config.AutoTriage["UseStudySelector"])
        }
    }

    static UpdateDefaultTriageRankMenu(MenuItemSelected, menu) {
        this.SetChecked(menu, this.TriageRankDisabledMenuName, this.TriageRankDisabledMenuName == MenuItemSelected)
        Loop 5
            this.SetChecked(menu, A_Index, A_Index == MenuItemSelected)
    }

    static SetChecked(menu, itemName, checked) {
        if checked
            menu.Check(itemName)
        else
            menu.Uncheck(itemName)
    }
}