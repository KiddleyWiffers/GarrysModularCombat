AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "gui/mchud.lua" )
AddCSLuaFile( "gui/mcmenu.lua" )
AddCSLuaFile( "commands.lua" )
AddCSLuaFile("gmcscoreboard.lua")
AddCSLuaFile("gui/npccreator.lua")

include( "auxpower.lua" )
include( "commands.lua" )
include( "npcspawns.lua" )
include( "modules.lua" )
include( "savedata.lua" )
include( "playerclass.lua" )

util.AddNetworkString("BindModules")
util.AddNetworkString("ChangeSuits")
util.AddNetworkString("RenameSuit")
util.AddNetworkString("ResetSuit")
util.AddNetworkString("SendSuitInfoToClient")
util.AddNetworkString("UpdateModules")
util.AddNetworkString("UpdatePlayerModel")
util.AddNetworkString("UpdateBodygroups")
util.AddNetworkString("castRecieve")
util.AddNetworkString("cheatRecieve")
util.AddNetworkString("StartRespawnCountdown")

local REBELS = {
	"models/player/group03/male_01.mdl",
	"models/player/group03/male_02.mdl",
	"models/player/group03/male_03.mdl",
	"models/player/group03/male_04.mdl",
	"models/player/group03/male_05.mdl",
	"models/player/group03/male_06.mdl",
	"models/player/group03/male_07.mdl",
	"models/player/group03/male_08.mdl",
	"models/player/group03/male_09.mdl",
	"models/player/group03/female_01.mdl",
	"models/player/group03/female_02.mdl",
	"models/player/group03/female_03.mdl",
	"models/player/group03/female_04.mdl",
	"models/player/group03/female_05.mdl",
	"models/player/group03/female_06.mdl",
}

local RemoveEntities = {
	"item_ammo_357",
	"item_ammo_357_large",
	"item_ammo_ar2_altfire",
	"item_ammo_ar2_large",
	"item_ammo_ar2",
	"item_ammo_crossbow",
	"item_ammo_pistol",
	"item_ammo_pistol_large",
	"item_ammo_smg1_grenade",
	"item_ammo_smg1_large",
	"item_ammo_smg1",
	"item_rpg_round",
	"item_box_buckshot",
	"item_battery",
	"item_healthvial",
	"item_healthkit",
	"weapon_357",
	"weapon_ar2",
	"weapon_crossbow",
	"weapon_crowbar",
	"weapon_frag",
	"weapon_medkit",
	"weapon_physgun",
	"weapon_physcannon",
	"weapon_pistol",
	"weapon_shotgun",
	"weapon_slam",
	"weapon_smg1",
	"weapon_stunstick",
	"weapon_rpg"
}

function GM:Initialize()
	spawnpoints = LoadSpawnConfigurationFromFile()
end

-- Create a table to store damage information
local playerDamageToEnemy = {}

function GM:EntityTakeDamage(target, dmg)
	local player
	local enemy
	local damage
    if IsValid(target) and IsValid(dmg:GetAttacker()) and dmg:GetAttacker():IsPlayer() then
        player = dmg:GetAttacker()
        enemy = target
        damage = dmg:GetDamage()
		
		if player:Team() != TEAM_FFA && target:IsPlayer() && player:Team() == target:Team() then
			return true
		end
		
		if !target:IsPlayer() && !target:IsNPC() then
			return
		end
		
		if target == player then
			return
		end
		
        -- Initialize the damage record for the player if not present
        playerDamageToEnemy[player] = playerDamageToEnemy[player] or {}
        playerDamageToEnemy[player][enemy] = (playerDamageToEnemy[player][enemy] or 0) + damage

        -- Make sure the accumulated damage is fairly calculated.
		if enemy:Health() < damage then
			local overdamage = enemy:Health() - damage
			playerDamageToEnemy[player][enemy] = playerDamageToEnemy[player][enemy] + overdamage
		end
    end

	
	--Suppress regenerative abilities for a few seconds after taking damage.
	if IsValid(target) then
		
	end
	
	-- Set damage for NPCs
	if IsValid(target) and IsValid(dmg:GetAttacker()) and (dmg:GetAttacker():IsNPC() || dmg:GetAttacker():IsNextBot()) then
		local attacker = dmg:GetAttacker()
		local damage = dmg:GetDamage()
		
		if attacker.Damage then
			dmg:SetDamage(math.Round(damage * attacker.Damage))
		end
	end
end

function GetPlayerDamageToEnemy(player, enemy)
    if playerDamageToEnemy[player] and playerDamageToEnemy[player][enemy] then
        return playerDamageToEnemy[player][enemy]
    else
        return 0
    end
end

function GM:OnNPCKilled(victim, attacker, inflictor)
    -- Check for valid attacker and NPC
    if not IsValid(attacker) or not IsValid(victim) or not attacker:IsPlayer() or attacker == victim then
        return
    end
	
	if GetConVar("gmc_npc_weapon_drop"):GetInt() == 0 then
		if IsValid(victim:GetActiveWeapon()) then
			victim:GetActiveWeapon():Remove()
		end
	end
	
	attacker:SetNPCKills(attacker:GetNPCKills() + 1)
	
    local expkill = victim.EXP or npc:GetMaxHealth()
    local vicname = victim.Name or "Invalid NPC"
    local viclvl = victim.Level or 0
    local lvldiff = GetConVar("gmc_exp_lvldifference_multiplier"):GetFloat()
	
	GetPlayerDamageToEnemy(player, enemy)
	
	local dmgPercent = {}
	local totalDmg = 0
	
	for player, damage in pairs(playerDamageToEnemy) do
		if damage[victim] and damage[victim] > 0 then
			totalDmg = totalDmg + damage[victim]
		end
	end
	
	for player, damage in pairs(playerDamageToEnemy) do
		if damage[victim] and damage[victim] > 0 then
			dmgPercent[player] = damage[victim]/totalDmg
			local atklvl = player:GetLevel()
			
			local expEarned = math.Round((expkill + (expkill * (lvldiff * (viclvl-atklvl)))) * (dmgPercent[player]))
			
			player:SetEXP(player:GetEXP() + expEarned)
			player:ChatPrint("You earned " .. expEarned .. " EXP for doing " .. math.Round(dmgPercent[player] * 100) .. "% damage to " .. vicname .. " (Level: " .. viclvl .. ").")
		end
	end
	
	for player, damage in pairs(playerDamageToEnemy) do
		if damage[victim] then
			playerDamageToEnemy[player][victim] = nil
		end
	end
end

function GM:PlayerDeath(victim, attacker, inflictor)
	-- Check for valid attacker and NPC
    if not IsValid(attacker) or not IsValid(victim) or not attacker:IsPlayer() or attacker == victim then
        return
    end
	
	local vicname = victim:Nick() or "Invalid Player"
	local viclvl = victim:GetLevel() or 1
	local expkill = GetConVar("gmc_exp_playerkills"):GetInt()
	local lvldiff = GetConVar("gmc_exp_lvldifference_multiplier"):GetFloat()
	
	GetPlayerDamageToEnemy(player, enemy)
	
	local dmgPercent = {}
	local totalDmg = 0
	
	for player, damage in pairs(playerDamageToEnemy) do
		if damage[victim] and damage[victim] > 0 then
			totalDmg = totalDmg + damage[victim]
		end
	end
	
	for player, damage in pairs(playerDamageToEnemy) do
		if damage[victim] and damage[victim] > 0 then
			dmgPercent[player] = damage[victim]/totalDmg
			local atklvl = player:GetLevel()
			
			local expEarned = math.Round((expkill + (expkill * (lvldiff * (viclvl-atklvl)))) * (dmgPercent[player]))
			
			player:SetEXP(player:GetEXP() + expEarned)
			player:ChatPrint("You earned " .. expEarned .. " EXP for doing " .. math.Round(dmgPercent[player] * 100) .. "% damage to " .. vicname .. " (Level: " .. viclvl .. ").")
		end
	end
	
	for player, damage in pairs(playerDamageToEnemy) do
		if damage[victim] then
			playerDamageToEnemy[player][victim] = nil
		end
	end
end

function GM:PlayerDisconnected(ply)
	SavePlayerData(ply)
	
	for player, damage in pairs(playerDamageToEnemy) do
		-- Remove the killed NPC from the playerDamageToEnemy table
		for player, damage in pairs(playerDamageToEnemy) do
			if damage[victim] then
				playerDamageToEnemy[player][victim] = nil
			end
		end
	end
end

function GM:ShutDown(ply)
	for k,v in pairs(player.GetAll()) do
		SavePlayerData(v)
	end
	
	for player, damage in pairs(playerDamageToEnemy) do
		-- Remove the killed NPC from the playerDamageToEnemy table
		for player, damage in pairs(playerDamageToEnemy) do
			if damage[victim] then
				playerDamageToEnemy[player][victim] = nil
			end
		end
	end
end

function GM:InitPostEntity()
	for k,v in pairs(RemoveEntities) do 
		finddelete = ents.FindByClass(v)
		for k,v in pairs(finddelete) do
			v:Remove()
		end
	end
	if spawnpoints then
        for _, spawnpointData in ipairs(spawnpoints) do
            local position = spawnpointData.Position
            local category = spawnpointData.Category
            local spawntype = spawnpointData.Type
			local option1 = spawnpointData.Option1
			local option2 = spawnpointData.Option2
			local option3 = spawnpointData.Option3
			
            -- Create a new entity at the specified position with the saved spawn data
            if category == "Weapons" && (spawntype != "gmc_smallhealthpack" && spawntype != "gmc_mediumhealthpack" && spawntype != "gmc_largehealthpack") then
				local newEntity = ents.Create("gmc_spawnpoint")
				newEntity.SpawnType = spawntype
				newEntity.ExtraOption1 = option1
				newEntity.ExtraOption2 = option2
				newEntity.ExtraOption3 = option3
				newEntity:SetPos(position)
				newEntity:Spawn()
			elseif (spawntype == "gmc_smallhealthpack" || spawntype == "gmc_mediumhealthpack" || spawntype == "gmc_largehealthpack") then
				local newEntity = ents.Create(spawntype)
				newEntity.SpawnType = spawntype
				newEntity:SetPos(position)
				newEntity:Spawn()
			end
        end
    else
        print("No spawn configuration found.")
    end
end

local lvlexpbase = GetConVar( "gmc_levelexp_base" ):GetInt()
local lvlexpscale = GetConVar( "gmc_levelexp_scale" ):GetInt()
local lvlexppower = GetConVar( "gmc_levelexp_power" ):GetInt()

--Timer that runs every 0.1 seconds to optimize functions
timer.Create("FractionTimer", 0.1, 0, function()
	for k,ply in pairs(player.GetAll()) do
		if(ply:GetEXP() >= ply:GetEXPtoLevel() && ply:GetEXPtoLevel() > 0) then
			ply:SetLevel(ply:GetLevel() + 1)
			ply:SetEXP(ply:GetEXP() - ply:GetEXPtoLevel())
			ply:SetEXPtoLevel((lvlexpscale * ply:GetLevel()) * lvlexppower)
			ply:SetSP(ply:GetSP() + GetConVar( "gmc_points_per_level"):GetInt())
		end
		
		for id,ammo in pairs(ply:GetAmmo()) do
			local ammomax =  math.floor(game.GetAmmoMax(id) + (game.GetAmmoMax(id) * (ply:GetNWInt("ammoreserve") * MOD_AMMORES)))
			if ply:GetAmmoCount(id) > ammomax then
				ply:SetAmmo(ammomax, id)
			end
		end
	end
end)

function GM:PlayerInitialSpawn ( ply )
	LoadPlayerData(ply)
	ply:SetTeam( TEAM_FFA )
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_gmc")
	
	-- Get the values of the convars
	local weapons = GetConVar("gmc_loadout_weapon"):GetString()
	local ammoTypes = GetConVar("gmc_loadout_ammotypes"):GetString()
	local ammoAmounts = GetConVar("gmc_loadout_ammoamount"):GetString()

	-- Set the players loadout based on the convars
	local loadout = string.Explode(" ", weapons)
	local ammo = string.Explode(" ", ammoTypes)
	local amount = string.Explode(" ", ammoAmounts)

	-- Grant the player their loadout
    for i = 1, #loadout do
        ply:Give(loadout[i], false)
    end

    for i = 1, #ammo do
		if isnumber(tonumber(amount[i])) then
			ply:GiveAmmo(amount[i] + (game.GetAmmoMax(game.GetAmmoID(ammo[i])) * (ply:GetNWInt("ammoreserve") * MOD_AMMORES)), ammo[i])
		end
    end

    SetAUX(ply)
    ply:SetDuckSpeed(0.3)
    ply:SetUnDuckSpeed(0.4)
    ply:SetCrouchedWalkSpeed(0.4)
    ply:AllowFlashlight(true)
    ply:SetupHands()
	
	self:PlayerSetModel(ply)
	
    -- Use the spawnpoints
    self:SelectPlayerSpawn(ply)

    ply:GodEnable()
    ply:SetMaterial("models/wireframe")
    timer.Simple(5, function()
        ply:SetMaterial("")
        ply:GodDisable()
		ply:SetColor(Color(255, 255, 255))
    end)
end

function GM:SelectPlayerSpawn(ply)
    if not spawnpoints then return end

    local potentialspawns = {}
    local team = ply:Team()

    for _, spawnpointData in pairs(spawnpoints) do
        local position = spawnpointData.Position
		local angle = spawnpointData.Angle
        local category = spawnpointData.Category
        local spawntype = spawnpointData.Type

        if category == "Players" then
            local spawnteam = nil

            if spawntype == "Red" then
                spawnteam = TEAM_RED
            elseif spawntype == "Blue" then
                spawnteam = TEAM_BLUE
            elseif spawntype == "Green" then
                spawnteam = TEAM_GREEN
            elseif spawntype == "Purple" then
                spawnteam = TEAM_PURPLE
			else
				spawnteam = "No Team"
            end

            local entitiesNearSpawn = ents.FindInSphere(position, 50)

            local isBlocked = false

            for _, entity in pairs(entitiesNearSpawn) do
                if IsValid(entity) and (entity:IsPlayer() or entity:IsNPC()) then
                    isBlocked = true
                    break
                end
            end

            -- Only add potential spawns if not blocked and the conditions are met
            if not isBlocked then
                if (team ~= TEAM_FFA and team ~= TEAM_COOP) or (spawnteam == team || spawnteam == "No Team") then
                    table.insert(potentialspawns, {position, angle})
                elseif (team == TEAM_FFA or team == TEAM_COOP) then
                    table.insert(potentialspawns, {position, angle})
                end
            end
        end
    end

    if ply:Alive() and #potentialspawns > 0 then
		local pickedspawn = table.Random(potentialspawns)
        ply:SetPos(Vector(pickedspawn[1]))
		if angle then
			ply:SetEyeAngles(pickedspawn[2])
		end
    end
end

function GM:PlayerSetModel(ply)
	if (util.IsValidModel(ply:GetInfo("gmc_model"))) then
		ply:SetModel( ply:GetInfo("gmc_model") )
		-- Set to a test value to try and get it to work
		ply:SetBodyGroups(ply:GetInfo("gmc_bodygroups"))
	else
		ply:SetModel( table.Random(REBELS) )
	end
	
    -- Get the player's desired color from the ConVar
    local colorStr = ply:GetInfo("gmc_color")

    -- Parse the color string (format: "R G B")
    local r, g, b = string.match(colorStr, "(%d+) (%d+) (%d+)")
    
    if r and g and b then
        r = tonumber(r)
        g = tonumber(g)
        b = tonumber(b)
    else
        -- Set default values if parsing fails
        r, g, b = 255, 255, 255
    end
	
	-- Set player color based on team
	if ply:Team() == TEAM_RED then
		ply:SetPlayerColor(team.GetColor( TEAM_RED ):ToVector())
		ply:SetColor(team.GetColor( TEAM_RED ))
	elseif ply:Team() == TEAM_BLUE then
		ply:SetPlayerColor(team.GetColor( TEAM_BLUE ):ToVector())
		ply:SetColor(team.GetColor( TEAM_BLUE ))
	elseif ply:Team() == TEAM_GREEN then
		ply:SetPlayerColor(team.GetColor( 2 ):ToVector())
		ply:SetColor(team.GetColor( TEAM_GREEN ))
	elseif ply:Team() == TEAM_PURPLE then
		ply:SetPlayerColor(team.GetColor( TEAM_PURPLE ):ToVector())
		ply:SetColor(team.GetColor( TEAM_PURPLE ))
	elseif ply:Team() == TEAM_COOP || ply:Team() == TEAM_FFA then
		ply:SetColor(Color(r, g, b))
		ply:SetPlayerColor(Vector(r / 255, g / 255, b / 255))
	end
	
	PlayerColorPicker(ply)
end

net.Receive("UpdateBodygroups", function(len, ply)
	local bodygroup = net.ReadInt(8)
	local value = net.ReadInt(8)
	ReceiveSecurity(ply, 10)
	
	ply:SetBodygroup(bodygroup, value)
end)

net.Receive("UpdatePlayerModel", function(len, ply)
	local model = net.ReadString()
	ReceiveSecurity(ply, 3)
	
	ply:SetModel(model)
end)

function GM:ShowSpare2(ply)
	ply:ConCommand("gmc_gamemenu")
end

function LoadSpawnConfigurationFromFile()
    local spawnpoints = {}
	print("Loading spawn configuration for " .. game.GetMap())

    local data = file.Read("gmc/mapdata/" .. game.GetMap() .. ".txt", "DATA") -- Read the saved data from the file

    if data then
        spawnpoints = util.JSONToTable(data)
		print("Spawn configuration loaded.")
    else
        print("Failed to load spawn configuration, no config found.")
    end
	
    return spawnpoints
end

function PlayerColorPicker(ply)
    local color = ply:GetPlayerColor():ToColor()
    local r, g, b = color.r, color.g, color.b

    -- Define a list of target colors
    local colors = {
        { name = "red", color = Color(255, 0, 0) },
        { name = "blue", color = Color(0, 0, 255) },
        { name = "green", color = Color(0, 255, 0) },
        { name = "pink", color = Color(255, 0, 150) },
		{ name = "purple", color = Color(200, 0, 255) },
        { name = "yellow", color = Color(255, 255, 0) },
        { name = "orange", color = Color(255, 100, 0) },
        { name = "electricblue", color = Color(0, 255, 255) },
        { name = "white", color = Color(255, 255, 255) },
		{ name = "black", color = Color(0, 0, 0) },
    }

    -- Function to calculate the distance between two colors
    local function colorDistance(c1, c2)
        return math.sqrt((c1.r - c2.r) ^ 2 + (c1.g - c2.g) ^ 2 + (c1.b - c2.b) ^ 2)
    end

    local closestColor = nil
    local minDistance = math.huge
	local blackThreshold = 50  -- Define a threshold for considering a color as black
	
    for _, targetColor in ipairs(colors) do
		local distance = colorDistance(color, targetColor.color)
		if targetColor.name == "black" and distance < blackThreshold then
            closestColor = targetColor
            minDistance = distance
            break
        end

        if distance < minDistance && targetColor.name != "black" then
            minDistance = distance
            closestColor = targetColor
        end
    end
	
	if closestColor.name == "black" then
		closestColor.color = Color(255,255,255)
	elseif closestColor.name == "orange" then
		closestColor.color = Color(255,20,0)
	end
	
	local pickedName = closestColor.name
	local pickedColor = closestColor.color:ToVector()
	
	ply:SetNWString("EffectColorName", pickedName)
    ply:SetNWVector("EffectColor", pickedColor)
end

hook.Add( "PlayerDeathSound", "MuteDefaultDeath", function( ply )
	return true -- we don't want the default sound!
end )

local playerNetInfo = {}

function ReceiveSecurity(ply, delay)
    if not IsValid(ply) then return end

    local steamID = ply:SteamID()
    if not playerNetInfo[steamID] then
        playerNetInfo[steamID] = {
            lastNetTime = 0,
            antispamCount = 0,
        }
    end

    local currentTime = CurTime()
    local playerData = playerNetInfo[steamID]

    if currentTime < playerData.lastNetTime then
        playerData.antispamCount = playerData.antispamCount + 1
        if playerData.antispamCount >= delay then
            ply:Kick("Sent " .. delay .. " nets in 0.5 seconds, possibly trying to crash the server.")
            return
        end
    else
        playerData.antispamCount = 0
        playerData.lastNetTime = currentTime + 0.5
    end
end