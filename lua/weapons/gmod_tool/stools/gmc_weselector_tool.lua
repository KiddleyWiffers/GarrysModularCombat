TOOL.Category = "Garry's Modular Combat"
TOOL.Name = "GMC Spawn Setter"

TOOL.ClientConVar["category"] = "Players"
TOOL.ClientConVar["type"] = "No Team"
TOOL.ClientConVar["extra1"] = ""
TOOL.ClientConVar["extra2"] = ""
TOOL.ClientConVar["extra3"] = ""

if CLIENT then
    language.Add("tool.gmc_weselector_tool.name", "GMC Spawn Setter")
    language.Add("tool.gmc_weselector_tool.desc", "Set spawnpoints for GMC using the settings on the tool.")
    language.Add("tool.gmc_weselector_tool.0", "Left-click to create a spawnpoint")
end
	
function TOOL.BuildCPanel(panel)
	if IsValid(panel) then
		panel:Clear()
	end
    local dropdownCategory = vgui.Create("DComboBox", panel)
    dropdownCategory:SetText("Select Category")
    dropdownCategory:SetPos(0, 20)
    dropdownCategory:SetSize(280, 30)
    dropdownCategory:SetValue("Players")
    dropdownCategory:AddChoice("Players")
    dropdownCategory:AddChoice("Weapons")
    dropdownCategory:AddChoice("NPCs")
    dropdownCategory:SetTextColor(Color(0, 0, 0, 255))

    -- Create dropdown menus
    local dropdownPanel = vgui.Create("DPanel", panel)
    dropdownPanel:SetPos(0, 60)
    dropdownPanel:SetSize(280, 220)
    dropdownPanel.Paint = function()
    end

    local playerspawns = {
        "No Team",
        "Red",
        "Blue",
        "Green",
        "Purple"
    }

    local dropdown1 = vgui.Create("DComboBox", dropdownPanel)
    dropdown1:SetPos(0, 0)
    dropdown1:SetSize(280, 30)
    for _, choice in ipairs(playerspawns) do
        dropdown1:AddChoice(choice)
    end
    dropdown1:SetVisible(true)
    dropdown1:SetTextColor(Color(0, 0, 0, 255))
    dropdown1:SetValue("No Team")

    -- Create a table to store weapon choices
    local weaponChoices = {}
	
	-- Include Half-Life 2 weapons
    local extraents = {
        "weapon_357",
        "weapon_smg1",
        "weapon_pistol",
        "weapon_ar2",
        "weapon_shotgun",
        "weapon_crossbow",
        "weapon_rocket_launcher",
        "weapon_grenade",
        "weapon_slam",
        "gmc_smallhealthpack",
        "gmc_mediumhealthpack",
        "gmc_largehealthpack",
    }

    for _, weapon in ipairs(extraents) do
        table.insert(weaponChoices, weapon)
    end

    -- Loop through available weapons and add them to the weaponChoices table
    for _, weapon in pairs(weapons.GetList()) do
        local class = weapon.ClassName
        table.insert(weaponChoices, class)
    end

    local dropdown2 = vgui.Create("DComboBox", dropdownPanel)
    dropdown2:SetPos(0, 0)
    dropdown2:SetSize(280, 30)
    for _, choice in ipairs(weaponChoices) do
        dropdown2:AddChoice(choice)
    end
    dropdown2:SetVisible(false)
    dropdown2:SetTextColor(Color(0, 0, 0, 255))
    dropdown2:SetValue("weapon_pistol")
    local ammoTypes = {}

    for _, ammo in pairs(game.GetAmmoTypes()) do
        table.insert(ammoTypes, ammo)
    end

    local ammoTypeDropdown = vgui.Create("DComboBox", dropdownPanel)
    ammoTypeDropdown:SetPos(0, 40)
    ammoTypeDropdown:SetSize(280, 30)
    for _, choice in ipairs(ammoTypes) do
        ammoTypeDropdown:AddChoice(choice)
    end
    ammoTypeDropdown:SetVisible(false)
    ammoTypeDropdown:SetValue("Pistol")

    -- Create Ammo slider
    local ammoSlider = vgui.Create("DNumSlider", dropdownPanel)
    ammoSlider:SetPos(3, 80)
    ammoSlider:SetSize(274, 30)  -- Adjusted size to fit the tool panel
    ammoSlider:SetText("Ammo Amount:")
    ammoSlider.Label:SetTextColor(Color(0,0,0,255))
    ammoSlider:SetMin(0)
    ammoSlider:SetMax(100)
    ammoSlider:SetDecimals(0)
    ammoSlider:SetVisible(false)
    ammoSlider:SetValue(54)

    -- Create Respawn Time slider
    local respawnSlider = vgui.Create("DNumSlider", dropdownPanel)
    respawnSlider:SetPos(3, 120)
    respawnSlider:SetSize(274, 30)  -- Adjusted size to fit the tool panel
    respawnSlider:SetText("Respawn Time:")
    respawnSlider.Label:SetTextColor(Color(0,0,0,255))
    respawnSlider:SetMin(1)
    respawnSlider:SetMax(60)
    respawnSlider:SetDecimals(0)
    respawnSlider:SetVisible(false)
    respawnSlider:SetValue(10)

    local NPCSpawns = {
        "Normal",
        "Large",
        "Huge",
        "Massive"
    }

    local dropdown3 = vgui.Create("DComboBox", dropdownPanel)
    dropdown3:SetPos(0, 0)
    dropdown3:SetSize(280, 30)
    for _, choice in ipairs(NPCSpawns) do
        dropdown3:AddChoice(choice)
    end
    dropdown3:SetVisible(false)
    dropdown3:SetTextColor(Color(0, 0, 0, 255))
    dropdown3:SetValue("Normal")
	
	local BossCheckbox = vgui.Create("DCheckBoxLabel", dropdownPanel)
    BossCheckbox:SetPos(0, 35)
    BossCheckbox:SetText("Boss Spawnpoint")
    BossCheckbox:SetVisible(false)
    BossCheckbox:SetChecked(false)

	-- Function to switch what's visible on the menu depending on the current category.
    local function UpdateVisibility()
        dropdown1:SetVisible(dropdownCategory:GetValue() == "Players")
		
        dropdown2:SetVisible(dropdownCategory:GetValue() == "Weapons")
		ammoTypeDropdown:SetVisible(dropdownCategory:GetValue() == "Weapons")
		ammoSlider:SetVisible(dropdownCategory:GetValue() == "Weapons")
		respawnSlider:SetVisible(dropdownCategory:GetValue() == "Weapons")
		
        dropdown3:SetVisible(dropdownCategory:GetValue() == "NPCs")
		BossCheckbox:SetVisible(dropdownCategory:GetValue() == "NPCs")
	end
	
	dropdownCategory.OnSelect = function(self,index,value)
		UpdateVisibility()
		
		local category = self:GetValue()
		
		LocalPlayer():ConCommand("gmc_weselector_tool_category " .. category)
		
		if category == "Players" then
			LocalPlayer():ConCommand("gmc_weselector_tool_type " .. dropdown1:GetValue())
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 " .. "None")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra2 " .. "None")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra3 " .. "None")
		elseif category == "Weapons" then
			LocalPlayer():ConCommand("gmc_weselector_tool_type " .. dropdown2:GetValue())
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 " .. ammoTypeDropdown:GetValue())
			LocalPlayer():ConCommand("gmc_weselector_tool_extra2 " .. ammoSlider:GetValue())
			LocalPlayer():ConCommand("gmc_weselector_tool_extra3 " .. respawnSlider:GetValue())
		elseif category == "NPCs" then
			LocalPlayer():ConCommand("gmc_weselector_tool_type " .. dropdown3:GetValue())
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 " .. tostring(BossCheckbox:GetChecked()))
			LocalPlayer():ConCommand("gmc_weselector_tool_extra2 " .. "None")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra3 " .. "None")
		end
	end
	
	dropdown1.OnSelect = function(self,index,value)
		LocalPlayer():ConCommand("gmc_weselector_tool_type " .. dropdown1:GetValue())
	end
	
	dropdown2.OnSelect = function(self,index,value)
		LocalPlayer():ConCommand("gmc_weselector_tool_type " .. dropdown2:GetValue())
		
		if dropdown2:GetValue() == "weapon_pistol" then
			ammoTypeDropdown:SetValue("Pistol")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 Pistol")
			ammoSlider:SetValue("54")
			respawnSlider:SetValue("10")
		end
		if dropdown2:GetValue() == "weapon_smg1" then
			ammoTypeDropdown:SetValue("SMG1")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 SMG1")
			ammoSlider:SetValue("90")
			respawnSlider:SetValue("10")
		end
		if dropdown2:GetValue() == "weapon_ar2" then
			ammoTypeDropdown:SetValue("AR2")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 AR2")
			ammoSlider:SetValue("30")
			respawnSlider:SetValue("20")
		end
		if dropdown2:GetValue() == "weapon_shotgun" then
			ammoTypeDropdown:SetValue("Buckshot")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 Buckshot")
			ammoSlider:SetValue("8")
			respawnSlider:SetValue("20")
		end
		if dropdown2:GetValue() == "weapon_grenade" then
			ammoTypeDropdown:SetValue("Grenade")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 Grenade")
			ammoSlider:SetValue("2")
			respawnSlider:SetValue("20")
		end
		if dropdown2:GetValue() == "weapon_357" then
			ammoTypeDropdown:SetValue("357")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 357")
			ammoSlider:SetValue("6")
			respawnSlider:SetValue("30")
		end
		if dropdown2:GetValue() == "weapon_crossbow" then
			ammoTypeDropdown:SetValue("XBowBolt")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 XBowBolt")
			ammoSlider:SetValue("4")
			respawnSlider:SetValue("30")
		end
		if dropdown2:GetValue() == "weapon_slam" then
			ammoTypeDropdown:SetValue("slam")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 slam")
			ammoSlider:SetValue("2")
			respawnSlider:SetValue("30")
		end
		if dropdown2:GetValue() == "weapon_rocket_launcher" then
			ammoTypeDropdown:SetValue("RPG_Round")
			LocalPlayer():ConCommand("gmc_weselector_tool_extra1 RPG Round")
			ammoSlider:SetValue("2")
			respawnSlider:SetValue("60")
		end
	end
	
	ammoTypeDropdown.OnSelect = function(self,index,value)
		LocalPlayer():ConCommand("gmc_weselector_tool_extra1 " .. tostring(ammoTypeDropdown:GetValue()))
	end
	
	ammoSlider.OnValueChanged = function(self,index,value)
		LocalPlayer():ConCommand("gmc_weselector_tool_extra2 " .. ammoSlider:GetValue())
	end
	
	respawnSlider.OnValueChanged = function(self,index,value)
		LocalPlayer():ConCommand("gmc_weselector_tool_extra3 " .. respawnSlider:GetValue())
	end
	
	dropdown3.OnSelect = function(self,index,value)
		LocalPlayer():ConCommand("gmc_weselector_tool_type " .. dropdown3:GetValue())
	end
	
	BossCheckbox.OnChange = function(self)
        LocalPlayer():ConCommand("gmc_weselector_tool_extra1 " .. tostring(BossCheckbox:GetChecked()))
    end
end

function TOOL:LeftClick(trace)
	if SERVER then
		local ply = self:GetOwner()
		local ent = ents.Create("gmc_weselector")
		if not IsValid(ent) then
			print("Failed to create the entity.")
			return false
		end
			
		local spawnCategory = self:GetClientInfo("category")
		local spawnType = self:GetClientInfo("type")
		local extraOption1 = self:GetClientInfo("extra1")
		local extraOption2 = self:GetClientInfo("extra2")
		local extraOption3 = self:GetClientInfo("extra3")
			
		ent:SetNWString("SpawnCategory", spawnCategory)
		ent:SetNWString("SpawnType", spawnType)
		ent:SetNWString("ExtraOption1", extraOption1)
		ent:SetNWString("ExtraOption2", extraOption2)
		ent:SetNWString("ExtraOption3", extraOption3)

		ent:SetPos(trace.HitPos)
		ent:SetAngles(Angle(0, ply:LocalEyeAngles().y + 180, 0))
		ent:Spawn()

		undo.Create("GMC Selector")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
		undo.Finish()

		ply:AddCleanup("gmc_selectors", ent)

		return true
	end
end