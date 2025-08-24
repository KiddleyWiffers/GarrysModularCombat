AddCSLuaFile()

include("gmc/gamemode/modules.lua")
include("gmc/gamemode/commands.lua")

Menu = nil
local existingData
local selectedBodygroupType = 0
local selectedBodygroupValue = 0
local descPanel = nil
modulebinds = {}
ModulesData = {}
moduleCooldowns = {}

net.Receive("SendSuitInfoToClient", function(len)
    existingData = net.ReadTable()
    local loadedsuit = existingData.suits[existingData.activeSuit]
    ModulesData = {}
    for com, bind in pairs(loadedsuit.keybinds) do
        modulebinds[com] = bind
    end

    for mod, lvl in pairs(loadedsuit.tech) do
        ModulesData[mod] = lvl
    end

    moduleCooldowns = {
        ["shieldamp"] = MOD_SHAMP_COOLDOWN + (MOD_SHAMP * ModulesData["shieldamp"]),
		["cloak"] = MOD_CLOAK_COOLDOWN - (MOD_CLOAK_COOLUP * ModulesData["cloak"]),
    }

    for mod, data in pairs(modules) do
        if not moduleCooldowns[mod] and data.COOLDOWN then
            local modLevel = ModulesData[mod] or 0
            moduleCooldowns[mod] = data.COOLDOWN + (modLevel * (data.COOLDOWN_SCALE or 0))
        end
    end
end)

local function PrintMyModules(ply, cmd, args)
    GMCDebugCommand(ply, cmd, args)
end

concommand.Add("gmc_debug_printmymodules", PrintMyModules, nil, "Print your current modules table to the console.", {FCVAR_CLIENTCMD_CAN_EXECUTE})
function MCMenu()
    if not IsValid(Menu) then
        Menu = vgui.Create("DFrame")
        Menu:SetSize(ScrW() / 2, ScrH() / 1.5)
        Menu:Center()
        Menu:SetTitle("")
        Menu:SetDraggable(false)
        Menu:ShowCloseButton(false)
        Menu:SetDeleteOnClose(false)
        Menu:MakePopup()
        Menu.Paint = function()
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(0, 0, Menu:GetWide(), Menu:GetTall())
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawRect(0, Menu:GetTall() / 30, Menu:GetWide(), 1)
        end
		if existingData == nil then
			LocalPlayer():ConCommand("reloadsuitdata")
			timer.Simple(0.5, function() addButtons(Menu) end)
		else
			addButtons(Menu)
		end
    else
        if Menu:IsVisible() then
            Menu:SetVisible(false)
            gui.EnableScreenClicker(false)
        else
            Menu:SetVisible(true)
            gui.EnableScreenClicker(true)
        end
    end

    local closeButton = vgui.Create("DButton", Menu)
    closeButton:SetSize(30, 20)
    closeButton:SetPos(Menu:GetWide() - 35, 2.5)
    closeButton:SetText("")
    closeButton.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 200))
        surface.SetDrawColor(230, 207, 40, 255)
        surface.DrawOutlinedRect(0, 0, w, h)
        draw.SimpleText("X", "GMCSmallFont", w / 2, h / 2, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function() Menu:Close() end
    Menu.OnClose = function()
        Menu:SetVisible(false)
        Menu:InvalidateLayout(true)
        gui.EnableScreenClicker(false)
    end
end

concommand.Add("gmc_gamemenu", MCMenu)
function addButtons(Menu)
    local gamePanel = Menu:Add("GPanel")
    local playerPanel = Menu:Add("PPanel")
    local modulePanel = Menu:Add("MPanel")
    gamePanel:Hide()
    playerPanel:Show()
    modulePanel:Hide()
    local playerButton = vgui.Create("DButton")
    playerButton:SetParent(Menu)
    playerButton:SetText("")
    playerButton:SetSize(Menu:GetWide() / 4, Menu:GetTall() / 18)
    playerButton:SetPos(Menu:GetWide() / 20, Menu:GetTall() / 24)
    playerButton.Paint = function()
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, playerButton:GetWide(), playerButton:GetTall())
        surface.SetDrawColor(230, 207, 40, 255)
        surface.DrawOutlinedRect(0, 0, playerButton:GetWide(), playerButton:GetTall(), 1)
        draw.SimpleText("Character", "GMCTitleFont", playerButton:GetWide() / 2, playerButton:GetTall() / 2, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    playerButton.DoClick = function()
        gamePanel:Hide()
        playerPanel:Show()
        modulePanel:Hide()
    end

    local gameButton = vgui.Create("DButton")
    gameButton:SetParent(Menu)
    gameButton:SetText("")
    gameButton:SetSize(Menu:GetWide() / 4, Menu:GetTall() / 18)
    gameButton:SetPos((Menu:GetWide() / 1.6) - gameButton:GetWide(), Menu:GetTall() / 24)
    gameButton.Paint = function()
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, gameButton:GetWide(), gameButton:GetTall())
        surface.SetDrawColor(230, 207, 40, 255)
        surface.DrawOutlinedRect(0, 0, gameButton:GetWide(), gameButton:GetTall(), 1)
        draw.SimpleText("Game", "GMCTitleFont", gameButton:GetWide() / 2, gameButton:GetTall() / 2, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    gameButton.DoClick = function()
        gamePanel:Show()
        playerPanel:Hide()
        modulePanel:Hide()
    end

    local moduleButton = vgui.Create("DButton")
    moduleButton:SetParent(Menu)
    moduleButton:SetText("")
    moduleButton:SetSize(Menu:GetWide() / 4, Menu:GetTall() / 18)
    moduleButton:SetPos((Menu:GetWide() / 1.05) - moduleButton:GetWide(), Menu:GetTall() / 24)
    moduleButton.Paint = function()
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, moduleButton:GetWide(), moduleButton:GetTall())
        surface.SetDrawColor(230, 207, 40, 255)
        surface.DrawOutlinedRect(0, 0, moduleButton:GetWide(), moduleButton:GetTall(), 1)
        draw.SimpleText("Modules", "GMCTitleFont", moduleButton:GetWide() / 2, moduleButton:GetTall() / 2, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    moduleButton.DoClick = function()
        gamePanel:Hide()
        playerPanel:Hide()
        modulePanel:Show()
    end
end

PlayerPanel = {} -- Player Panel
local pmicon = vgui.Create("DModelPanel", Panel)
function PlayerPanel:Init()
    self:SetSize(Menu:GetWide() * 0.95, Menu:GetTall() * 0.85)
    self:SetPos(24, Menu:GetTall() * 0.12)
    local bodygroupValueSlider = vgui.Create("DNumSlider", self)
    local bodygroupTypeSlider = vgui.Create("DNumSlider", self)
    local selectedBodygroupType = 1
    local selectedBodygroupValue = 0
    pmicon:SetParent(self)
    pmicon:SetSize(self:GetWide() / 4, self:GetTall() / 2)
    pmicon:SetModel(LocalPlayer():GetModel())
    pmicon:SetCamPos(Vector(30, 0, 55))
    pmicon:SetLookAt(Vector(0, 0, 50))
    pmicon:GetEntity():SetBodyGroups(LocalPlayer():GetInfo("gmc_bodygroups"))
    function pmicon.Entity:GetPlayerColor()
        return LocalPlayer():GetPlayerColor()
    end

    function pmicon:LayoutEntity(Entity)
        return
    end

    local pmiconRotationSlider = vgui.Create("DNumSlider", self)
    pmiconRotationSlider:Show()
    pmiconRotationSlider:SetPos(-100, pmicon:GetTall() - 30)
    pmiconRotationSlider:SetSize(pmicon:GetWide() * 1.5, 30)
    pmiconRotationSlider:SetText("")
    pmiconRotationSlider:SetMin(0)
    pmiconRotationSlider:SetMax(360)
    pmiconRotationSlider:SetValue(0)
    pmiconRotationSlider:SetDecimals(0)
    pmiconRotationSlider:SizeToContents()
    pmiconRotationSlider.OnValueChanged = function(self, value)
        selectedrotation = math.floor(value)
        pmicon.Entity:SetAngles(Angle(0, selectedrotation, 0))
    end

    pmicon.DoClick = function()
        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(Menu:GetWide(), Menu:GetTall())
        frame:Center()
        frame:MakePopup()
        frame:ShowCloseButton(false)
        frame.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, 200))
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("Playermodel Selection", "GMCSmallFont", w / 2, 5, Color(230, 207, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local closeButton = vgui.Create("DButton", frame)
        closeButton:SetSize(30, 20)
        closeButton:SetPos(frame:GetWide() - 40, 5)
        closeButton:SetText("")
        closeButton.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 200))
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("X", "GMCSmallFont", w / 2, h / 2, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        closeButton.DoClick = function() frame:Close() end
        local scrollPanel = vgui.Create("DScrollPanel", frame)
        scrollPanel:Dock(FILL)
        local iconLayout = vgui.Create("DIconLayout", scrollPanel)
        iconLayout:Dock(FILL)
        iconLayout:SetSpaceX(5)
        iconLayout:SetSpaceY(5)
        local allPlayermodels = player_manager.AllValidModels()
        local sortedModels = {}
        for name, model in pairs(allPlayermodels) do
            table.insert(sortedModels, {
                name = name,
                model = model
            })
        end

        table.sort(sortedModels, function(a, b) return a.name < b.name end)
        for _, modelData in ipairs(sortedModels) do
            local iconButton = iconLayout:Add("SpawnIcon")
            iconButton:SetModel(modelData.model)
            iconButton:SetTooltip(modelData.name)
            iconButton.DoClick = function()
                RunConsoleCommand("gmc_model", modelData.model)
                pmicon:SetModel(modelData.model)
                function pmicon.Entity:GetPlayerColor()
                    return LocalPlayer():GetPlayerColor()
                end

                net.Start("UpdatePlayerModel")
                net.WriteString(modelData.model)
                net.SendToServer()
                frame:Close()
                bodygroupTypeSlider:SetMax(pmicon.Entity:GetNumBodyGroups() - 1)
                bodygroupTypeSlider:SetDecimals(0)
                bodygroupValueSlider:SetMax(pmicon.Entity:GetBodygroupCount(selectedBodygroupType) - 1)
                if pmicon.Entity:GetBodygroupCount(selectedBodygroupType) - 1 < 1 then
                    bodygroupTypeSlider:Hide()
                    bodygroupValueSlider:Hide()
                else
                    bodygroupTypeSlider:Show()
                    bodygroupValueSlider:Show()
                end
            end
        end
    end

    local currentBodygroups = {}
    for i = 0, pmicon.Entity:GetNumBodyGroups() - 1 do
        currentBodygroups[i] = pmicon.Entity:GetBodygroup(i)
    end

    local function CreateBodygroupString()
        local bodygroupStr = "0"
        for i = 1, pmicon.Entity:GetNumBodyGroups() - 1 do
            bodygroupStr = bodygroupStr .. currentBodygroups[i]
        end
        return bodygroupStr:Trim()
    end


	colorPicker = vgui.Create("DColorMixer", self)
	colorPicker:SetSize(pmicon:GetWide() - 6, pmicon:GetTall() - 10)
	colorPicker:SetPos(3, pmicon:GetTall() + 5)
	colorPicker:SetColor(LocalPlayer():GetPlayerColor():ToColor())
	colorPicker.ValueChanged = function(picker, newColor)
		local playerColor = Vector(newColor.r / 255, newColor.g / 255, newColor.b / 255)
		LocalPlayer():SetPlayerColor(playerColor)
		local convarValue = string.format("%d %d %d", newColor.r, newColor.g, newColor.b)
		RunConsoleCommand("gmc_color", convarValue)
		function pmicon.Entity:GetPlayerColor()
			return LocalPlayer():GetPlayerColor()
		end
	end

    if existingData then
        local curSuit = LocalPlayer():GetActiveSuit()
        local buttonIndex = 1
        local numButtons = 5
        local buttonWidth = (self:GetWide() - pmicon:GetWide() - 20) / numButtons
        local renameSuitText = vgui.Create("DTextEntry", self)
        renameSuitText:SetPos(pmicon:GetWide() + 10, 170)
        renameSuitText:SetSize((self:GetWide() / 2.2 - pmicon:GetWide() - 20) * 0.7, 25)
        renameSuitText:SetText(existingData.suits[curSuit].SuitName)
        renameSuitText:SetMaximumCharCount(13)
        local suitButtons = {}
        for k, data in SortedPairs(existingData.suits) do
            local button = vgui.Create("DButton", self)
            button:SetPos(pmicon:GetWide() + 10 + (buttonIndex - 1) * buttonWidth, 105)
            button:SetSize(buttonWidth, 60)
            button:SetText("")
            button.Paint = function()
                surface.SetDrawColor(230, 207, 40, 255)
                surface.DrawOutlinedRect(0, 0, button:GetWide(), button:GetTall())
                draw.SimpleText(data.SuitName, "GMCSmallFont", 10, 10, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
                draw.SimpleText("Level: " .. data.plyLevel, "GMCSmallFont", 10, 30, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
            end

            button.DoClick = function()
                local suit = k
                LocalPlayer():SetActiveSuit(suit)
                curSuit = LocalPlayer():GetActiveSuit()
                net.Start("ChangeSuits")
                net.WriteString(suit)
                net.SendToServer()
                Menu:SetVisible(false)
                gui.EnableScreenClicker(false)
                renameSuitText:SetText(data.SuitName)
                modulebinds = {}
                for com, bind in pairs(data.keybinds) do
                    modulebinds[com] = bind
                end
            end

            suitButtons[k] = {
                button = button,
                data = data
            }

            buttonIndex = buttonIndex + 1
        end

        local renameSuitButton = vgui.Create("DButton", self)
        renameSuitButton:SetPos(pmicon:GetWide() + 20 + renameSuitText:GetWide(), 170)
        renameSuitButton:SetSize((self:GetWide() / 1.5 - pmicon:GetWide() - 20) * 0.3 - 10, 25)
        renameSuitButton:SetText("")
        renameSuitButton.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, 200))
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("Rename Suit", "GMCSmallFont", w / 2, 5, Color(230, 207, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        renameSuitButton.DoClick = function()
            local newName = renameSuitText:GetValue()
            net.Start("RenameSuit")
            net.WriteString(curSuit)
            net.WriteString(newName)
            net.SendToServer()
            renameSuitText:SetText(newName)
            for k, suitButton in pairs(suitButtons) do
                if k == curSuit then
                    local data = suitButton.data
                    data.SuitName = newName
                    data.plyLevel = LocalPlayer():GetLevel()
                    break
                end
            end
        end

        local resetSuitButton = vgui.Create("DButton", self)
        resetSuitButton:SetPos(pmicon:GetWide() + 10, 200)
        resetSuitButton:SetSize(self:GetWide() / 1.93 - pmicon:GetWide() - 20, 30)
        resetSuitButton:SetText("")
        resetSuitButton.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, 200))
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("Reset Suit", "GMCSmallFont", w / 2, 5, Color(230, 207, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        resetSuitButton.DoClick = function()
            local confirmResetPanel = vgui.Create("DPanel", self)
            confirmResetPanel:SetPos((self:GetWide() / 4) + 10, self:GetTall() / 3)
            confirmResetPanel:SetSize(self:GetWide() - pmicon:GetWide() - 20, 120)
            confirmResetPanel.Paint = function()
                draw.RoundedBox(8, 0, 0, confirmResetPanel:GetWide(), confirmResetPanel:GetTall(), Color(0, 0, 0, 200))
                draw.SimpleText("Are you sure you want to reset your active suit?", "GMCDescriptionFont", confirmResetPanel:GetWide() / 2, 20, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER)
                draw.SimpleText("This action will erase all the progress you've made.", "GMCDescriptionFont", confirmResetPanel:GetWide() / 2, 40, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER)
                draw.SimpleText("This action cannot be undone.", "GMCDescriptionFont", confirmResetPanel:GetWide() / 2, 60, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER)
            end

            local resetButton = vgui.Create("DButton", confirmResetPanel)
            resetButton:SetPos(10, 90)
            resetButton:SetSize(confirmResetPanel:GetWide() / 2 - 15, 20)
            resetButton:SetText("")
            resetButton.Paint = function(self, w, h)
                draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, 200))
                surface.SetDrawColor(230, 207, 40, 255)
                surface.DrawOutlinedRect(0, 0, w, h)
                draw.SimpleText("Confirm", "GMCSmallFont", w / 2, 0, Color(230, 207, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end

            resetButton.DoClick = function()
                net.Start("ResetSuit")
                net.SendToServer()
                confirmResetPanel:Remove()
                for k, suitButton in pairs(suitButtons) do
                    if k == curSuit then
                        local data = suitButton.data
                        data.SuitName = "New Suit"
                        data.plyLevel = 1
						descPanel:Clear()
                        break
                    end
                end
            end

            local cancelButton = vgui.Create("DButton", confirmResetPanel)
            cancelButton:SetPos(confirmResetPanel:GetWide() / 2 + 5, 90)
            cancelButton:SetSize(confirmResetPanel:GetWide() / 2 - 15, 20)
            cancelButton:SetText("")
            cancelButton.DoClick = function() confirmResetPanel:Remove() end
            cancelButton.Paint = function(self, w, h)
                draw.RoundedBox(10, 0, 0, w, h, Color(0, 0, 0, 200))
                surface.SetDrawColor(230, 207, 40, 255)
                surface.DrawOutlinedRect(0, 0, w, h)
                draw.SimpleText("Cancel", "GMCSmallFont", w / 2, 0, Color(230, 207, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end

        bodygroupTypeSlider:SetPos(pmicon:GetWide() + renameSuitText:GetWide() - 20, 165)
        bodygroupTypeSlider:SetSize(self:GetWide() / 1.5 - pmicon:GetWide() - 20, 30)
        bodygroupTypeSlider:SetText("")
        bodygroupTypeSlider:SetMin(1)
        bodygroupTypeSlider:SetDecimals(0)
        bodygroupTypeSlider:SetMax(pmicon.Entity:GetNumBodyGroups() - 1)
        bodygroupTypeSlider:SetValue(1)
        bodygroupTypeSlider.OnValueChanged = function(self, value)
            selectedBodygroupType = math.floor(value)
            bodygroupValueSlider:SetMax(pmicon.Entity:GetBodygroupCount(selectedBodygroupType) - 1)
            bodygroupValueSlider:SetValue(pmicon.Entity:GetBodygroup(selectedBodygroupType))
        end

        bodygroupValueSlider:SetPos(pmicon:GetWide() + renameSuitText:GetWide() - 20, 200)
        bodygroupValueSlider:SetSize(self:GetWide() / 1.5 - pmicon:GetWide() - 20, 30)
        bodygroupValueSlider:SetText("")
        bodygroupValueSlider:SetMin(0)
        bodygroupValueSlider:SetDecimals(0)
        bodygroupValueSlider:SetMax(pmicon.Entity:GetBodygroupCount(selectedBodygroupType) - 1)
        bodygroupValueSlider:SetValue(pmicon.Entity:GetBodygroup(1))
        local prevvalue = 0
        bodygroupValueSlider.OnValueChanged = function(self, value)
            selectedBodygroupValue = math.Round(value)
            pmicon.Entity:SetBodygroup(selectedBodygroupType, selectedBodygroupValue)
            currentBodygroups[selectedBodygroupType] = selectedBodygroupValue
            local bodygroupStr = CreateBodygroupString()
            RunConsoleCommand("gmc_bodygroups", bodygroupStr)
            if prevvalue ~= selectedBodygroupValue then
                prevvalue = selectedBodygroupValue
                net.Start("UpdateBodygroups")
                net.WriteInt(selectedBodygroupType, 8)
                net.WriteInt(selectedBodygroupValue, 8)
                net.SendToServer()
            end
        end

        if pmicon.Entity:GetBodygroupCount(selectedBodygroupType) - 1 < 1 then
            bodygroupTypeSlider:Hide()
            bodygroupValueSlider:Hide()
        else
            bodygroupTypeSlider:Show()
            bodygroupValueSlider:Show()
        end
    end
end

function PlayerPanel:Paint(w, h)
    surface.SetDrawColor(230, 207, 40, 255)
    surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 1)
    surface.SetDrawColor(230, 207, 40, 255)
    surface.DrawRect(0, pmicon:GetTall(), self:GetWide(), 1)
    surface.DrawRect(pmicon:GetWide(), 0, 1, self:GetTall())
    if modelcommand:GetString() == modelcommand:GetDefault() then
        draw.SimpleText("Click to change your playermodel", "GMCSmallFont", pmicon:GetWide() / 2, 10, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER)
        pmicon:SetCamPos(Vector(35, 0, 55))
    else
        pmicon:SetCamPos(Vector(30, 0, 55))
    end

    draw.SimpleText("Name: " .. LocalPlayer():Nick(), "GMCDescriptionFont", pmicon:GetWide() + 10, 10, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
    draw.SimpleText("Level: " .. LocalPlayer():GetLevel(), "GMCDescriptionFont", pmicon:GetWide() + 10, 40, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
    draw.SimpleText("Experience: " .. LocalPlayer():GetEXP() .. "/" .. LocalPlayer():GetEXPtoLevel(), "GMCDescriptionFont", pmicon:GetWide() + 10, 70, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
end

vgui.Register("PPanel", PlayerPanel, "Panel")
GamePanel = {} -- Game Panel
function GamePanel:Init()
    self:SetSize(Menu:GetWide() * 0.95, Menu:GetTall() * 0.85)
    self:SetPos(24, Menu:GetTall() * 0.12)
    if existingData then
        local activesuit = existingData.suits[LocalPlayer():GetActiveSuit()]
        local BindScroll = vgui.Create("DScrollPanel", self)
        BindScroll:SetSize(self:GetWide() / 3, self:GetTall() - 20)
        BindScroll:SetPos((self:GetWide() - BindScroll:GetWide()) - 10, 10)
        BindScroll.Paint = function()
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawOutlinedRect(0, 0, BindScroll:GetWide(), BindScroll:GetTall(), 1)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(1, 1, BindScroll:GetWide() - 2, 18)
            surface.SetDrawColor(230, 207, 40, 255)
            surface.DrawRect(0, 20, BindScroll:GetWide(), 1)
            draw.SimpleText("Active Modules Keybindings", "GMCSmallFont", 3, 2, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
        end

        local labelHeight = 20
        local buttonSpacing = 0
        local yOffset = labelHeight + buttonSpacing
        for mod, data in pairs(modules) do
            if data.Active then
				local lastSend = 0
                local ModuleBinder = vgui.Create("DBinder", BindScroll)
                ModuleBinder:SetSize(BindScroll:GetWide(), 40)
                ModuleBinder:SetPos(0, yOffset)
                yOffset = yOffset + ModuleBinder:GetTall() + buttonSpacing
                local modkey = activesuit.keybinds[mod] or 0
                ModuleBinder:SetValue(modkey)
                local IsActive = false
                ModuleBinder.OnReleased = function() IsActive = true end
                ModuleBinder.Paint = function()
                    if ModuleBinder:GetValue() ~= 0 and IsActive == false then
                        ModuleBinder:SetText(data.PrintName .. " = " .. input.GetKeyName(ModuleBinder:GetValue()))
                    elseif IsActive == true then
                        ModuleBinder:SetText("Press a button...")
                    else
                        ModuleBinder:SetText(data.PrintName .. " = None")
                    end

                    activesuit = existingData.suits[LocalPlayer():GetActiveSuit()]
                    modkey = activesuit.keybinds[mod] or 0
                    if modulebinds[mod] ~= modkey then ModuleBinder:SetValue(modkey) end
                    if ModuleBinder:GetValue() ~= modkey then ModuleBinder:SetValue(modkey) end
                    ModuleBinder:SetFont("GMCDescriptionFont")
                    ModuleBinder:SetColor(Color(230, 207, 40, 255))
                    surface.SetDrawColor(230, 207, 40, 255)
                    surface.DrawOutlinedRect(0, 0, ModuleBinder:GetWide(), ModuleBinder:GetTall(), 1)
                    surface.SetTexture(surface.GetTextureID(data.Icon))
                    surface.DrawTexturedRect(0, 0, 40, 40)
                end
				
                ModuleBinder.OnChange = function(_, key)
					if lastSend < CurTime() then
						lastSend = CurTime() + 0.1
						activesuit = existingData.suits[LocalPlayer():GetActiveSuit()]
						if modulebinds[mod] == key then
							modulebinds[mod] = 0
							activesuit.keybinds[mod] = 0
						else
							modulebinds[mod] = key
							activesuit.keybinds[mod] = key
						end
						local sentOnce = true
						for com, data in pairs(modulebinds) do
							if data == key and mod ~= com and sentOnce then
								sentOnce = false
								modulebinds[com] = 0
								activesuit.keybinds[com] = 0
								net.Start("BindModules")
								net.WriteString(com)
								net.WriteInt(0, 9)
								net.SendToServer()
							end
						end

						net.Start("BindModules")
						net.WriteString(mod)
						net.WriteInt(modulebinds[mod], 9)
						net.SendToServer()
						IsActive = false
					end
                end
            end
        end
    end
end

function GamePanel:Paint(w, h)
    surface.SetDrawColor(230, 207, 40, 255)
    surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 1)
end

vgui.Register("GPanel", GamePanel, "Panel")
ModulePanel = {}
function ModulePanel:Init()
    self:SetSize(Menu:GetWide() * 0.95, Menu:GetTall() * 0.85)
    self:SetPos(24, Menu:GetTall() * 0.12)
    self.categoryList = vgui.Create("DCategoryList", self)
    self.categoryList:SetPos(0, 0)
    self.categoryList:SetSize(self:GetWide() * 0.25, self:GetTall())
    self.categoryList.Paint = function()
        surface.SetDrawColor(230, 207, 40, 255)
        surface.DrawOutlinedRect(0, 0, self.categoryList:GetWide(), self.categoryList:GetTall(), 1)
    end

    self.descriptionPanel = vgui.Create("DPanel", self)
    self.descriptionPanel:SetPos(self:GetWide() * 0.25, 0)
    self.descriptionPanel:SetSize(self:GetWide() * 0.75, self:GetTall())
    self.descriptionPanel.Paint = function()
        surface.SetDrawColor(230, 207, 40, 255)
        surface.DrawOutlinedRect(0, 0, self.descriptionPanel:GetWide(), self.descriptionPanel:GetTall(), 1)
    end
	
	descPanel = self.descriptionPanel

    self.categoryButtons = {}
	for mod, data in pairs(modules) do
		local category = data.Category
        if not self.categoryButtons[category] then
            -- Create the category panel if not already created
            local cat = self.categoryList:Add(category)
            cat.Paint = function()
                surface.SetDrawColor(230, 207, 40, 255)
                surface.DrawOutlinedRect(0, 0, cat:GetWide(), cat:GetTall(), 1)
            end
            self.categoryButtons[category] = {panel = cat, modules = {}}
        end

        -- Add module to the category's module list
        table.insert(self.categoryButtons[category].modules, {mod = mod, data = data})
    end

    -- Add sorted modules to their respective category panels
    for category, categoryData in pairs(self.categoryButtons) do
        local cat = categoryData.panel
        local modulesList = categoryData.modules

        -- Sort modules by Order (primary) and PrintName (secondary)
        table.sort(modulesList, function(a, b)
            return a.data.PrintName < b.data.PrintName
        end)
		
		table.sort(modulesList, function(a, b)
            return a.data.Order < b.data.Order
        end)

        -- Add modules to the category
        for _, moduleInfo in ipairs(modulesList) do
            local modLabel = moduleInfo.data.PrintName
            local modButton = cat:Add(modLabel)
            modButton:SetTextColor(Color(230, 207, 40, 255))
            modButton.DoClick = function()
                self:UpdateDescriptionPanel(moduleInfo.mod, moduleInfo.data) -- Update description panel when module is clicked
            end
        end
	end
end

function ModulePanel:UpdateDescriptionPanel(mod, data)
    self.descriptionPanel:Clear()
    local icon = vgui.Create("DImage", self.descriptionPanel)
    icon:SetPos(10, 10)
    icon:SetSize(self.descriptionPanel:GetWide() / 6.84, self.descriptionPanel:GetTall() / 6.12)
    icon:SetImage(data.Icon)
    local printNameLabel = vgui.Create("DLabel", self.descriptionPanel)
    printNameLabel:SetPos(icon:GetWide() + 20, icon:GetTall() / 2)
    printNameLabel:SetText(data.PrintName)
    printNameLabel:SetFont("GMCTitleFont")
    printNameLabel:SizeToContents()
    printNameLabel:SetAutoStretchVertical(true)
    local descriptionLabel = vgui.Create("DLabel", self.descriptionPanel)
    descriptionLabel:SetPos(10, icon:GetTall() + 10)
    descriptionLabel:SetAutoStretchVertical(true)
    descriptionLabel:SetWide(self.descriptionPanel:GetWide() - 10)
    descriptionLabel:SetText(data.Description)
    descriptionLabel:SetFont("GMCDescriptionFont")
    descriptionLabel:SetWrap(true)
    timer.Simple(0.0001, function() self:CreateStatsTable(mod, data, descriptionLabel) end)
    self.descriptionPanel.Paint = function()
        local w, h = self.descriptionPanel:GetWide(), self.descriptionPanel:GetTall()
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
        surface.SetMaterial(Material(data.Icon))
        surface.DrawTexturedRect(100, 100, 80, 80)
        surface.SetTextColor(230, 207, 40, 255)
        draw.SimpleText("Module Points: " .. LocalPlayer():GetSP(), "GMCSmallFont", self.descriptionPanel:GetWide() - 140, 10, Color(230, 207, 40, 255), TEXT_ALIGN_LEFT)
    end
end

function ModulePanel:CreateStatsTable(mod, data, descriptionLabel)
    local statsTable = vgui.Create("DPanel", self.descriptionPanel)
    statsTable:SetPos(10, descriptionLabel:GetY() + descriptionLabel:GetTall() + 10)
    statsTable:SetSize(self.descriptionPanel:GetWide() - 20, self.descriptionPanel:GetTall() / 3)
    statsTable.Paint = function() end
    local maxLevel = data.MAXLEVEL or 1
    local baseValue = data.BASE or 0
    local playerLevel = ModulesData[mod] or 0 -- Access player's module level
    local grid = vgui.Create("DGrid", statsTable)
    grid:SetPos(0, 0)
    grid:SetCols(maxLevel + 1)
    grid:SetColWide(60)
    grid:SetRowHeight(30)
    grid.Paint = function(self, w, h)
        local numRows = math.ceil(#self:GetItems() / self:GetCols())
        for i = 1, self:GetCols() do
            for j = 1, numRows do
                local x = (i - 1) * self.m_iColWide
                local y = (j - 1) * self.m_iRowHeight
                surface.SetDrawColor(230, 207, 40, 255)
                surface.DrawOutlinedRect(x, y, self.m_iColWide, self.m_iRowHeight)
                if j == 1 and i == playerLevel + 1 and playerLevel > 0 then draw.RoundedBox(0, x, y, self.m_iColWide, self.m_iRowHeight * numRows, Color(230, 207, 40, 255)) end
            end
        end
    end

    local headerLabel = vgui.Create("DLabel") -- Create level header
    headerLabel:SetSize(60, 30)
    headerLabel:SetText("Level")
    headerLabel:SetContentAlignment(5)
    grid:AddItem(headerLabel)
    for level = 1, maxLevel do -- Create level labels
        local label = vgui.Create("DLabel")
        label:SetSize(60, 30)
        label:SetText(tostring(level))
        label:SetContentAlignment(5)
        if level == playerLevel then label:SetTextColor(Color(0, 0, 0, 255)) end
        grid:AddItem(label)
    end

    for _, stats in ipairs(data.STAT) do -- Populate stats for the module
        local statValue, statName, statBase, statType = stats[1], stats[2], stats[3] or -1, stats[4] or 0
        if statBase > -1 then baseValue = statBase end
        local statNameLabel = vgui.Create("DLabel")
        statNameLabel:SetSize(60, 30)
        statNameLabel:SetText(statName)
        statNameLabel:SetContentAlignment(5)
        grid:AddItem(statNameLabel)
        for level = 1, maxLevel do
            local statValueLabel = vgui.Create("DLabel")
            statValueLabel:SetSize(60, 30)
            local finalValue = 0
            if statType == 0 then -- Handle different types
                finalValue = (statValue * level) + baseValue
            elseif statType == 1 then
                finalValue = ((statValue * level) + baseValue) * 100 .. "%"
            elseif statType == 2 then
                finalValue = math.Round((statValue * level) + baseValue)
            elseif statType == 3 then
                finalValue = math.floor((statValue * level) + baseValue)
            elseif statType == 4 then
                finalValue = baseValue - (statValue * level)
            elseif statType == 5 then
                finalValue = (baseValue - (statValue * level)) * 100 .. "%"
            end

            statValueLabel:SetText(tostring(finalValue))
            statValueLabel:SetContentAlignment(5)
            if level == playerLevel then statValueLabel:SetTextColor(Color(0, 0, 0, 255)) end
            grid:AddItem(statValueLabel)
        end
    end

    local purchaseButton = vgui.Create("DButton", self.descriptionPanel) -- Purchase button logic
    purchaseButton:SetSize(self.descriptionPanel:GetWide() / 2, 40)
    purchaseButton:SetPos(self.descriptionPanel:GetWide() / 2 - purchaseButton:GetWide() / 2, self.descriptionPanel:GetTall() - 60)
    purchaseButton:SetText("Purchase")
    purchaseButton.DoClick = function()
        local plySkillPoints = LocalPlayer():GetSP()
        local moduleValue = ModulesData[mod] or 0
        if plySkillPoints >= 1 and moduleValue < data.MAXLEVEL then
            playerLevel = playerLevel + 1
            net.Start("UpdateModules")
            net.WriteString(mod)
            net.WriteInt(tonumber(moduleValue) + 1, 8)
            net.SendToServer()
            ModulesData[mod] = playerLevel
        elseif plySkillPoints >= 1 and moduleValue >= data.MAXLEVEL then
            chat.AddText(Color(255, 0, 0), "This module is at max level!")
        else
            chat.AddText(Color(255, 0, 0), "Not enough skill points to purchase this module!")
        end
    end
end

function ModulePanel:Paint(w, h)
    surface.SetDrawColor(230, 207, 40, 255)
    surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall(), 1)
end

vgui.Register("MPanel", ModulePanel, "Panel")