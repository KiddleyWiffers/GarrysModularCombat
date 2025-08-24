ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "GMC Spawnpoint"
ENT.Author = "Kiddley"
ENT.Purpose = "Place these around the maps to set spawn points for weapons and for Garry's Modular Combat"
ENT.Instructions = "Use the entity to open the weapon selector GUI"
ENT.Spawnable = true
ENT.Category = "Garry's Modular Combat"

if engine.ActiveGamemode() != "gmc" then
	concommand.Add("gmc_savespawns", function(ply, cmd, args, argStr)
		spawnpointents = ents.FindByClass( "gmc_weselector" )
		proppointents = ents.FindByClass("gmc_mapent")
		local spawnpoints = {}
		if spawnpointents then
			for k,v in pairs(spawnpointents) do
				local spawnpos = v:GetPos()
				local spawnang = v:GetAngles()
				local spawnc = v:GetNWString("SpawnCategory")
				local spawnt = v:GetNWString("SpawnType")
				local spawn1 = v:GetNWString("ExtraOption1")
				local spawn2 = v:GetNWString("ExtraOption2")
				local spawn3 = v:GetNWString("ExtraOption3")
				
				local spawnpoint = {
					["Ent"] = "gmc_weselector",
					["Position"] = spawnpos,
					["Angle"] = spawnang,
					["Category"] = spawnc,
					["Type"] = spawnt,
					["Option1"] = spawn1,
					["Option2"] = spawn2,
					["Option3"] = spawn3
				}
				
				table.insert( spawnpoints, spawnpoint)
			end
			if proppointents then
				for k,v in pairs(proppointents) do
					local spawnpos = v:GetPos()
					local spawnang = v:GetAngles()
					local spawnc = v:GetNWString("PropOrEnt")
					local spawnt = v:GetNWString("Entry")
					local spawnphys = v:GetPhysicsObject()
					if IsValid(spawnphys) then
						local spawnf = spawnphys:IsMotionEnabled()
						
						local spawnpoint = {
							["Ent"] = "gmc_mapent",
							["Position"] = spawnpos,
							["Angle"] = spawnang,
							["Category"] = spawnc,
							["Type"] = spawnt,
							["Frozen"] = spawnf
						}
						table.insert(spawnpoints, spawnpoint)
					end
				end
			end
			SaveSpawnConfigurationToFile(spawnpoints)
		end
	end)

	concommand.Add("gmc_loadspawns", function(ply, cmd, args, argStr)
		local spawnpoints = LoadSpawnConfigurationFromFile()
		local currentspawns = ents.FindByClass( "gmc_weselector" )
		table.Add(currentspawns, ents.FindByClass("gmc_mapent"))
		if currentspawns then
			for k,v in pairs(currentspawns) do
				v:Remove()
			end
		end
		if spawnpoints then
			for _, spawnpointData in ipairs(spawnpoints) do
				local position = spawnpointData.Position
				local angle = spawnpointData.Angle
				local category = spawnpointData.Category
				local spawntype = spawnpointData.Type
				local ent = spawnpointData.Ent
				local newEntity = ents.Create(ent)
				newEntity:SetPos(position)
				newEntity:SetAngles(angle)
				newEntity:Spawn()
				if ent == "gmc_weselector" then
					local option1 = spawnpointData.Option1
					local option2 = spawnpointData.Option2
					local option3 = spawnpointData.Option3
					
					newEntity:SetNWString("SpawnCategory", category)
					newEntity:SetNWString("SpawnType", spawntype)
					newEntity:SetNWString("ExtraOption1", option1)
					newEntity:SetNWString("ExtraOption2", option2)
					newEntity:SetNWString("ExtraOption3", option3)
				elseif ent == "gmc_mapent" then
					local option1 = spawnpointData.Frozen
					
					ChangeModel(newEntity, category, spawntype)
				
					newEntity:SetNWString("PropOrEnt", category)
					newEntity:SetNWString("Entry", spawntype)
					
					newEntity:GetPhysicsObject():EnableMotion(option1)
				end
			end
		else
			print("No spawn configuration found.")
		end
	end)
end

function LoadSpawnConfigurationFromFile()
    local spawnpoints = {}

    local data = file.Read("gmc/mapdata/" .. game.GetMap() .. ".txt", "DATA") -- Read the saved data from the file

    if data then
        spawnpoints = util.JSONToTable(data)
    else
        print("Failed to load spawn configuration.")
    end

    return spawnpoints
end

function SaveSpawnConfigurationToFile(spawnData)
	local folderName = "gmc/mapdata"
    local filename = folderName .. "/" .. game.GetMap() .. ".txt"
    local fileContent = ""

    -- Construct the line with the spawn configuration
    local line = util.TableToJSON( spawnData, true )

	-- Create the folder if it doesn't exist
    if not file.IsDir(folderName, "DATA") then
        file.CreateDir(folderName)
    end
	
    -- Write the line to the specific map file
    file.Write(filename, line)

    print("Spawn Configuration saved to file:", filename)
end