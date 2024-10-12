local MCNPCMenu = nil;

local archivedNPCDropdown
local npcSelectorDropdown
local npcSelectorTextEntry
local npcNameTextEntry
local npcScaleTextEntry
local npcColorPicker
local npcSpawnWeightTextEntry
local npcSkinTextEntry
local npcBodygroupTextEntry
local npcBaseHealthTextEntry
local npcHealthPerLevelTextEntry
local npcBaseDamageTextEntry
local npcDamagePerLevelTextEntry
local npcWeaponComboBox
local npcBaseExpTextEntry
local npcExpPerLevelTextEntry
local npcBossCheckbox
local npcMinionCheckbox
local npcLargeCheckbox
local npcHugeCheckbox
local npcMassiveCheckbox

local archivedNPCs = {}

RunConsoleCommand("gmc_updatenpcs")

function NPCMenu()
	if LocalPlayer():IsSuperAdmin() then
		MCNPCMenu = vgui.Create("DFrame")
		MCNPCMenu:SetSize(ScrW()/2, ScrH()/1.53)
		MCNPCMenu:Center()
		MCNPCMenu:SetTitle("Garry's Modular Combat - NPC Creator")
		MCNPCMenu:SetDraggable(true)
		MCNPCMenu:ShowCloseButton(true)
		MCNPCMenu:SetDeleteOnClose(false)
		MCNPCMenu:MakePopup(true)
		
		MCNPCMenu.Paint = function()
			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawRect(0, 0, MCNPCMenu:GetWide(), MCNPCMenu:GetTall())

			surface.SetDrawColor(230,207,40,255)
			surface.DrawRect(0, MCNPCMenu:GetTall()/30, MCNPCMenu:GetWide(), 1)
			surface.DrawRect(MCNPCMenu:GetWide()/3.2, MCNPCMenu:GetTall()/30, 1, MCNPCMenu:GetTall())
			
		end
		
		RunConsoleCommand("gmc_updatenpcs")
		NPCMcreateNPCCreator()
	else
		print("====SUPERADMINS ONLY!=====")
		print("This command is reserved to superadmins, otherwise any player could just add NPCs any time they wanted.")
		print("If you are supposed to be a superadmin, contact the server owner.")
		print("If you are the server owner, stop having a skill issue and fix your server.")
	end
end
concommand.Add("gmc_npccreator", NPCMenu)

if CLIENT then
	net.Receive("SendArchivedNPCs", function()
		archivedNPCs = net.ReadTable()
	end)
end

function NPCMcreateNPCCreator()
	local wide = MCNPCMenu:GetWide() -- 960 on 1920x1080
	local tall = MCNPCMenu:GetTall() -- 830 on 1920x1080
	local align = wide/106.6
	
	local archivedNPCDropdownLabel = vgui.Create("DLabel", MCNPCMenu)
	archivedNPCDropdownLabel:SetText("Load NPC:")
	archivedNPCDropdownLabel:SetPos(align, 30)
	archivedNPCDropdownLabel:SizeToContents()
	archivedNPCDropdownLabel:SetTextColor(Color(230,207,40,255))
	
	archivedNPCDropdown = vgui.Create("DComboBox", MCNPCMenu)
	archivedNPCDropdown:SetPos(align, 50)
	archivedNPCDropdown:SetSize(200, 20)
	
	for _, anpc in pairs(archivedNPCs) do
		archivedNPCDropdown:AddChoice(anpc.name)
	end
	
	-- First Button (Positioned after the dropdown, within 300px limit)
	local loadButton = vgui.Create("DButton", MCNPCMenu)
	loadButton:SetText("Load")
	loadButton:SetPos(210, 50)
	loadButton:SetSize(40, 20)
	
	loadButton.DoClick = function()
		local selectedNPC = archivedNPCDropdown:GetSelected() -- Get the selected NPC from the dropdown
		if not selectedNPC then return end -- Exit if no NPC is selected

		for _, anpc in pairs(archivedNPCs) do
			if anpc.name == selectedNPC then
				-- Set the Text Entries
				npcSelectorTextEntry:SetText(anpc.class)
				npcNameTextEntry:SetText(anpc.name)
				npcScaleTextEntry:SetText(anpc.scale)
				npcSpawnWeightTextEntry:SetText(anpc.weight)
				npcSkinTextEntry:SetText(anpc.skin)
				npcBodygroupTextEntry:SetText(anpc.bodygroups)
				npcBaseHealthTextEntry:SetText(anpc.basehealth)
				npcHealthPerLevelTextEntry:SetText(anpc.healthlvl)
				npcBaseDamageTextEntry:SetText(anpc.basedamage)
				npcDamagePerLevelTextEntry:SetText(anpc.damagelvl)
				npcWeaponComboBox:SetValue(anpc.weapon)
				npcBaseExpTextEntry:SetText(anpc.baseexp)
				npcExpPerLevelTextEntry:SetText(anpc.explvl)

				-- Set the Color Picker
				npcColorPicker:SetColor(Color(anpc.color.red, anpc.color.green, anpc.color.blue, anpc.color.alpha))

				-- Set the Checkboxes
				npcBossCheckbox:SetChecked(tobool(anpc.isboss))
				npcLargeCheckbox:SetChecked(tobool(anpc.islarge))
				npcMinionCheckbox:SetChecked(tobool(anpc.isminion))
				npcHugeCheckbox:SetChecked(tobool(anpc.ishuge))
				npcMassiveCheckbox:SetChecked(tobool(anpc.ismassive))

				break -- Exit loop once the matching NPC is found and loaded
			end
		end
	end

	-- Second Button (Positioned after the first button, within 300px limit)
	local deleteButton = vgui.Create("DButton", MCNPCMenu)
	deleteButton:SetText("Delete")
	deleteButton:SetPos(250, 50)
	deleteButton:SetSize(40, 20)
	
	deleteButton.DoClick = function()
		for _, anpc in pairs(archivedNPCs) do
			if anpc.name == archivedNPCDropdown:GetSelected() then
				archivedNPCDropdown:RemoveChoice(_)
				net.Start("DeleteArchivedNPC")
					net.WriteTable(anpc)
				net.SendToServer()
			end
			archivedNPCDropdown:SetValue("")
		end
	end

	local npcSelectorLabel = vgui.Create("DLabel", MCNPCMenu)
	npcSelectorLabel:SetText("NPC Class:")
	npcSelectorLabel:SetPos(align, 70)
	npcSelectorLabel:SizeToContents()
	npcSelectorLabel:SetTextColor(Color(230,207,40,255))

	npcSelectorDropdown = vgui.Create("DComboBox", MCNPCMenu)
	npcSelectorDropdown:SetPos(align, 90)
	npcSelectorDropdown:SetSize(280, 20)

	-- Populate the dropdown with available NPC classes
	local npcClasses = list.Get("NPC")
	for class, _ in pairs(npcClasses) do
		npcSelectorDropdown:AddChoice(class)
	end

	-- Make a Text Entry to allow custom entities to be spawned.
	npcSelectorTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcSelectorTextEntry:SetPos(align, 90)
	npcSelectorTextEntry:SetSize(260, 20)

	-- Create a TextEntry for NPC Name
	local npcNameLabel = vgui.Create("DLabel", MCNPCMenu)
	npcNameLabel:SetText("NPC Name:")
	npcNameLabel:SetPos(align, 115)
	npcNameLabel:SizeToContents()
	npcNameLabel:SetTextColor(Color(230,207,40,255))

	npcNameTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcNameTextEntry:SetPos(align, 130)
	npcNameTextEntry:SetSize(280, 20)

	-- Create a TextEntry for NPC Scale
	local npcScaleLabel = vgui.Create("DLabel", MCNPCMenu)
	npcScaleLabel:SetText("NPC Scale:")
	npcScaleLabel:SetPos(align, 155)
	npcScaleLabel:SizeToContents()
	npcScaleLabel:SetTextColor(Color(230,207,40,255))

	npcScaleTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcScaleTextEntry:SetPos(align, 170)
	npcScaleTextEntry:SetSize(40, 20)
	npcScaleTextEntry:SetText("1")
	
	-- Create Checkboxes for Boss and Minion
	npcBossCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcBossCheckbox:SetText("Boss")
	npcBossCheckbox:SetPos(190, 160)
	npcBossCheckbox:SizeToContents()
	npcBossCheckbox:SetTextColor(Color(230,207,40,255))
	
	npcMinionCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcMinionCheckbox:SetText("Minion")
	npcMinionCheckbox:SetPos(190, 185)
	npcMinionCheckbox:SizeToContents()
	npcMinionCheckbox:SetTextColor(Color(230,207,40,255))

	-- Create a TextEntry for NPC Color
	local npcColorLabel = vgui.Create("DLabel", MCNPCMenu)
	npcColorLabel:SetText("NPC Color:")
	npcColorLabel:SetPos(align, 195)
	npcColorLabel:SizeToContents()
	npcColorLabel:SetTextColor(Color(230,207,40,255))

	npcColorPicker = vgui.Create("DColorMixer", MCNPCMenu)
	npcColorPicker:SetPos(align, 210)
	npcColorPicker:SetSize(200, 200)
	npcColorPicker:SetPalette(true) -- Display palette on the right side

	-- Create a TextEntry for NPC Spawn Weight
	local npcSpawnWeightLabel = vgui.Create("DLabel", MCNPCMenu)
	npcSpawnWeightLabel:SetText("NPC Spawn Weight:")
	npcSpawnWeightLabel:SetPos(wide/13.325, 155)
	npcSpawnWeightLabel:SizeToContents()
	npcSpawnWeightLabel:SetTextColor(Color(230,207,40,255))

	npcSpawnWeightTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcSpawnWeightTextEntry:SetPos(wide/13.325, 170)
	npcSpawnWeightTextEntry:SetSize(40, 20)
	npcSpawnWeightTextEntry:SetText("1")

	-- Create a TextEntry for NPC Skin
	local npcSkinLabel = vgui.Create("DLabel", MCNPCMenu)
	npcSkinLabel:SetText("NPC Skin:")
	npcSkinLabel:SetPos(align, 425)
	npcSkinLabel:SizeToContents()
	npcSkinLabel:SetTextColor(Color(230,207,40,255))

	npcSkinTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcSkinTextEntry:SetPos(75, 420)
	npcSkinTextEntry:SetSize(60, 20)

	-- Create a TextEntry for Bodygroups
	local npcBodygroupLabel = vgui.Create("DLabel", MCNPCMenu)
	npcBodygroupLabel:SetText("Bodygroups:")
	npcBodygroupLabel:SetPos(align, 450)
	npcBodygroupLabel:SizeToContents()
	npcBodygroupLabel:SetTextColor(Color(230,207,40,255))

	npcBodygroupTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBodygroupTextEntry:SetPos(75, 445)
	npcBodygroupTextEntry:SetSize(60, 20)

	-- Create TextEntries for NPC Health
	local npcHealthLabel = vgui.Create("DLabel", MCNPCMenu)
	npcHealthLabel:SetText("Health Configuration:")
	npcHealthLabel:SetPos(align, 475)
	npcHealthLabel:SizeToContents()
	npcHealthLabel:SetTextColor(Color(230,207,40,255))

	local npcBaseHealthLabel = vgui.Create("DLabel", MCNPCMenu)
	npcBaseHealthLabel:SetText("Base:")
	npcBaseHealthLabel:SetPos(align, 500)
	npcBaseHealthLabel:SizeToContents()
	npcBaseHealthLabel:SetTextColor(Color(230,207,40,255))

	npcBaseHealthTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBaseHealthTextEntry:SetPos(60, 495)
	npcBaseHealthTextEntry:SetSize(50, 20)

	local npcHealthPerLevelLabel = vgui.Create("DLabel", MCNPCMenu)
	npcHealthPerLevelLabel:SetText("Per Level:")
	npcHealthPerLevelLabel:SetPos(align, 525)
	npcHealthPerLevelLabel:SizeToContents()
	npcHealthPerLevelLabel:SetTextColor(Color(230,207,40,255))

	npcHealthPerLevelTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcHealthPerLevelTextEntry:SetPos(60, 520)
	npcHealthPerLevelTextEntry:SetSize(50, 20)

	-- Create TextEntries for NPC Damage
	local npcDamageLabel = vgui.Create("DLabel", MCNPCMenu)
	npcDamageLabel:SetText("Damage Multiplier:")
	npcDamageLabel:SetPos(120, 475)
	npcDamageLabel:SizeToContents()
	npcDamageLabel:SetTextColor(Color(230,207,40,255))

	local npcBaseDamageLabel = vgui.Create("DLabel", MCNPCMenu)
	npcBaseDamageLabel:SetText("Base:")
	npcBaseDamageLabel:SetPos(120, 500)
	npcBaseDamageLabel:SizeToContents()
	npcBaseDamageLabel:SetTextColor(Color(230,207,40,255))

	npcBaseDamageTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBaseDamageTextEntry:SetPos(180, 495)
	npcBaseDamageTextEntry:SetSize(50, 20)

	local npcDamagePerLevelLabel = vgui.Create("DLabel", MCNPCMenu)
	npcDamagePerLevelLabel:SetText("Per Level:")
	npcDamagePerLevelLabel:SetPos(120, 525)
	npcDamagePerLevelLabel:SizeToContents()
	npcDamagePerLevelLabel:SetTextColor(Color(230,207,40,255))

	npcDamagePerLevelTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcDamagePerLevelTextEntry:SetPos(180, 520)
	npcDamagePerLevelTextEntry:SetSize(50, 20)

	-- Create a ComboBox for Weapon Configuration
	local npcWeaponLabel = vgui.Create("DLabel", MCNPCMenu)
	npcWeaponLabel:SetText("Weapon Configuration:")
	npcWeaponLabel:SetPos(align, 550)
	npcWeaponLabel:SizeToContents()
	npcWeaponLabel:SetTextColor(Color(230,207,40,255))

	npcWeaponComboBox = vgui.Create("DComboBox", MCNPCMenu)
	npcWeaponComboBox:SetPos(align, 570)
	npcWeaponComboBox:SetSize(280, 20)

	-- Populate the weapon ComboBox with available weapons
	npcWeaponComboBox:AddChoice("None")
	for _, weaponClass in pairs(list.Get("Weapon")) do
		npcWeaponComboBox:AddChoice(weaponClass.ClassName)
	end

	local npcExpLabel = vgui.Create("DLabel", MCNPCMenu)
	npcExpLabel:SetText("EXP Configuration:")
	npcExpLabel:SetPos(align, 595)
	npcExpLabel:SizeToContents()
	npcExpLabel:SetTextColor(Color(230,207,40,255))

	local npcBaseExpLabel = vgui.Create("DLabel", MCNPCMenu)
	npcBaseExpLabel:SetText("Base:")
	npcBaseExpLabel:SetPos(align, 620)
	npcBaseExpLabel:SizeToContents()
	npcBaseExpLabel:SetTextColor(Color(230,207,40,255))

	npcBaseExpTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBaseExpTextEntry:SetPos(60, 615)
	npcBaseExpTextEntry:SetSize(50, 20)

	local npcExpPerLevelLabel = vgui.Create("DLabel", MCNPCMenu)
	npcExpPerLevelLabel:SetText("Per Level:")
	npcExpPerLevelLabel:SetPos(align, 645)
	npcExpPerLevelLabel:SizeToContents()
	npcExpPerLevelLabel:SetTextColor(Color(230,207,40,255))

	npcExpPerLevelTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcExpPerLevelTextEntry:SetPos(60, 640)
	npcExpPerLevelTextEntry:SetSize(50, 20)
	
	-- NPC Size Checkboxes
	
	npcLargeCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcLargeCheckbox:SetText("Large")
	npcLargeCheckbox:SetPos(130, 595)
	npcLargeCheckbox:SizeToContents()
	npcLargeCheckbox:SetTextColor(Color(230,207,40,255))
	
	npcHugeCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcHugeCheckbox:SetText("Huge")
	npcHugeCheckbox:SetPos(130, 620)
	npcHugeCheckbox:SizeToContents()
	npcHugeCheckbox:SetTextColor(Color(230,207,40,255))
	
	npcMassiveCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcMassiveCheckbox:SetText("Massive")
	npcMassiveCheckbox:SetPos(130, 645)
	npcMassiveCheckbox:SizeToContents()
	npcMassiveCheckbox:SetTextColor(Color(230,207,40,255))
	
	-- Add a "Save Configuration" button
	local saveButton = vgui.Create("DButton", MCNPCMenu)
	saveButton:SetText("Save Spawn Data")
	saveButton:SetPos(10, 670)
	saveButton:SetSize(280, 30)
	saveButton.DoClick = function()
		SaveNPCConfigurationToFile(
			npcSelectorTextEntry,
			npcNameTextEntry,
			npcScaleTextEntry,
			npcColorPicker,
			npcSpawnWeightTextEntry,
			npcSkinTextEntry,
			npcBodygroupTextEntry,
			npcBaseHealthTextEntry,
			npcHealthPerLevelTextEntry,
			npcBaseDamageTextEntry,
			npcDamagePerLevelTextEntry,
			npcWeaponComboBox,
			npcBaseExpTextEntry,
			npcExpPerLevelTextEntry,
			npcBossCheckbox,
			npcMinionCheckbox,
			npcLargeCheckbox,
			npcHugeCheckbox,
			npcMassiveCheckbox,
			archivedNPCDropdown
		)
	end

	-- Callback for when an NPC class is selected
	npcSelectorDropdown.OnSelect = function(self, index, value, data)
		local selectedNPCClass = value
		archivedNPCDropdown:SetValue("") -- Clear the Archived NPC entry when an npc class is selected
		npcSelectorTextEntry:SetText(tostring(selectedNPCClass))
		npcNameTextEntry:SetText("") -- Clear the text entry when selecting a new NPC class
		npcScaleTextEntry:SetText("1") -- Clear the text entry when selecting a new NPC class
		npcColorPicker:SetColor(Color(255, 255, 255)) -- Reset color picker when selecting a new NPC class
		npcSpawnWeightTextEntry:SetText("5") -- Reset the text entry when selecting a new NPC class
		npcSkinTextEntry:SetText("") -- Clear the text entry when selecting a new NPC class
		npcBodygroupTextEntry:SetText("") -- Clear the text entry for bodygroups
		npcBaseHealthTextEntry:SetText("50") -- Clear the text entry when selecting a new NPC class
		npcHealthPerLevelTextEntry:SetText("5") -- Clear the text entry for health per level
		npcBaseDamageTextEntry:SetText("1") -- Clear the text entry when selecting a new NPC class
		npcDamagePerLevelTextEntry:SetText("0") -- Clear the text entry for damage per level
		npcWeaponComboBox:Clear() -- Clear the weapon ComboBox when selecting a new NPC class
		npcBaseExpTextEntry:SetText("10") -- Clear the text entry when selecting a new NPC class
		npcExpPerLevelTextEntry:SetText("1") -- Clear the text entry for EXP per level
		npcBossCheckbox:SetValue(false) -- Clear the boss checkbox
		npcLargeCheckbox:SetValue(false) -- Clear the large NPC checkbox
		npcHugeCheckbox:SetValue(false) -- Clear the large NPC checkbox
		npcMassiveCheckbox:SetValue(false) -- Clear the large NPC checkbox
		npcMinionCheckbox:SetValue(false) -- Clear the minion checkbox
		for _, weaponClass in pairs(list.Get("Weapon")) do
			npcWeaponComboBox:AddChoice(weaponClass.ClassName)
		end
	end
	
	-- Callback for when size checkboxes are changed
	function npcLargeCheckbox:OnChange(value)
		npcHugeCheckbox:SetChecked(false)
		npcMassiveCheckbox:SetChecked(false)
	end
	
	function npcHugeCheckbox:OnChange(value)
		npcMassiveCheckbox:SetChecked(false)
		npcLargeCheckbox:SetChecked(false)
	end
	
	function npcMassiveCheckbox:OnChange(value)
		npcHugeCheckbox:SetChecked(false)
		npcLargeCheckbox:SetChecked(false)
	end
end

-- Callback for saving NPC configuration to a file
function SaveNPCConfigurationToFile(npcSelectorTextEntry, npcNameTextEntry, npcScaleTextEntry, npcColorPicker, npcSpawnWeightTextEntry, npcSkinTextEntry, npcBodygroupTextEntry, npcBaseHealthTextEntry, npcHealthPerLevelTextEntry, npcBaseDamageTextEntry, npcDamagePerLevelTextEntry, npcWeaponComboBox, npcBaseExpTextEntry, npcExpPerLevelTextEntry, npcBossCheckbox, npcMinionCheckbox, npcLargeCheckbox, npcHugeCheckbox, npcMassiveCheckbox, archivedNPCDropdown)
    local npcName = npcNameTextEntry:GetValue()
	local folderName = "gmc/npcs"
    local filename = folderName .. "/" .. npcName .. ".json"
    local fileContent = ""

	local npcData = {
        ["class"] = npcSelectorTextEntry:GetValue(),
        ["name"] = npcNameTextEntry:GetValue(),
        ["scale"] = npcScaleTextEntry:GetValue(),
        ["color"] = {
			["red"] = npcColorPicker:GetColor().r,
			["green"] = npcColorPicker:GetColor().g, 
			["blue"] = npcColorPicker:GetColor().b,
			["alpha"] = npcColorPicker:GetColor().a,
		},
        ["weight"] = npcSpawnWeightTextEntry:GetValue(),
        ["skin"] = npcSkinTextEntry:GetValue(),
        ["bodygroups"] = npcBodygroupTextEntry:GetValue(),
        ["basehealth"] = npcBaseHealthTextEntry:GetValue(),
        ["healthlvl"] = npcHealthPerLevelTextEntry:GetValue(),
        ["basedamage"] = npcBaseDamageTextEntry:GetValue(),
        ["damagelvl"] = npcDamagePerLevelTextEntry:GetValue(),
        ["weapon"] = npcWeaponComboBox:GetSelected() or "None",
        ["baseexp"] = npcBaseExpTextEntry:GetValue(),
        ["explvl"] = npcExpPerLevelTextEntry:GetValue(),
        ["isboss"] = tostring(npcBossCheckbox:GetChecked()),
        ["islarge"] = tostring(npcLargeCheckbox:GetChecked()),
        ["isminion"] = tostring(npcMinionCheckbox:GetChecked()),
		["ishuge"] = tostring(npcHugeCheckbox:GetChecked()),
		["ismassive"] = tostring(npcMassiveCheckbox:GetChecked())
    }
	
	net.Start("ReceiveArchivedNPC")
		net.WriteTable(npcData)
	net.SendToServer()
	
	 -- Check if the NPC already exists in the table
    local found = false
    for k, anpc in pairs(archivedNPCs) do
        if anpc.name == npcData.name then
            archivedNPCs[k] = npcData  -- Overwrite existing NPC data
            found = true
            break
        end
    end
    
    -- If the NPC was not found, insert it as a new entry
    if not found then
        table.insert(archivedNPCs, npcData)
    end
	
	archivedNPCDropdown:Clear()
	for _, anpc in pairs(archivedNPCs) do
		archivedNPCDropdown:AddChoice(anpc.name)
	end
	
    print("NPC Configuration saved to file:", filename)
	print(table.ToString( npcData, npcData.name, true ))
end