include("modules.lua")

local lvlexpbase = GetConVar("gmc_levelexp_base"):GetInt()
local lvlexpscale = GetConVar("gmc_levelexp_scale"):GetInt()
local lvlexppower = GetConVar("gmc_levelexp_power"):GetInt()

local defaultSuit = {
	SuitName = "New Suit",
	plyEXP = 0,
	plyLevel = 1,
	plySkillPoints = GetConVar("gmc_points_per_level"):GetInt(),
	tech = {},
	keybinds = {}
}

concommand.Add("reloadsuitdata", function(ply, cmd, args) LoadPlayerData(ply) end)

function MergeTables(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            MergeTables(target[key], value)
        else
            target[key] = value
        end
    end
end

function LoadPlayerData(ply)
    local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"
	
	ply.ModulesData = {}
	
	-- Initialize all modules to 0
	for mod, data in pairs(modules) do
        ply.ModulesData[mod] = 0
    end
	
    if file.Exists(dataPath, "DATA") then
        local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))
        if existingData then
			if ply:GetActiveSuit() == "" then
				ply:SetActiveSuit(existingData.activeSuit)
				print("Overriding Active Suit")
			end
			local suit = ply:GetActiveSuit()
            for k, suitData in pairs(existingData.suits) do
				if suit == tostring(k) then
					print(k)
					ply:SetEXP(suitData.plyEXP)
					ply:SetLevel(suitData.plyLevel)
					ply:SetSP(suitData.plySkillPoints)
					for mod, lvl in pairs(suitData.tech) do
						ply.ModulesData[mod] = lvl
					end
				end
            end
			net.Start("SendSuitInfoToClient")
				net.WriteTable(existingData)
			net.Send(ply)
			ply:SetActiveSuitName(existingData.suits[suit].SuitName)
			ply:SetEXPtoLevel((lvlexpscale * ply:GetLevel()) * lvlexppower)
            print("Loaded data for " .. ply:Nick())
        else
            print("Failed to load data for " .. ply:Nick() .. ", creating new save.")
			CreateNewData(ply)
			LoadPlayerData(ply)
        end
    else
        print("No data found for " .. ply:Nick() .. ", creating new save.")
        CreateNewData(ply)
		LoadPlayerData(ply)
    end
end

function CreateNewData(ply)
    local steamID64 = ply:SteamID64()
    if not steamID64 then
        return
    end

    local dataPath = "gmc/players/" .. steamID64 .. ".txt"

    if not file.Exists("gmc/players/", "DATA") then
        file.CreateDir("gmc/players/")
    end

    local datatable = {
        Player = ply:Nick(),
        activeSuit = "suit1", -- Set the active suit to "suit1"
        suits = {}
    }

    -- Create and initialize suits
    for i = 1, 5 do
        local suitKey = "suit" .. i
        local suitData = table.Copy(defaultSuit)

        -- Initialize tech for all suits
        for mod, data in pairs(modules) do
            suitData.tech[mod] = 0 -- Initialize all modules for the suit to level 0
        end
		
		-- Setup the values for suit1
        if suitKey == "suit1" then
            ply:SetEXP(suitData.plyEXP)
            ply:SetLevel(suitData.plyLevel)
            ply:SetSP(suitData.plySkillPoints)
			ply:SetActiveSuit(suitKey)
			ply:SetActiveSuitName(suitData.SuitName)
			ply:SetEXPtoLevel((lvlexpscale * ply:GetLevel()) * lvlexppower)
        end

        -- Add the suit data to the datatable
        datatable.suits[suitKey] = suitData
    end
	
    file.Write(dataPath, util.TableToJSON(datatable, true))
end

function SavePlayerData(ply)
    --if GetConVar("sv_cheats"):GetInt() <= 0 then
		local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"
		if file.Exists(dataPath, "DATA") then
			local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))
			if existingData then
				local suit = ply:GetActiveSuit()
				existingData.activeSuit = suit -- Find the active suit's data
				local activeSuitData = existingData.suits[suit]
				if activeSuitData then
					activeSuitData.plyEXP = ply:GetEXP() -- Update the active suit's properties
					activeSuitData.plyLevel = ply:GetLevel()
					activeSuitData.plySkillPoints = ply:GetSP()
					activeSuitData.SuitName = ply:GetActiveSuitName()
					for mod, data in pairs(modules) do -- Check for new tech modules and add them to the suit data
						if activeSuitData.tech[mod] == nil then activeSuitData.tech[mod] = ply.ModulesData[mod] end
					end

					for mod, _ in pairs(activeSuitData.tech) do -- Update tech for the active suit
						activeSuitData.tech[mod] = ply.ModulesData[mod]
					end

					table.sort(existingData)
					file.Write(dataPath, util.TableToJSON(existingData, true)) -- Save updated data back to the file
					print("Saved data for " .. ply:Nick())
				else
					print("Failed to save data for " .. ply:Nick() .. " - Active suit data not found.")
				end
			else
				print("Failed to save data for " .. ply:Nick() .. " - Existing data is invalid.")
			end
		else
			print("Failed to save data for " .. ply:Nick() .. " - Data file not found.")
		end
	--end
end

net.Receive("ChangeSuits", function(len, ply)
	ReceiveSecurity(ply, 3)
	local newSuit = net.ReadString()
	SavePlayerData(ply)
	ply:SetActiveSuit(newSuit)
	LoadPlayerData(ply)
	
	local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"
	local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))
	
	net.Start("SendSuitInfoToClient")
		net.WriteTable(existingData)
	net.Send(ply)

	SavePlayerData(ply)
	
	local d = DamageInfo()
	d:SetDamage(ply:Health() * 100)
	d:SetAttacker(ply)
	d:SetDamageType(DMG_DISSOLVE)
	
	ply:EmitSound("ambient/machines/teleport4.wav", 75, 100, 1, CHAN_AUTO)
	ply:GodDisable()
	ply:TakeDamageInfo(d)
end)

function ResetActiveSuitData(ply)
    local suit = ply:GetActiveSuit()
    local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"

    if file.Exists(dataPath, "DATA") then
        local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))

        if existingData and existingData.suits[suit] then

            local activeSuitData = existingData.suits[suit]

            -- Reset active suit's properties to default values
            activeSuitData.SuitName = defaultSuit.SuitName
            activeSuitData.plyEXP = defaultSuit.plyEXP
            activeSuitData.plyLevel = defaultSuit.plyLevel
            activeSuitData.plySkillPoints = defaultSuit.plySkillPoints
			
			ply:SetEXP(defaultSuit.plyEXP)
            ply:SetLevel(defaultSuit.plyLevel)
            ply:SetSP(defaultSuit.plySkillPoints)
			ply:SetActiveSuitName(defaultSuit.SuitName)
			ply:SetEXPtoLevel((lvlexpscale * ply:GetLevel()) * lvlexppower)
			
            for mod, _ in pairs(activeSuitData.tech) do
                activeSuitData.tech[mod] = 0
				ply.ModulesData[mod] = 0
            end
			
			for mod, bind in pairs(activeSuitData.keybinds) do
				if mod != "prev" and mod != "next" and mod != "selected" then
					activeSuitData.keybinds[mod] = 0
				elseif mod == "prev" then
					activeSuitData.keybinds[mod] = 36
				elseif mod == "next" then
					activeSuitData.keybinds[mod] = 13
				elseif mod == "selected" then
					activeSuitData.keybinds[mod] = 34
				elseif not IsValid(mod) then
					activeSuitData.keybinds["prev"] = 36
					activeSuitData.keybinds["next"] = 13
					activeSuitData.keybinds["selected"] = 34
				end
            end
			
            -- Save the updated active suit data back to the file
            SavePlayerData(ply)
            print("Reset active suit data for " .. ply:Nick())
			
			local d = DamageInfo()
			d:SetDamage(ply:Health() * 100)
			d:SetDamageType(DMG_DISSOLVE)
			ply:TakeDamageInfo(d)
        else
            print("Failed to reset active suit data for " .. ply:Nick() .. " - Active suit data not found.")
        end
    else
        print("Failed to reset active suit data for " .. ply:Nick() .. " - Data file not found.")
    end
end

net.Receive("ResetSuit", function(len, ply)
	ReceiveSecurity(ply, 3)
	ResetActiveSuitData(ply)
	local suit = ply:GetActiveSuit()
    local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"

    if file.Exists(dataPath, "DATA") then
        local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))
		net.Start("SendSuitInfoToClient")
			net.WriteTable(existingData)
		net.Send(ply)
	end
end)

net.Receive("BindModules", function(len, ply)
	ReceiveSecurity(ply, 20)
	local mod = net.ReadString()
	local key = net.ReadInt(9)
	local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"
	local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))
	
	if existingData then
		local suit = ply:GetActiveSuit()
			
		-- Find the active suit's data
		existingData.activeSuit = suit
		local activeSuitData = existingData.suits[suit]
		
		activeSuitData.keybinds[mod] = key
	end
	
	file.Write(dataPath, util.TableToJSON(existingData, true))
	
	net.Start("SendSuitInfoToClient")
		net.WriteTable(existingData)
	net.Send(ply)
end)

net.Receive("RenameSuit", function(len,ply)
	ReceiveSecurity(ply, 3)
	local curSuit = net.ReadString()
	local newName = net.ReadString()
	local dataPath = "gmc/players/" .. ply:SteamID64() .. ".txt"
	
	ply:SetActiveSuitName(newName)
	SavePlayerData(ply)
	
    local existingData = util.JSONToTable(file.Read(dataPath, "DATA"))
	net.Start("SendSuitInfoToClient")
		net.WriteTable(existingData)
	net.Send(ply)
end)