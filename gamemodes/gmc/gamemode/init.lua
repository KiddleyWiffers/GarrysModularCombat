AddCSLuaFile("gmcscoreboard.lua")
AddCSLuaFile("gui/mchud.lua")
AddCSLuaFile("gui/mcmenu.lua")
AddCSLuaFile("gui/npccreator.lua")
AddCSLuaFile("killstreaks.lua")
AddCSLuaFile("commands.lua")

include("auxpower.lua")
include("commands.lua")
include("npcspawns.lua")
include("modules.lua")
include("savedata.lua")
include("killstreaks.lua")

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

local REBELS = {"models/player/group03/male_01.mdl", "models/player/group03/male_02.mdl", "models/player/group03/male_03.mdl", "models/player/group03/male_04.mdl", "models/player/group03/male_05.mdl", "models/player/group03/male_06.mdl", "models/player/group03/male_07.mdl", "models/player/group03/male_08.mdl", "models/player/group03/male_09.mdl", "models/player/group03/female_01.mdl", "models/player/group03/female_02.mdl", "models/player/group03/female_03.mdl", "models/player/group03/female_04.mdl", "models/player/group03/female_05.mdl", "models/player/group03/female_06.mdl",}
local RemoveEntities = {"item_ammo_357", "item_ammo_357_large", "item_ammo_ar2_altfire", "item_ammo_ar2_large", "item_ammo_ar2", "item_ammo_crossbow", "item_ammo_pistol", "item_ammo_pistol_large", "item_ammo_smg1_grenade", "item_ammo_smg1_large", "item_ammo_smg1", "item_rpg_round", "item_box_buckshot", "item_battery", "item_healthvial", "item_healthkit", "weapon_357", "weapon_ar2", "weapon_crossbow", "weapon_crowbar", "weapon_frag", "weapon_medkit", "weapon_physgun", "weapon_physcannon", "weapon_pistol", "weapon_shotgun", "weapon_slam", "weapon_smg1", "weapon_stunstick", "weapon_rpg"}

function GM:Initialize()
    spawnpoints = LoadSpawnConfigurationFromFile()
end

local playerDamageToEnemy = {} -- Create a table to store damage information
function GM:EntityTakeDamage(target, dmg)
    local player
    local enemy
    local damage

	if target:IsValid() and target:IsPlayer() and GetConVar("gmc_regen_suppression"):GetInt() > 0 then --Suppress regenerative abilities for a few seconds after taking damage.
		target.RegenSuppress = true
		timer.Create(target:EntIndex() .. "RegenSuppress", GetConVar("gmc_regen_suppression"):GetInt(), 1, function()
			if target:IsValid() then
				target.RegenSuppress = false
			end
		end)
    end
	
    if IsValid(target) and IsValid(dmg:GetAttacker()) and dmg:GetAttacker():IsPlayer() then
        player = dmg:GetAttacker()
        enemy = target
        damage = dmg:GetDamage()
        if player:Team() ~= TEAM_FFA and target:IsPlayer() and player:Team() == target:Team() then return true end
        if not target:IsPlayer() and (not target:IsNPC() and not target:IsNextBot()) then return end
        if target == player then return end
        playerDamageToEnemy[player] = playerDamageToEnemy[player] or {} -- Initialize the damage record for the player if not present
        playerDamageToEnemy[player][enemy] = (playerDamageToEnemy[player][enemy] or 0) + damage
        if enemy:Health() < damage then -- Make sure the accumulated damage is fairly calculated.
            local overdamage = enemy:Health() - damage
            playerDamageToEnemy[player][enemy] = playerDamageToEnemy[player][enemy] + overdamage
        end
    end

    if IsValid(target) and IsValid(dmg:GetAttacker()) and (dmg:GetAttacker():IsNPC() or dmg:GetAttacker():IsNextBot()) then -- Set damage for NPCs
        local attacker = dmg:GetAttacker()
        local damage = dmg:GetDamage()
        if attacker.Damage then dmg:SetDamage(math.Round(damage * attacker.Damage)) end
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
    if not IsValid(victim) then
        return
    end

    if GetConVar("gmc_npc_weapon_drop"):GetInt() == 0 then if IsValid(victim:GetActiveWeapon()) then victim:GetActiveWeapon():Remove() end end
	
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:SetNPCKills(attacker:GetNPCKills() + 1)
	end
	
    local expkill = victim.EXP or npc:GetMaxHealth()
    local vicname = victim.Name or "Invalid NPC"
    local viclvl = victim.Level or 0
    local lvldiff = GetConVar("gmc_exp_lvldifference_multiplier"):GetFloat()
    GetPlayerDamageToEnemy(player, enemy)
    local dmgPercent = {}
    local totalDmg = 0
    for player, damage in pairs(playerDamageToEnemy) do
        if damage[victim] and damage[victim] > 0 then totalDmg = totalDmg + damage[victim] end
    end

    for player, damage in pairs(playerDamageToEnemy) do
        if damage[victim] and damage[victim] > 0 then
			totalmult[player] = totalmult[player] or 0
            dmgPercent[player] = damage[victim] / totalDmg
            local atklvl = player:GetLevel()
            local expRaw = math.Round((expkill + (expkill * (lvldiff * (viclvl - atklvl)))) * dmgPercent[player])
			local expEarned = math.Round((expRaw + (expRaw * totalmult[player])))
            player:SetEXP(player:GetEXP() + expEarned)
            player:ChatPrint("You earned " .. expEarned .. " EXP for doing " .. math.Round(dmgPercent[player] * 100) .. "% damage to " .. vicname .. " (Level: " .. viclvl .. ").")
        end
    end

    for player, damage in pairs(playerDamageToEnemy) do
        if damage[victim] then playerDamageToEnemy[player][victim] = nil end
    end
	
	timer.Simple(10, function()
		if IsValid(victim) then
			victim:Remove()
		end
	end)
end

function GM:PlayerDeath(victim, attacker, inflictor)
    if not IsValid(victim) then -- Check for valid attacker and NPC
		return
    end

    local vicname = victim:Nick() or "Invalid Player"
    local viclvl = victim:GetLevel() or 1
    local expkill = GetConVar("gmc_exp_playerkills"):GetInt()
    local lvldiff = GetConVar("gmc_exp_lvldifference_multiplier"):GetFloat()
    GetPlayerDamageToEnemy(player, enemy)
	KillstreakLogic(victim, attacker)
    local dmgPercent = {}
    local totalDmg = 0
    for player, damage in pairs(playerDamageToEnemy) do
        if damage[victim] and damage[victim] > 0 then totalDmg = totalDmg + damage[victim] end
    end

    for player, damage in pairs(playerDamageToEnemy) do
        if damage[victim] and damage[victim] > 0 then
			totalmult[player] = totalmult[player] or 0
            dmgPercent[player] = damage[victim] / totalDmg
            local atklvl = player:GetLevel()
            local expRaw = math.Round((expkill + (expkill * (lvldiff * (viclvl - atklvl)))) * dmgPercent[player])
			local expEarned = math.Round((expRaw + (expRaw * totalmult[player])))
			totalmult[player] = 0
            player:SetEXP(player:GetEXP() + expEarned)
            player:ChatPrint("You earned " .. expEarned .. " EXP for doing " .. math.Round(dmgPercent[player] * 100) .. "% damage to " .. vicname .. " (Level: " .. viclvl .. ").")
        end
    end

    for player, damage in pairs(playerDamageToEnemy) do
        if damage[victim] then playerDamageToEnemy[player][victim] = nil end
    end
end

function GM:PlayerDisconnected(ply)
    SavePlayerData(ply)
    for player, damage in pairs(playerDamageToEnemy) do
        for player, damage in pairs(playerDamageToEnemy) do -- Remove the killed NPC from the playerDamageToEnemy table
            if damage[victim] then playerDamageToEnemy[player][victim] = nil end
        end
    end
end

function GM:ShutDown(ply)
    for k, v in pairs(player.GetAll()) do
        SavePlayerData(v)
    end

    for player, damage in pairs(playerDamageToEnemy) do
        for player, damage in pairs(playerDamageToEnemy) do -- Remove the killed NPC from the playerDamageToEnemy table
            if damage[victim] then playerDamageToEnemy[player][victim] = nil end
        end
    end
end

local function CheckBounds(entity)
	local minb, maxb = entity:GetCollisionBounds()
	minb = (minb + entity:GetPos())
	maxb = (maxb + entity:GetPos())
	local check = ents.FindInBox(minb + Vector(5, 5, 5), maxb - Vector(5, 5, 5))
	local blocked = false
	
	for k,v in pairs(check) do
		if not v:IsWorld() and v != entity then
			blocked = true
			break
		end
	end
	
	return blocked
end

local function SpawnRespawningProp(pos, ang, model, frozen)
	local newProp = ents.Create("prop_physics")
		if not IsValid(newProp) then return end

		newProp:SetModel(model)
		newProp:SetPos(pos)
		newProp:SetAngles(ang)
		newProp:PhysicsInit(SOLID_VPHYSICS)
		
		if not CheckBounds(newProp) then
			newProp:Spawn()
		else
			newProp:Remove()
			newProp = nil
			timer.Simple(10, function()
				if not IsValid(newProp) then
					SpawnRespawningProp(pos, ang, model, frozen)
				end
			end)
		end
		
		if IsValid(newProp) then
			local phys = newProp:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(frozen)
			end

			newProp:CallOnRemove("RespawnProp", function(ent)
				timer.Simple(10, function()
				if not IsValid(ent) then
					SpawnRespawningProp(pos, ang, model, frozen)
				end
			end)
		end)
	end
	return newProp
end

local function SpawnRespawningEnt(pos, ang, ent, frozen)
	local newEnt = ents.Create(ent)
		if not IsValid(newEnt) then return end

		newEnt:SetPos(pos)
		newEnt:SetAngles(ang)
		
		if not CheckBounds(newEnt) then
			newEnt:Spawn()
		else
			newEnt:Remove()
			newEnt = nil
			timer.Simple(10, function()
				if not IsValid(newEnt) then
					SpawnRespawningEnt(pos, ang, model, frozen)
				end
			end)
		end

		if IsValid(newEnt) then
			local phys = newEnt:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(frozen)
			end

			newEnt:CallOnRemove("RespawnProp", function(ent)
				timer.Simple(10, function()
					if not IsValid(ent) then
						SpawnRespawningEnt(pos, ang, ent, frozen)
					end
				end)
			end)
		end
	return newEnt
end

local function SpawnRespawningVehicle(pos, ang, vehicle)
	local selVech = list.Get("Vehicles")[vehicle]
	local newVech = ents.Create(selVech.Class)
	if not IsValid(newVech) then return end
	
	newVech:SetModel(selVech.Model)
	newVech:SetKeyValue("vehiclescript", selVech.KeyValues.vehiclescript)
	newVech:SetPos(pos)
	newVech:SetAngles(ang)
	newVech.beenDriven = false
	
	if not CheckBounds(newVech) then
		newVech:Spawn()
	else
		newVech:Remove()
		newVech = nil
		timer.Simple(10, function()
			if not IsValid(ent) then
				SpawnRespawningVehicle(pos, ang, vehicle)
			end
		end)
	end
	
	if IsValid(newVech) then
		timer.Create("MonitorVehicle_" .. newVech:EntIndex(), 5, 0, function()
			if not IsValid(newVech) then
				timer.Simple(10, function()
					if not IsValid(ent) then
						SpawnRespawningVehicle(pos, ang, vehicle)
					end
				end)
				timer.Remove("MonitorVehicle_" .. newVech:EntIndex())
				return
			end

			-- Check if the vehicle has been driven and is now unoccupied
			if newVech.HasBeenDriven and not IsValid(newVech:GetDriver()) then
				-- Start the respawn timer if it doesn't already exist
				if not timer.Exists("RespawnVehicle_" .. newVech:EntIndex()) then
					timer.Create("RespawnVehicle_" .. newVech:EntIndex(), 60, 1, function()
						if IsValid(newVech) then
							newVech:Remove()
							SpawnRespawningVehicle(pos, ang, vehicle)
						end
					end)
				end
			else
				-- If the vehicle becomes occupied, remove the respawn timer
				timer.Remove("RespawnVehicle_" .. newVech:EntIndex())
			end
		end)

		-- Hook to detect when the vehicle is entered
		hook.Add("PlayerEnteredVehicle", "TrackVehicleUsage_" .. newVech:EntIndex(), function(ply, vehicle)
			if vehicle == newVech and not newVech.HasBeenDriven then
				newVech.HasBeenDriven = true
			end
		end)
		
		-- Detect if the vehicle is damaged to prevent players pushing it into unreachable locations.
		hook.Add("EntityTakeDamage", "VehicleDamaged_" .. newVech:EntIndex(), function(vehicle, dmginfo)
			if vehicle == newVech and not newVech.HasBeenDriven then
				newVech.HasBeenDriven = true
			end
		end)

		-- Clean up hooks and timers when the vehicle is removed
		newVech:CallOnRemove("CleanupVehicleTimers", function()
			timer.Remove("MonitorVehicle_" .. newVech:EntIndex())
			timer.Remove("RespawnVehicle_" .. newVech:EntIndex())
			hook.Remove("PlayerEnteredVehicle", "TrackVehicleUsage_" .. newVech:EntIndex())
			hook.Remove("EntityTakeDamage", "VehicleDamaged_" .. newVech:EntIndex())
		end)
	end
end

function GM:InitPostEntity()
    for k, v in pairs(RemoveEntities) do
        finddelete = ents.FindByClass(v)
        for k, v in pairs(finddelete) do
            v:Remove()
        end
    end

    if spawnpoints then
        for _, spawnpointData in ipairs(spawnpoints) do
			local position = spawnpointData.Position
			local angle = spawnpointData.Angle
			local category = spawnpointData.Category
			local spawntype = spawnpointData.Type
			if spawnpointData.Ent == "gmc_weselector" then
				local option1 = spawnpointData.Option1
				local option2 = spawnpointData.Option2
				local option3 = spawnpointData.Option3
				if category == "Weapons" and (spawntype ~= "gmc_smallhealthpack" and spawntype ~= "gmc_mediumhealthpack" and spawntype ~= "gmc_largehealthpack") then -- Create a new entity at the specified position with the saved spawn data
					local newEntity = ents.Create("gmc_spawnpoint")
					newEntity.SpawnType = spawntype
					newEntity.ExtraOption1 = option1
					newEntity.ExtraOption2 = option2
					newEntity.ExtraOption3 = option3
					newEntity:SetPos(position)
					newEntity:SetAngles(angle)
					newEntity:Spawn()
				elseif spawntype == "gmc_smallhealthpack" or spawntype == "gmc_mediumhealthpack" or spawntype == "gmc_largehealthpack" then
					local newEntity = ents.Create(spawntype)
					newEntity.SpawnType = spawntype
					newEntity:SetPos(position)
					newEntity:Spawn()
				end
			elseif spawnpointData.Ent == "gmc_mapent" then
				if category == "Prop" then
					SpawnRespawningProp(position, angle, spawntype, spawnpointData.Frozen)
				elseif category == "Ent" then
					SpawnRespawningEnt(position, angle, spawntype, spawnpointData.Frozen)
				elseif category == "Vehicle" then
					SpawnRespawningVehicle(position, angle, spawntype)
				end
			end
        end
    else
        print("No spawn configuration found.")
    end
end

local lvlexpbase = GetConVar("gmc_levelexp_base"):GetInt()
local lvlexpscale = GetConVar("gmc_levelexp_scale"):GetInt()
local lvlexppower = GetConVar("gmc_levelexp_power"):GetInt()
timer.Create("FractionTimer", 0.1, 0, function()
    for k, ply in pairs(player.GetAll()) do --Timer that runs every 0.1 seconds to optimize functions
        if ply:GetEXP() >= ply:GetEXPtoLevel() and ply:GetEXPtoLevel() > 0 then
            ply:SetLevel(ply:GetLevel() + 1)
            ply:SetEXP(ply:GetEXP() - ply:GetEXPtoLevel())
            ply:SetEXPtoLevel((lvlexpscale * ply:GetLevel()) * lvlexppower)
            ply:SetSP(ply:GetSP() + GetConVar("gmc_points_per_level"):GetInt())
        end

        for id, ammo in pairs(ply:GetAmmo()) do
            local ammomax = math.floor(game.GetAmmoMax(id) + (game.GetAmmoMax(id) * (ply:GetMod("ammoreserve") * MOD_AMMORES)))
            if ply:GetAmmoCount(id) > ammomax then ply:SetAmmo(ammomax, id) end
        end
    end
end)

function GM:PlayerInitialSpawn(ply)
    LoadPlayerData(ply)
    ply:SetTeam(TEAM_FFA)
	ply:SetRenderMode(RENDERMODE_TRANSCOLOR)
end

function GM:PlayerSpawn(ply)
    local weapons = GetConVar("gmc_loadout_weapon"):GetString() -- Get the values of the convars
    local ammoTypes = GetConVar("gmc_loadout_ammotypes"):GetString()
    local ammoAmounts = GetConVar("gmc_loadout_ammoamount"):GetString()
    local loadout = string.Explode(" ", weapons) -- Set the players loadout based on the convars
    local ammo = string.Explode(" ", ammoTypes)
    local amount = string.Explode(" ", ammoAmounts)
    for i = 1, #loadout do -- Grant the player their loadout
        ply:Give(loadout[i], false)
    end

    for i = 1, #ammo do
        if isnumber(tonumber(amount[i])) then ply:GiveAmmo(amount[i] + (game.GetAmmoMax(game.GetAmmoID(ammo[i])) * (ply:GetMod("ammoreserve") * MOD_AMMORES)), ammo[i]) end
    end

    SetAUX(ply)
    ply:SetDuckSpeed(0.3)
    ply:SetUnDuckSpeed(0.4)
    ply:SetCrouchedWalkSpeed(0.4)
    ply:AllowFlashlight(true)
    ply:SetupHands()
    self:PlayerSetModel(ply)
    self:SelectPlayerSpawn(ply) -- Use the spawnpoints
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

            if not isBlocked then -- Only add potential spawns if not blocked and the conditions are met
                if (team ~= TEAM_FFA and team ~= TEAM_COOP) or (spawnteam == team or spawnteam == "No Team") then
                    table.insert(potentialspawns, {position, angle})
                elseif team == TEAM_FFA or team == TEAM_COOP then
                    table.insert(potentialspawns, {position, angle})
                end
            end
        end
    end

    if ply:Alive() and #potentialspawns > 0 then
        local pickedspawn = table.Random(potentialspawns)
        ply:SetPos(Vector(pickedspawn[1]))
        ply:SetEyeAngles(pickedspawn[2])
    end
end

function GM:PlayerSetModel(ply)
    if util.IsValidModel(ply:GetInfo("gmc_model")) then
        ply:SetModel(ply:GetInfo("gmc_model"))
        ply:SetBodyGroups(ply:GetInfo("gmc_bodygroups")) -- Set to a test value to try and get it to work
    else
        ply:SetModel(table.Random(REBELS))
    end

    local colorStr = ply:GetInfo("gmc_color") -- Get the player's desired color from the ConVar
    local r, g, b = string.match(colorStr, "(%d+) (%d+) (%d+)") -- Parse the color string (format: "R G B")
    if r and g and b then
        r = tonumber(r)
        g = tonumber(g)
        b = tonumber(b)
    else
        r, g, b = 255, 255, 255 -- Set default values if parsing fails
    end

    if ply:Team() == TEAM_RED then -- Set player color based on team
        ply:SetPlayerColor(team.GetColor(TEAM_RED):ToVector())
        ply:SetColor(team.GetColor(TEAM_RED))
    elseif ply:Team() == TEAM_BLUE then
        ply:SetPlayerColor(team.GetColor(TEAM_BLUE):ToVector())
        ply:SetColor(team.GetColor(TEAM_BLUE))
    elseif ply:Team() == TEAM_GREEN then
        ply:SetPlayerColor(team.GetColor(2):ToVector())
        ply:SetColor(team.GetColor(TEAM_GREEN))
    elseif ply:Team() == TEAM_PURPLE then
        ply:SetPlayerColor(team.GetColor(TEAM_PURPLE):ToVector())
        ply:SetColor(team.GetColor(TEAM_PURPLE))
    elseif ply:Team() == TEAM_COOP or ply:Team() == TEAM_FFA then
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

    local function colorDistance(c1, c2) -- Function to calculate the distance between two colors
        return math.sqrt((c1.r - c2.r) ^ 2 + (c1.g - c2.g) ^ 2 + (c1.b - c2.b) ^ 2)
    end

    local closestColor = nil
    local minDistance = math.huge
    local blackThreshold = 50 -- Define a threshold for considering a color as black
    for _, targetColor in ipairs(colors) do
        local distance = colorDistance(color, targetColor.color)
        if targetColor.name == "black" and distance < blackThreshold then
            closestColor = targetColor
            minDistance = distance
            break
        end

        if distance < minDistance and targetColor.name ~= "black" then
            minDistance = distance
            closestColor = targetColor
        end
    end

    if closestColor.name == "black" then
        closestColor.color = Color(255, 255, 255)
    elseif closestColor.name == "orange" then
        closestColor.color = Color(255, 20, 0)
    end

    local pickedName = closestColor.name
    local pickedColor = closestColor.color:ToVector()
    ply:SetNWString("EffectColorName", pickedName)
    ply:SetNWVector("EffectColor", pickedColor)
end

hook.Add("PlayerDeathSound", "MuteDefaultDeath", function(ply)
    return true -- we don't want the default sound
end)

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