	AddCSLuaFile()

	include( "modules.lua" )
	include("commands.lua")
	AddCSLuaFile("playerclass.lua")
	include( "playerclass.lua" )

	GM.Name    = "Garry's Modular Combat"
	GM.Author  = "KiddleyWiffers"
	GM.Email   = "dahouse5501@gmail.com"
	GM.Website = "N/A"

	TEAM_RED = 0
	TEAM_BLUE = 1
	TEAM_GREEN = 2
	TEAM_PURPLE = 3
	TEAM_COOP = 4
	TEAM_FFA = 5
	TEAM_MONSTER = 6

	team.SetUp ( TEAM_RED, "Red", Color( 255, 0, 0, 255) )
	team.SetUp ( TEAM_BLUE, "Blue", Color( 0, 0, 255, 255) )
	team.SetUp ( TEAM_GREEN, "Green", Color( 0, 255, 0, 255) )
	team.SetUp ( TEAM_PURPLE, "Purple", Color( 200, 0, 200, 255) )
	team.SetUp ( TEAM_COOP, "Coop", Color( 255, 255, 255, 255) )
	team.SetUp ( TEAM_FFA, "Free For All", Color( 255, 255, 255, 255) )
	team.SetUp ( TEAM_MONSTER, "Monster", Color( 0, 255, 0, 255) )

	-- Respawn timer logic
	local respawnTime = GetConVar("gmc_respawntime_coop"):GetInt()

	-- Table to store player respawn times
	local respawnTimers = {}

	-- Respawn players if there is a lua refresh
	for k,ply in pairs(player.GetAll()) do
		if !ply:Alive() then
			ply:Spawn()
			if SERVER then
				ply:UnSpectate()
			end
		end
	end

	local playerList = {}

	local function SortPlayerList()
		for i = #playerList, 1, -1 do
			if not IsValid(playerList[i]) then table.remove(playerList, i) end
		end
		table.sort(playerList, function(a, b)
			if not (IsValid(a) and IsValid(b)) then return false end
			return a:Nick():lower() < b:Nick():lower()
		end)
	end

	for k, ply in pairs(player.GetAll()) do
		table.insert(playerList, ply)
		SortPlayerList()
	end

	-- Add player to the spectate list when they join
	hook.Add("PlayerInitialSpawn", "AddPlayerToList", function(ply)
		table.insert(playerList, ply)
		SortPlayerList()
		player_manager.SetPlayerClass(ply, "player_gmc")
	end)

	-- Remove player from the spectate list when they leave
	hook.Add("PlayerDisconnected", "RemovePlayerFromList", function(ply)
		for i, p in ipairs(playerList) do
			if p == ply then
				table.remove(playerList, i)
				break
			end
		end
	end)

	-- Update the list when a player's name changes
	hook.Add("PlayerNameChanged", "UpdatePlayerListOnNameChange", function(ply, oldName, newName)
		SortPlayerList()
	end)

	hook.Add("PlayerDeath", "HandleDeath", function(victim, inflictor, attacker)
		respawnTime = GetConVar("gmc_respawntime_coop"):GetInt()
		-- Set the respawn delay
		respawnTimers[victim:SteamID()] = CurTime() + respawnTime
		local rag = victim:GetRagdollEntity()
		
		if victim:IsPlayer() then
			for k,ply in pairs(player.GetAll()) do
				if ply:GetObserverTarget() == victim then
					if IsValid(rag) then
						victim:SpectateEntity(rag)
					end
				end
			end
		end
		
		-- Make the player spectate the person who killed them.
		if attacker:IsPlayer() && attacker:Alive() then
			victim:Spectate(OBS_MODE_CHASE)
			victim:SpectateEntity(attacker)
		else
			victim:Spectate(OBS_MODE_CHASE)
			if IsValid(rag) then
				victim:SpectateEntity(rag)
			end
		end
	end)

	hook.Add("PlayerDeathThink", "RestrictRespawn", function(ply)
		return false
	end)

	local spectateCooldowns = {}

	local function CanSwitchSpectateTarget(ply)
		local steamID = ply:SteamID()
		local cooldownTime = 0.4  -- Cooldown in seconds
		local lastSwitch = spectateCooldowns[steamID] or 0

		if CurTime() >= lastSwitch + cooldownTime then
			spectateCooldowns[steamID] = CurTime()
			return true
		end

		return false
	end

	hook.Add("StartCommand", "HandleSpectatingSwitch", function(ply, cmd)
		if CLIENT then return end                         -- avoid double-firing
		if ply:Alive() then return end
		if ply:GetObserverMode() == OBS_MODE_NONE then return end

		local buttons = cmd:GetButtons()
		local ATTACK  = bit.band(buttons, IN_ATTACK)  ~= 0
		local ATTACK2 = bit.band(buttons, IN_ATTACK2) ~= 0

		if ATTACK and CanSwitchSpectateTarget(ply) then
			NextSpectateTarget(ply)
		elseif ATTACK2 and CanSwitchSpectateTarget(ply) then
			PreviousSpectateTarget(ply)
		end
	end)

	hook.Add("StartCommand", "HandleRespawnAfterTimer", function(ply, cmd)
		local timerEnd = respawnTimers[ply:SteamID()]

		if timerEnd and CurTime() >= timerEnd then
			if cmd:GetButtons() != IN_ATTACK && cmd:GetButtons() != IN_ATTACK2 && cmd:GetButtons() != (IN_ATTACK + IN_ATTACK2) && cmd:GetButtons() > 0 then
				ply:UnSpectate()
				ply:Spawn()
				respawnTimers[ply:SteamID()] = nil
			end
		end
	end)
	
	local function IsValidSpectateTarget(ply, target)
		return IsValid(target)
			and target:IsPlayer()
			and target ~= ply
			and target:Alive()
			and target:Team() == ply:Team()
	end

	local function FindNextValidTarget(ply, startIndex, step)
		local listSize = #playerList
		if listSize <= 0 then return nil end

		local idx = startIndex
		for _ = 1, listSize do
			idx = idx + step
			if idx > listSize then idx = 1
			elseif idx < 1 then idx = listSize
			end

			local t = playerList[idx]
			if IsValidSpectateTarget(ply, t) then
				return t
			end
		end
		return nil
	end

	function NextSpectateTarget(ply)
		if CLIENT then return end
		local cur = ply:GetObserverTarget()
		local start = table.KeyFromValue(playerList, cur) or 0   -- 0 so first step hits index 1
		local tgt = FindNextValidTarget(ply, start, 1)
		if IsValid(tgt) then
			if ply:GetObserverMode() == OBS_MODE_NONE then
				ply:Spectate(OBS_MODE_CHASE)
			end
			ply:SpectateEntity(tgt)
		end
	end

	function PreviousSpectateTarget(ply)
		if CLIENT then return end
		local cur = ply:GetObserverTarget()
		local start = table.KeyFromValue(playerList, cur) or 1
		local tgt = FindNextValidTarget(ply, start, -1)
		if IsValid(tgt) then
			if ply:GetObserverMode() == OBS_MODE_NONE then
				ply:Spectate(OBS_MODE_CHASE)
			end
			ply:SpectateEntity(tgt)
		end
	end