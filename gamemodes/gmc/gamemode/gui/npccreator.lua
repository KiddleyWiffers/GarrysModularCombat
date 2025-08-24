local MCNPCMenu = nil;

local archivedNPCDropdown
local npcClass = ""
local npcName = ""
local npcColor = (Color(255, 255, 255))
local npcSkin = -1
local npcBodyGroups = ""
local npcStats = {scale = 1, weight = 5, hp = 50, lvlhp = 5, damage = 1, lvldamage = 0, exp = 10, lvlexp = 1}
local npcWeapon = "None"
local npcType = "Default"
local npcSize = "Normal"
local npcMultipliers = {
	["All"] = {order = 1, value = 1, tooltip = "Multiplies the damage this NPC receives from all sources."},
	["Bullet"] = {order = 2, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT"}, -- DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT
	["Explosion"] = {order = 3, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_BLAST, DMG_BLAST_SURFACE, DMG_ALWAYS_GIB"}, -- DMG_BLAST, DMG_BLAST_SURFACE, DMG_ALWAYS_GIB
	["Sharp"] = {order = 4, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_SLASH, DMG_NEVERGIB"}, -- DMG_SLASH, DMG_NEVERGIB
	["Blunt"] = {order = 5, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_CLUB"}, -- DMG_CLUB
	["Acid"] = {order = 6, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_ACID"}, -- DMG_ACID
	["Energy"] = {order = 7, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_ENERGYBEAM, DMG_DISSOLVE"}, -- DMG_ENERGYBEAM, DMG_DISSOLVE
	["Fire"] = {order = 8, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_BURN, DMG_SLOWBURN"}, -- DMG_BURN, DMG_SLOWBURN
	["Phys"] = {order = 9, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_CRUSH, DMG_VEHICLE"}, -- DMG_CRUSH, DMG_VEHICLE
	["Physgun"] = {order = 10, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_PHYSGUN (The gravity gun, not the props it throws)"}, -- DMG_PHYSGUN
	["Plasma"] = {order = 11, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_PLASMA"}, -- DMG_PLASMA
	["Poison"] = {order = 12, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_POISON, DMG_PARALYZE, DMG_NERVEGAS"}, -- DMG_POISON, DMG_PARALYZE, DMG_NERVEGAS
	["Radiation"] = {order = 13, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_RADIATION"}, -- DMG_RADIATION
	["Sonic"] = {order = 14, value = 1, tooltip = "Multiplies the damage this NPC receives from DMG_SONIC"} -- DMG_SONIC
}
local npcDamageMultipliers = {}
local npcSpawnConditions = {
	["Outside"] = false,
	["Inside"] = false,
	["Roof"] = false,
	["Underwater"] = false
}

local archivedNPCs = {}

hook.Add("InitPostEntity", "archiveNPCsOnSpawn", function()
	RunConsoleCommand("gmc_updatenpcs")
end)

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
			surface.DrawRect(MCNPCMenu:GetWide()/2.2, MCNPCMenu:GetTall()/30, 1, MCNPCMenu:GetTall())
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
	archivedNPCDropdown:SetTooltip("Pick a created NPC to delete or load.")
	
	for _, anpc in pairs(archivedNPCs) do
		archivedNPCDropdown:AddChoice(anpc.name)
	end
	
	-- First Button (Positioned after the dropdown, within 300px limit)
	local loadButton = vgui.Create("DButton", MCNPCMenu)
	loadButton:SetText("Load")
	loadButton:SetPos(210, 50)
	loadButton:SetSize(40, 20)

	-- Second Button (Positioned after the first button, within 300px limit)
	local deleteButton = vgui.Create("DButton", MCNPCMenu)
	deleteButton:SetText("Delete")
	deleteButton:SetPos(250, 50)
	deleteButton:SetSize(40, 20)

	local npcSelectorLabel = vgui.Create("DLabel", MCNPCMenu)
	npcSelectorLabel:SetText("NPC Class:")
	npcSelectorLabel:SetPos(align, 70)
	npcSelectorLabel:SizeToContents()
	npcSelectorLabel:SetTextColor(Color(230,207,40,255))

	local npcSelectorDropdown = vgui.Create("DComboBox", MCNPCMenu)
	npcSelectorDropdown:SetPos(align, 90)
	npcSelectorDropdown:SetSize(280, 20)
	npcSelectorDropdown:SetTooltip("Pick a NPC from the NPC list.")

	-- Populate the dropdown with available NPC classes
	local npcClasses = list.Get("NPC")
	for class, _ in pairs(npcClasses) do
		npcSelectorDropdown:AddChoice(class)
	end

	-- Make a Text Entry to allow custom entities to be spawned.
	local npcSelectorTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcSelectorTextEntry:SetPos(align, 90)
	npcSelectorTextEntry:SetSize(260, 20)
	npcSelectorTextEntry:SetTooltip("The class name of the NPC you are trying to spawn.")

	-- Create a TextEntry for NPC Name
	local npcNameLabel = vgui.Create("DLabel", MCNPCMenu)
	npcNameLabel:SetText("NPC Name:")
	npcNameLabel:SetPos(align, 115)
	npcNameLabel:SizeToContents()
	npcNameLabel:SetTextColor(Color(230,207,40,255))

	local npcNameTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcNameTextEntry:SetPos(align, 130)
	npcNameTextEntry:SetSize(280, 20)
	npcNameTextEntry:SetTooltip("The print name of the NPC, this will be displayed on the HUD.")

	-- Create a TextEntry for NPC Scale
	local npcScaleLabel = vgui.Create("DLabel", MCNPCMenu)
	npcScaleLabel:SetText("NPC Scale:")
	npcScaleLabel:SetPos(align, 155)
	npcScaleLabel:SizeToContents()
	npcScaleLabel:SetTextColor(Color(230,207,40,255))

	local npcScaleTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcScaleTextEntry:SetPos(align, 170)
	npcScaleTextEntry:SetSize(40, 20)
	npcScaleTextEntry:SetText("1")
	npcScaleTextEntry:SetTooltip("Multiply the size of the NPC by this amount.")
	
	-- Create Checkboxes for Boss and Minion
	local npcBossCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcBossCheckbox:SetText("Boss")
	npcBossCheckbox:SetPos(140, 160)
	npcBossCheckbox:SizeToContents()
	npcBossCheckbox:SetTextColor(Color(230,207,40,255))
	npcBossCheckbox:SetTooltip("Whether or not the NPC is a boss.")
	
	local npcMinionCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcMinionCheckbox:SetText("Minion")
	npcMinionCheckbox:SetPos(140, 185)
	npcMinionCheckbox:SizeToContents()
	npcMinionCheckbox:SetTextColor(Color(230,207,40,255))
	npcMinionCheckbox:SetTooltip("Whether or not this NPC should show up as a minion module. Minions also don't count towards total NPC count.")
	
	local npcBonusCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcBonusCheckbox:SetText("Bonus")
	npcBonusCheckbox:SetPos(210, 185)
	npcBonusCheckbox:SizeToContents()
	npcBonusCheckbox:SetTextColor(Color(230,207,40,255))
	npcBonusCheckbox:SetTooltip("Whether or not this is a bonus NPC. Bonus NPCs don't count towards the NPC limit.")

	-- Create a TextEntry for NPC Color
	local npcColorLabel = vgui.Create("DLabel", MCNPCMenu)
	npcColorLabel:SetText("NPC Color:")
	npcColorLabel:SetPos(align, 195)
	npcColorLabel:SizeToContents()
	npcColorLabel:SetTextColor(Color(230,207,40,255))

	local npcColorPicker = vgui.Create("DColorMixer", MCNPCMenu)
	npcColorPicker:SetPos(align, 210)
	npcColorPicker:SetSize(200, 200)
	npcColorPicker:SetPalette(true) -- Display palette on the right side
	npcColorPicker:SetTooltip("What color to paint the NPC upon spawning.")

	-- Create a TextEntry for NPC Spawn Weight
	local npcSpawnWeightLabel = vgui.Create("DLabel", MCNPCMenu)
	npcSpawnWeightLabel:SetText("NPC Weight:")
	npcSpawnWeightLabel:SetPos(wide/13.325, 155)
	npcSpawnWeightLabel:SizeToContents()
	npcSpawnWeightLabel:SetTextColor(Color(230,207,40,255))

	local npcSpawnWeightTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcSpawnWeightTextEntry:SetPos(wide/13.325, 170)
	npcSpawnWeightTextEntry:SetSize(40, 20)
	npcSpawnWeightTextEntry:SetText("1")
	npcSpawnWeightTextEntry:SetTooltip("How likely the NPC is to spawn. The higher this number, the more likely it is to spawn.")

	-- Create a TextEntry for NPC Skin
	local npcSkinLabel = vgui.Create("DLabel", MCNPCMenu)
	npcSkinLabel:SetText("NPC Skin:")
	npcSkinLabel:SetPos(align, 425)
	npcSkinLabel:SizeToContents()
	npcSkinLabel:SetTextColor(Color(230,207,40,255))

	local npcSkinTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcSkinTextEntry:SetPos(75, 420)
	npcSkinTextEntry:SetSize(60, 20)
	npcSkinTextEntry:SetNumeric(true)
	npcSkinTextEntry:SetTooltip("Which skin the NPC should use, leave blank for default skin.")

	-- Create a TextEntry for Bodygroups
	local npcBodygroupLabel = vgui.Create("DLabel", MCNPCMenu)
	npcBodygroupLabel:SetText("Bodygroups:")
	npcBodygroupLabel:SetPos(align, 450)
	npcBodygroupLabel:SizeToContents()
	npcBodygroupLabel:SetTextColor(Color(230,207,40,255))

	local npcBodygroupTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBodygroupTextEntry:SetPos(75, 445)
	npcBodygroupTextEntry:SetSize(60, 20)
	npcBodygroupTextEntry:SetNumeric(true)
	npcBodygroupTextEntry:SetTooltip("What should we set this NPCs bodygroups to? This uses the SetBodyGroups function, and works the same as that. (Look it up on the Gmod Wiki)")

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

	local npcBaseHealthTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBaseHealthTextEntry:SetPos(60, 495)
	npcBaseHealthTextEntry:SetSize(50, 20)
	npcBaseHealthTextEntry:SetNumeric(true)
	npcBaseHealthTextEntry:SetTooltip("This is the base health the NPC will spawn with.")

	local npcHealthPerLevelLabel = vgui.Create("DLabel", MCNPCMenu)
	npcHealthPerLevelLabel:SetText("Per Level:")
	npcHealthPerLevelLabel:SetPos(align, 525)
	npcHealthPerLevelLabel:SizeToContents()
	npcHealthPerLevelLabel:SetTextColor(Color(230,207,40,255))

	local npcHealthPerLevelTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcHealthPerLevelTextEntry:SetPos(60, 520)
	npcHealthPerLevelTextEntry:SetSize(50, 20)
	npcHealthPerLevelTextEntry:SetTooltip("This will be multiplied by the NPCs level and added to it's base health.")

	-- Create TextEntries for NPC Damage
	local npcDamageLabel = vgui.Create("DLabel", MCNPCMenu)
	npcDamageLabel:SetText("Damage Configuration:")
	npcDamageLabel:SetPos(120, 475)
	npcDamageLabel:SizeToContents()
	npcDamageLabel:SetTextColor(Color(230,207,40,255))

	local npcBaseDamageLabel = vgui.Create("DLabel", MCNPCMenu)
	npcBaseDamageLabel:SetText("Base:")
	npcBaseDamageLabel:SetPos(120, 500)
	npcBaseDamageLabel:SizeToContents()
	npcBaseDamageLabel:SetTextColor(Color(230,207,40,255))

	local npcBaseDamageTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBaseDamageTextEntry:SetPos(180, 495)
	npcBaseDamageTextEntry:SetSize(50, 20)
	npcBaseDamageTextEntry:SetTooltip("This will be the NPCs default damage multiplier, this will make NPCs do more or less damage. If unsure, leave on 1 for default NPC behavior.")

	local npcDamagePerLevelLabel = vgui.Create("DLabel", MCNPCMenu)
	npcDamagePerLevelLabel:SetText("Per Level:")
	npcDamagePerLevelLabel:SetPos(120, 525)
	npcDamagePerLevelLabel:SizeToContents()
	npcDamagePerLevelLabel:SetTextColor(Color(230,207,40,255))

	local npcDamagePerLevelTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcDamagePerLevelTextEntry:SetPos(180, 520)
	npcDamagePerLevelTextEntry:SetSize(50, 20)
	npcDamagePerLevelTextEntry:SetTooltip("This will be the NPCs added to the NPCs damage multiplier every level, this will make NPCs do more or less damage. If unsure, leave on 0 for default NPC behavior.")

	-- Create a ComboBox for Weapon Configuration
	local npcWeaponLabel = vgui.Create("DLabel", MCNPCMenu)
	npcWeaponLabel:SetText("Weapon Configuration:")
	npcWeaponLabel:SetPos(align, 550)
	npcWeaponLabel:SizeToContents()
	npcWeaponLabel:SetTextColor(Color(230,207,40,255))

	local npcWeaponComboBox = vgui.Create("DComboBox", MCNPCMenu)
	npcWeaponComboBox:SetPos(align, 570)
	npcWeaponComboBox:SetSize(280, 20)
	npcWeaponComboBox:SetTooltip("This will set the NPCs weapon, like the Weapon Override from Sandbox.")

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

	local npcBaseExpTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcBaseExpTextEntry:SetPos(60, 615)
	npcBaseExpTextEntry:SetSize(50, 20)
	npcBaseExpTextEntry:SetTooltip("This will set the base EXP reward for the NPC.")

	local npcExpPerLevelLabel = vgui.Create("DLabel", MCNPCMenu)
	npcExpPerLevelLabel:SetText("Per Level:")
	npcExpPerLevelLabel:SetPos(align, 645)
	npcExpPerLevelLabel:SizeToContents()
	npcExpPerLevelLabel:SetTextColor(Color(230,207,40,255))

	local npcExpPerLevelTextEntry = vgui.Create("DTextEntry", MCNPCMenu)
	npcExpPerLevelTextEntry:SetPos(60, 640)
	npcExpPerLevelTextEntry:SetSize(50, 20)
	npcExpPerLevelTextEntry:SetTooltip("This will be multiplied by the NPCs level and added to the EXP reward for the NPC.")
	
	-- NPC Size Checkboxes
	
	local npcLargeCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcLargeCheckbox:SetText("Large")
	npcLargeCheckbox:SetPos(130, 595)
	npcLargeCheckbox:SizeToContents()
	npcLargeCheckbox:SetTextColor(Color(230,207,40,255))
	npcLargeCheckbox:SetTooltip("This will mark the NPC as Large and make then spawn on Large spawnpoints. This is about the size of an Antlion Guard.")
	
	local npcHugeCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcHugeCheckbox:SetText("Huge")
	npcHugeCheckbox:SetPos(130, 620)
	npcHugeCheckbox:SizeToContents()
	npcHugeCheckbox:SetTextColor(Color(230,207,40,255))
	npcHugeCheckbox:SetTooltip("This will mark the NPC as Huge and make then spawn on Huge spawnpoints. This is about the size of a Hunter Chopper.")
	
	local npcMassiveCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	npcMassiveCheckbox:SetText("Massive")
	npcMassiveCheckbox:SetPos(130, 645)
	npcMassiveCheckbox:SizeToContents()
	npcMassiveCheckbox:SetTextColor(Color(230,207,40,255))
	npcMassiveCheckbox:SetTooltip("This will mark the NPC as Massive and make then spawn on Massive spawnpoints. This is about the size of a Strider.")
	
	-- NPC Damage Multipliers
	local yOffset = MCNPCMenu:GetTall() / 30 + 30
	local xOffset = wide / 3.2 + 5

	local multiplierTextEntries = {}
	local multiplierLabel = vgui.Create("DLabel", MCNPCMenu)
	multiplierLabel:SetText("Damage Multipliers:")
	multiplierLabel:SetFont("GMCSmallFont")
	multiplierLabel:SetPos(xOffset, yOffset - 20)
	multiplierLabel:SizeToContents()
	multiplierLabel:SetTextColor(Color(230, 207, 40, 255))
	
	local multiplierEntries = {}
	
	for dmgType, value in SortedPairsByMemberValue(npcMultipliers, "order", false) do
		-- Label for the multiplier
		local multlabel = dmgType .. "multiplierLabel"
		local multlabel = vgui.Create("DLabel", MCNPCMenu)
		multlabel:SetText(dmgType .. ":")
		multlabel:SetPos(xOffset, yOffset + 5)
		multlabel:SizeToContents()
		multlabel:SetTextColor(Color(230, 207, 40, 255))

		-- Text entry for the multiplier
		local multentry = vgui.Create("DTextEntry", MCNPCMenu)
		multentry:SetPos(xOffset + 50, yOffset)
		multentry:SetNumeric(true)
		multentry:SetMaximumCharCount(4)
		multentry:SetSize(30, 20)
		multentry:SetText(tostring(value.value))
		multentry:SetTooltip(value.tooltip)
		
		multiplierEntries[dmgType] = multentry
		
		multentry.OnChange = function()
			npcMultipliers[dmgType].value = tofloat(multentry:GetValue())
		end
		
		-- Adjust the yOffset for the next entry
		yOffset = yOffset + 25
	end
	
	yOffset = yOffset + 30
	local spawnConditionLabel = vgui.Create("DLabel", MCNPCMenu)
	spawnConditionLabel:SetText("Spawn Conditions:")
	spawnConditionLabel:SetFont("GMCSmallFont")
	spawnConditionLabel:SetPos(xOffset, yOffset - 20)
	spawnConditionLabel:SizeToContents()
	spawnConditionLabel:SetTextColor(Color(230, 207, 40, 255))

	local outsideCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	outsideCheckbox:SetText("Outside")
	outsideCheckbox:SetPos(xOffset, yOffset)
	outsideCheckbox:SizeToContents()
	outsideCheckbox:SetTooltip("NPC will only spawn underneath the skybox.")
	outsideCheckbox:SetTextColor(Color(230, 207, 40, 255))

	local insideCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	insideCheckbox:SetText("Inside")
	insideCheckbox:SetPos(xOffset, yOffset + 25)
	insideCheckbox:SizeToContents()
	insideCheckbox:SetTooltip("NPC will never spawn underneath the skybox.")
	insideCheckbox:SetTextColor(Color(230, 207, 40, 255))

	local roofCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	roofCheckbox:SetText("Roof")
	roofCheckbox:SetPos(xOffset, yOffset + 50)
	roofCheckbox:SizeToContents()
	roofCheckbox:SetTooltip("NPC will spawn on the roof instead of the ground. (Also automatically counts as an inside NPC)")
	roofCheckbox:SetTextColor(Color(230, 207, 40, 255))

	local underwaterCheckbox = vgui.Create("DCheckBoxLabel", MCNPCMenu)
	underwaterCheckbox:SetText("Underwater")
	underwaterCheckbox:SetPos(xOffset, yOffset + 75)
	underwaterCheckbox:SizeToContents()
	underwaterCheckbox:SetTooltip("NPC will only spawn underwater. NPCs without this tag will automatically never spawn underwater.")
	underwaterCheckbox:SetTextColor(Color(230, 207, 40, 255))

	-- Logic for dependencies between checkboxes
	function roofCheckbox:OnChange(value)
		npcSpawnConditions["Roof"] = value
		if value then
			insideCheckbox:SetChecked(true) -- Roof depends on Inside
			npcSpawnConditions["Inside"] = true
			
			if outsideCheckbox:GetChecked() then
				outsideCheckbox:SetChecked(false)
				npcSpawnConditions["Outside"] = false
			end
			if underwaterCheckbox:GetChecked() then
				underwaterCheckbox:SetChecked(false)
				npcSpawnConditions["Underwater"] = false
			end
		end
	end

	function insideCheckbox:OnChange(value)
		npcSpawnConditions["Inside"] = value
		if not value and roofCheckbox:GetChecked() then
			roofCheckbox:SetChecked(false) -- If Inside is unchecked, uncheck Roof
			npcSpawnConditions["Roof"] = false
		end
		if value and outsideCheckbox:GetChecked() then
			outsideCheckbox:SetChecked(false) -- Inside is mutually exclusive with Outside
			npcSpawnConditions["Outside"] = false
		end
		if value and underwaterCheckbox:GetChecked() then
			underwaterCheckbox:SetChecked(false)
			npcSpawnConditions["Underwater"] = false
		end
	end

	function outsideCheckbox:OnChange(value)
		npcSpawnConditions["Outside"] = value
		if value then
			insideCheckbox:SetChecked(false)
			roofCheckbox:SetChecked(false)
			underwaterCheckbox:SetChecked(false)
			
			npcSpawnConditions["Inside"] = false
			npcSpawnConditions["Roof"] = false
			npcSpawnConditions["Underwater"] = false
		end
	end

	function underwaterCheckbox:OnChange(value)
		npcSpawnConditions["Underwater"] = value
		if value then
			-- Uncheck all other spawn conditions if Underwater is checked
			outsideCheckbox:SetChecked(false)
			insideCheckbox:SetChecked(false)
			roofCheckbox:SetChecked(false)
			npcSpawnConditions["Outside"] = false
			npcSpawnConditions["Inside"] = false
			npcSpawnConditions["Roof"] = false
		end
	end
	
	-- OnChanged for NPC Class Text Entry
	npcSelectorTextEntry.OnChange = function(self)
		npcClass = self:GetValue()
	end

	-- OnChanged for NPC Name Text Entry
	npcNameTextEntry.OnChange = function(self)
		npcName = self:GetValue()
	end

	-- OnChange for NPC Scale Text Entry
	npcScaleTextEntry.OnChange = function(self)
		npcStats.scale = tonumber(self:GetValue()) or 1
	end

	-- OnChange for NPC Spawn Weight Text Entry
	npcSpawnWeightTextEntry.OnChange = function(self)
		npcStats.weight = tonumber(self:GetValue()) or 5
	end

	-- OnChange for NPC Skin Text Entry
	npcSkinTextEntry.OnChange = function(self)
		npcSkin = tonumber(self:GetValue()) or -1
	end

	-- OnChange for NPC Bodygroups Text Entry
	npcBodygroupTextEntry.OnChange = function(self)
		npcBodyGroups = self:GetValue()
	end

	-- OnChange for NPC Base Health Text Entry
	npcBaseHealthTextEntry.OnChange = function(self)
		npcStats.hp = tonumber(self:GetValue()) or 50
	end

	-- OnChange for NPC Health Per Level Text Entry
	npcHealthPerLevelTextEntry.OnChange = function(self)
		npcStats.lvlhp = tonumber(self:GetValue()) or 5
	end

	-- OnChange for NPC Base Damage Text Entry
	npcBaseDamageTextEntry.OnChange = function(self)
		npcStats.damage = tonumber(self:GetValue()) or 1
	end

	-- OnChange for NPC Damage Per Level Text Entry
	npcDamagePerLevelTextEntry.OnChange = function(self)
		npcStats.lvldamage = tonumber(self:GetValue()) or 0
	end

	-- OnChange for NPC Weapon ComboBox
	npcWeaponComboBox.OnSelect = function(self, index, value)
		npcWeapon = value
	end

	-- OnChange for NPC Base EXP Text Entry
	npcBaseExpTextEntry.OnChange = function(self)
		npcStats.exp = tonumber(self:GetValue()) or 10
	end

	-- OnChange for NPC EXP Per Level Text Entry
	npcExpPerLevelTextEntry.OnChange = function(self)
		npcStats.lvlexp = tonumber(self:GetValue()) or 1
	end

	-- OnChange for NPC Color Picker
	npcColorPicker.ValueChanged = function(self, color)
		npcColor = color
	end

	-- OnChanged logic for mutually exclusive NPC Type checkboxes
	function npcBossCheckbox:OnChange(value)
		if value then
			npcMinionCheckbox:SetChecked(false)
			npcBonusCheckbox:SetChecked(false)
			npcType = "Boss"
		elseif not (npcMinionCheckbox:GetChecked() or npcBonusCheckbox:GetChecked()) then
			npcType = "Default"
		end
	end

	function npcMinionCheckbox:OnChange(value)
		if value then
			npcBossCheckbox:SetChecked(false)
			npcBonusCheckbox:SetChecked(false)
			npcType = "Minion"
		elseif not (npcBossCheckbox:GetChecked() or npcBonusCheckbox:GetChecked()) then
			npcType = "Default"
		end
	end

	function npcBonusCheckbox:OnChange(value)
		if value then
			npcBossCheckbox:SetChecked(false)
			npcMinionCheckbox:SetChecked(false)
			npcType = "Bonus"
		elseif not (npcBossCheckbox:GetChecked() or npcMinionCheckbox:GetChecked()) then
			npcType = "Default"
		end
	end

	-- OnChanged logic for mutually exclusive NPC Size checkboxes
	function npcMassiveCheckbox:OnChange(value)
		if value then
			npcHugeCheckbox:SetChecked(false)
			npcLargeCheckbox:SetChecked(false)
			npcSize = "Massive"
		elseif not (npcHugeCheckbox:GetChecked() or npcLargeCheckbox:GetChecked()) then
			npcSize = "Normal"
		end
	end

	function npcHugeCheckbox:OnChange(value)
		if value then
			npcMassiveCheckbox:SetChecked(false)
			npcLargeCheckbox:SetChecked(false)
			npcSize = "Huge"
		elseif not (npcMassiveCheckbox:GetChecked() or npcLargeCheckbox:GetChecked()) then
			npcSize = "Normal"
		end
	end

	function npcLargeCheckbox:OnChange(value)
		if value then
			npcMassiveCheckbox:SetChecked(false)
			npcHugeCheckbox:SetChecked(false)
			npcSize = "Large"
		elseif not (npcMassiveCheckbox:GetChecked() or npcHugeCheckbox:GetChecked()) then
			npcSize = "Normal"
		end
	end
	
	-- Add a "Save Configuration" button
	local saveButton = vgui.Create("DButton", MCNPCMenu)
	saveButton:SetText("Save Spawn Data")
	saveButton:SetPos(10, 670)
	saveButton:SetSize(280, 30)
	saveButton.DoClick = function()
		SaveNPCConfigurationToFile()
	end

	-- Callback for when an NPC class is selected
	npcSelectorDropdown.OnSelect = function(self, index, value, data)
		local selectedNPCClass = value
		archivedNPCDropdown:SetValue("") -- Clear the Archived NPC entry when an npc class is selected
		npcSelectorTextEntry:SetValue(tostring(selectedNPCClass))
		
		npcClass = npcSelectorTextEntry:GetValue() or ""
	end
	
	loadButton.DoClick = function()
		local selectedNPC = archivedNPCDropdown:GetSelected() -- Get the selected NPC from the dropdown
		if not selectedNPC then return end -- Exit if no NPC is selected

		for _, anpc in pairs(archivedNPCs) do
			if anpc.name == selectedNPC then
				-- Set variables directly from the NPC data
				npcClass = anpc.class or ""
				npcName = anpc.name or ""
				npcStats.scale = tonumber(anpc.scale) or 1
				npcStats.weight = tonumber(anpc.weight) or 5
				npcSkin = tonumber(anpc.skin) or -1
				npcBodyGroups = anpc.bodygroups or ""
				npcStats.hp = tonumber(anpc.basehealth) or 50
				npcStats.lvlhp = tonumber(anpc.healthlvl) or 5
				npcStats.damage = tonumber(anpc.basedamage) or 1
				npcStats.lvldamage = tonumber(anpc.damagelvl) or 0
				npcWeapon = anpc.weapon or "None"
				npcStats.exp = tonumber(anpc.baseexp) or 10
				npcStats.lvlexp = tonumber(anpc.explvl) or 1
				npcType = anpc.type or "Default"
				npcSize = anpc.size or "Normal"
				npcDamageMultipliers = anpc.multipliers or {}
				npcSpawnConditions = anpc.conditions or {}

				-- Update UI elements to reflect loaded data
				npcSelectorTextEntry:SetText(npcClass)
				npcNameTextEntry:SetText(npcName)
				npcScaleTextEntry:SetText(tostring(npcStats.scale))
				npcSpawnWeightTextEntry:SetText(tostring(npcStats.weight))
				npcSkinTextEntry:SetText(tostring(npcSkin))
				npcBodygroupTextEntry:SetText(npcBodyGroups)
				npcBaseHealthTextEntry:SetText(tostring(npcStats.hp))
				npcHealthPerLevelTextEntry:SetText(tostring(npcStats.lvlhp))
				npcBaseDamageTextEntry:SetText(tostring(npcStats.damage))
				npcDamagePerLevelTextEntry:SetText(tostring(npcStats.lvldamage))
				npcWeaponComboBox:SetValue(npcWeapon)
				npcBaseExpTextEntry:SetText(tostring(npcStats.exp))
				npcExpPerLevelTextEntry:SetText(tostring(npcStats.lvlexp))
				npcColorPicker:SetColor(npcColor)

				-- Set checkboxes for NPC type
				npcBossCheckbox:SetChecked(npcType == "Boss")
				npcMinionCheckbox:SetChecked(npcType == "Minion")
				npcBonusCheckbox:SetChecked(npcType == "Bonus")

				-- Set checkboxes for NPC size
				npcMassiveCheckbox:SetChecked(npcSize == "Massive")
				npcHugeCheckbox:SetChecked(npcSize == "Huge")
				npcLargeCheckbox:SetChecked(npcSize == "Large")

				-- Set checkboxes for spawn conditions
				outsideCheckbox:SetChecked(npcSpawnConditions["Outside"] or false)
				insideCheckbox:SetChecked(npcSpawnConditions["Inside"] or false)
				roofCheckbox:SetChecked(npcSpawnConditions["Roof"] or false)
				underwaterCheckbox:SetChecked(npcSpawnConditions["Underwater"] or false)

				-- Update multipliers UI if applicable
				for dmgType, entry in pairs(anpc.multipliers) do
					if multiplierEntries[dmgType] then
						multiplierEntries[dmgType]:SetValue(entry)
					end
				end

				break -- Exit loop once the matching NPC is found and loaded
			end
		end
	end
	
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
end

-- Callback for saving NPC configuration to a file
function SaveNPCConfigurationToFile()
	local folderName = "gmc/npcs"
    local filename = folderName .. "/" .. npcName .. ".json"
    local fileContent = ""
	
	for k,v in pairs(npcMultipliers) do
		npcDamageMultipliers[k] = v.value
		print(npcDamageMultipliers[k])
	end

	local npcData = {
        ["class"] = npcClass,
        ["name"] = npcName,
        ["scale"] = npcStats.scale,
        ["color"] = npcColor,
        ["weight"] = npcStats.weight,
        ["skin"] = npcSkin,
        ["bodygroups"] = npcBodyGroups,
        ["basehealth"] = npcStats.hp,
        ["healthlvl"] = npcStats.lvlhp,
        ["basedamage"] = npcStats.damage,
        ["damagelvl"] = npcStats.lvldamage,
        ["weapon"] = npcWeapon or "None",
        ["baseexp"] = npcStats.exp,
        ["explvl"] = npcStats.lvlexp,
        ["type"] = npcType,
		["size"] = npcSize,
		["multipliers"] = npcDamageMultipliers,
		["conditions"] = npcSpawnConditions
    }
	
	net.Start("GetArchivedNPC")
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