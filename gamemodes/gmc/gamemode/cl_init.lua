AddCSLuaFile("gui/mchud.lua")
AddCSLuaFile("gui/mcmenu.lua")
AddCSLuaFile("commands.lua")
AddCSLuaFile("gui/npccreator.lua")

include("gmcscoreboard.lua")
include( "gui/mchud.lua" )
include("gui/mcmenu.lua")
include("gui/npccreator.lua")
include( "commands.lua" )

surface.CreateFont( "GMCTitleFont", {font = "Verdana", extended = false, size = 40, weight = 500, blursize = 0, antialias = true, shadow = true, outline = false,} )
surface.CreateFont( "GMCDescriptionFont", {font = "Verdana", extended = false, size = 25, weight = 500, blursize = 0, antialias = true, shadow = true, outline = false,} )
surface.CreateFont( "GMCSmallFont", {font = "Verdana", extended = false, size = 16, weight = 500, blursize = 0, antialias = false, shadow = true, outline = false,} )
surface.CreateFont( "GMCScoreboardFont", {font = "Verdana", extended = false, size = 18, weight = 500, blursize = 0, antialias = false, shadow = true, outline = false,} )

local chatopen = false

function GM:HUDDrawTargetID()
	local tr = LocalPlayer():GetEyeTrace()
    local target = tr.Entity
	
	if IsValid(target) && IsEntity( target ) && LocalPlayer():Alive() then
        local text = ""
        
        if target:IsPlayer() then
            local level = target:GetLevel()
            text = target:Nick() .. "\nLevel: " .. level
        elseif target:IsNPC() then
			local name = target:GetNWString("NPCName")
			local level = target:GetNWInt("NPCLevel")
            text = name .. "\nLevel: " .. level
        end
        
        -- Draw the additional information
		if target:IsPlayer() then
			local lines = string.Explode("\n", text)
			for i, line in ipairs(lines) do
				draw.DrawText(text, "GMCSmallFont", (ScrW() / 2), (ScrH() / 2) + 50, target:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER)
			end
		else
			local lines = string.Explode("\n", text)
			for i, line in ipairs(lines) do
				draw.DrawText(text, "GMCSmallFont", ScrW() / 2, ScrH() / 2 + 50, Color(255,255,60), TEXT_ALIGN_CENTER)
			end
		end
    end
end

local ModuleDelay = 0

function GM:Think()
    for com, bind in pairs(modulebinds) do
        if ModuleDelay < CurTime() then
            if input.IsKeyDown(bind) && !gui.IsGameUIVisible() && !Menu:IsVisible() && !chatopen then
                net.Start("GMCast")
					net.WriteString(com)
                net.SendToServer()
                ModuleDelay = CurTime() + 0.4
            end
        end
    end
end

hook.Add( "StartChat", "ClientStartTyping", function()
	chatopen = true
end )

hook.Add( "FinishChat", "ClientFinishTyping", function()
	chatopen = false
end )

-- HEV Voiceline code for playing sounds clientside for various events.

local vld = 0 -- Voiceline delay, so we don't annoy players with constant voiceline spam.
local vdm = GetConVar("gmc_hev_voiceline_delay_muliplier"):GetInt() -- Command to allow players more control over their voicelines
local hevactor = GetConVar("gmc_hev_voiceline_actor"):GetString() -- Command to allow players to pick their HEV suit voice
local fvd = 5 -- Flat voice line delay, this will be added to the length of each voiceline to determime how long before we play the next voiceline.


-- Creating the sounds for each line, and reloading them if the command changes.
local voicePackPath = "sound/gmc/suitvoices/".. hevactor .."/"  -- Base path to the voice pack folder
local playbackPath = "gmc/suitvoices/" .. hevactor .. "/"
local voiceLines = {
	"armorgone",
	"auxfull",
	"auxpowerlow",
	"death",
	"greeting",
	"hardhit",
	"ignited",
	"lowhealth",
	"neardeath",
	"poisoned",
	"radiated",
	"shocked",
	"splashed"
}

-- Function to get all variants for a given list of voice lines
local function GetAllVoiceLineVariants(voiceLines, path)
	local voiceVariants = {}
	
	for _, voiceLine in ipairs(voiceLines) do
		local files, _ = file.Find(path .. voiceLine .. "*.wav", "GAME")
		voiceVariants[voiceLine] = files
	end

	return voiceVariants
end

-- Get all voice line variants
local voiceLineVariants = GetAllVoiceLineVariants(voiceLines, voicePackPath)

-- Print out the variants for each voice line
for voiceLine, variants in pairs(voiceLineVariants) do
	print("Variants for '" .. voiceLine .. "': " .. #variants)
	for _, variant in ipairs(variants) do
		print("  " .. variant)
	end
end

-- Play a random variant of a specific voice line
local function PlayRandomVariant(voiceLine)
	local variants = voiceLineVariants[voiceLine]
	if variants and #variants > 0 then
		local randomIndex = math.random(1, #variants)
		local selectedVariant = playbackPath .. variants[randomIndex]
		surface.PlaySound(selectedVariant)
	else
		print("No variants found for " .. voiceLine)
	end
end

-- Add a callback to detect changes
cvars.AddChangeCallback("gmc_hev_voiceline_actor", OnHEVVAChanged, "HEVActorChanged")

hook.Add("InitPostEntity", "HEVGreeting", function(ply)
	-- We have to open and close the menu at the start of the game so we can initalize it.
	MCMenu()
	Menu:Close()
	
	PlayRandomVariant("greeting")
end)

-- Clientside Player Death Events
local respawnTime = 0
local attackerName = ""

gameevent.Listen( "entity_killed" )
hook.Add( "entity_killed", "HEVDeathResponse", function( data ) 
	local weapon = ents.GetByIndex(data.entindex_inflictor)
	local attacker = ents.GetByIndex(data.entindex_attacker)
	local victim = ents.GetByIndex(data.entindex_killed)
	
	attackerName = ""
	
	if victim == LocalPlayer() then
		PlayRandomVariant("death")
		
		if attacker:IsPlayer() then
			attackerName = tostring(attacker:Name())
		end
		if attacker:IsNPC() && !attacker:GetOwner():IsPlayer() then
			attackerName = attacker:GetNWString("NPCName")
		end
		respawnTime = (CurTime() + GetConVar("gmc_respawntime_coop"):GetInt())
	end
end )

hook.Add("HUDPaint", "RespawnHUD", function()
	if !LocalPlayer():Alive() && (attackerName ~= "" || attackerName ~= tostring(LocalPlayer():Name())) then
        draw.SimpleTextOutlined("Killed by: " .. attackerName, "GMCDescriptionFont", ScrW() / 2, 180, Color(230,207,40,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,200))
    end
    if !LocalPlayer():Alive() && respawnTime > CurTime() then
		local timeLeft = math.Round(respawnTime - CurTime())
        draw.SimpleTextOutlined("Respawn allowed in: " .. timeLeft, "GMCDescriptionFont", ScrW() / 2, 205, Color(230,207,40,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,200))
    end
	if LocalPlayer():GetObserverTarget():IsPlayer() then
		draw.SimpleTextOutlined("Spectating: " .. LocalPlayer():GetObserverTarget():Name(), "GMCScoreboardFont", ScrW() / 2, 20, Color(230,207,40,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,200))
	end
end)