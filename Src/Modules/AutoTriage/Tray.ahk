#Requires AutoHotkey v2.0
#Include "Config.ahk"
#Include "AutoTriage.ahk"

class AutoTriageTrayMenu {

    static DefaultRankMenuName := "Default rank"
    static StudySelectorMenuName := "Use study selector"
    static TriageRankDisabledMenuName := "Disabled"
    static ForgetAliasMenuName := "Forget alias"

    static AddToMenu(parentMenu) {
        parentMenu.Add(this.DefaultRankMenuName, DefaultTriageRankMenu := Menu())
        DefaultTriageRankMenu.Add(this.TriageRankDisabledMenuName, DefaultTriageRankMenuCallback)
        Loop 5 {
            DefaultTriageRankMenu.Add(A_Index, DefaultTriageRankMenuCallback)
        }
        this.UpdateDefaultTriageRankMenu(Config.DefaultTriageRank || this.TriageRankDisabledMenuName, DefaultTriageRankMenu)
        parentMenu.Add(this.StudySelectorMenuName, ToggleEnableStudySelector)
        this.SetChecked(parentMenu, this.StudySelectorMenuName, Config.EnableStudySelector)
        parentMenu.Add(this.ForgetAliasMenuName, ForgetAlias)

        DefaultTriageRankMenuCallback(MenuItemSelected, ItemPos, myMenu) {
            Config.DefaultTriageRank := this.TriageRankDisabledMenuName == MenuItemSelected ? 0 : MenuItemSelected
            this.UpdateDefaultTriageRankMenu(MenuItemSelected, myMenu)
        }

        ToggleEnableStudySelector(ItemName, ItemPos, menu) {
            this.SetChecked(menu, this.StudySelectorMenuName, Config.EnableStudySelector := !Config.EnableStudySelector)
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