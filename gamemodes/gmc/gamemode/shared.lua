AddCSLuaFile()

include( "modules.lua" )
include("commands.lua")

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
    table.sort(playerList, function(a, b)
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

-- Update the list when a player's name changes (optional)
hook.Add("PlayerNameChanged", "UpdatePlayerListOnNameChange", function(ply, oldName, newName)
    SortPlayerList()
end)

hook.Add("PlayerDeath", "HandleDeath", function(victim, inflictor, attacker)
	respawnTime = GetConVar("gmc_respawntime_coop"):GetInt()
    -- Set the respawn delay
    respawnTimers[victim:SteamID()] = CurTime() + respawnTime
	
	if victim:IsPlayer() then
		for k,ply in pairs(player.GetAll()) do
			if ply:GetObserverTarget() == victim then
				victim:SpectateEntity(victim:GetRagdollEntity())
			end
		end
	end
	
	-- Make the player spectate the person who killed them.
	if attacker:IsPlayer() && attacker:Alive() then
		victim:Spectate(OBS_MODE_CHASE)
		victim:SpectateEntity(attacker)
	else
		victim:Spectate(OBS_MODE_CHASE)
		victim:SpectateEntity(victim:GetRagdollEntity())
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
    if not ply:Alive() then
        if cmd:KeyDown(IN_ATTACK) && CanSwitchSpectateTarget(ply) then
            NextSpectateTarget(ply)
        elseif cmd:KeyDown(IN_ATTACK2) && CanSwitchSpectateTarget(ply) then
            PreviousSpectateTarget(ply)
        end
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

local function FindNextValidTarget(ply, startIndex, step)
    local teamID = ply:Team()
    local listSize = #playerList
    local currentIndex = startIndex

    while true do
        currentIndex = currentIndex + step

        -- Wrap around the list if we reach the end or start
        if currentIndex > listSize then
            currentIndex = 1
        elseif currentIndex < 1 then
            currentIndex = listSize
        end

        local target = playerList[currentIndex] or nil
        
		if target:IsValid() then
			if target:Alive() and target:Team() == teamID then
				return target
			end
        end
		
        -- Stop if we've cycled through all players without finding a valid target
        if currentIndex == startIndex then
            return nil
        end
    end
end

function NextSpectateTarget(ply)
    local currentTarget = ply:GetObserverTarget()
    local startIndex = table.KeyFromValue(playerList, currentTarget) or 1
    local nextTarget = FindNextValidTarget(ply, startIndex, 1)
    
	if nextTarget == nil then return end
	
    if nextTarget:Alive() then 
		if SERVER then
			ply:SpectateEntity(nextTarget)
		end
    end
end

function PreviousSpectateTarget(ply)
    local currentTarget = ply:GetObserverTarget()
    local startIndex = table.KeyFromValue(playerList, currentTarget) or 1
    local previousTarget = FindNextValidTarget(ply, startIndex, -1)
    
	if previousTarget == nil then return end
	
    if previousTarget:Alive() then
		if SERVER then
			ply:SpectateEntity(previousTarget)
		end
    end
end