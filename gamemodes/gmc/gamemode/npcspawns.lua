include("shared.lua")
include("particles.lua")

game.AddParticles( "particles/teleported_fx.pcf" )

local spawnableNPCs = {}

local npcDataDirectory = "gmc/npcs/"
local npcFiles = file.Find(npcDataDirectory .. "*", "DATA")

local GAMEMODE_MONSTER_THRESHOLD = 3

table.Empty(spawnableNPCs)
for _, filename in ipairs(npcFiles) do
	-- Construct the full file path
	local filePath = npcDataDirectory .. filename
	
	-- Read the contents of the file
	local fileContents = file.Read(filePath, "DATA")

	-- Process the file contents (you might want to parse it if it's in a specific format)
	fileContents = util.JSONToTable(fileContents)
		
	if fileContents.isminion == "false" then
		table.insert(spawnableNPCs, fileContents)
	end
			
	npcsRegistered = true
end

if SERVER then
    util.AddNetworkString("SendArchivedNPCs")
	util.AddNetworkString("ReceiveArchivedNPC")
	util.AddNetworkString("DeleteArchivedNPC")

    local function SendArchivedNPCsToClient(ply)
        if ply:IsSuperAdmin() then
            net.Start("SendArchivedNPCs")
				net.WriteTable(spawnableNPCs)
            net.Send(ply)
        end
    end

    concommand.Add("gmc_updatenpcs", function(ply)
        if ply:IsSuperAdmin() then
            SendArchivedNPCsToClient(ply)
        else
            print("====SUPERADMINS ONLY!=====")
        end
    end)
	
	net.Receive("ReceiveArchivedNPC", function(len,ply)
		if !ply:IsSuperAdmin() then return end
		local newnpc = net.ReadTable()
		local filename = npcDataDirectory .. newnpc.name .. ".txt"
		
		for k, npc in ipairs(spawnableNPCs) do
			if npc.name == newnpc.name then
				table.remove(spawnableNPCs, k)
			end
		end

		table.insert(spawnableNPCs, newnpc)
		
		-- Construct the line with the NPC configuration
		local line = util.TableToJSON( newnpc, true )

		-- Create the folder if it doesn't exist
		if not file.IsDir(npcDataDirectory, "DATA") then
			file.CreateDir(npcDataDirectory)
		end
		
		-- Write the line to the specific NPC's file
		file.Write(filename, line)
	end)
	
	net.Receive("DeleteArchivedNPC", function(len,ply)
		if !ply:IsSuperAdmin() then return end
		local deletednpc = net.ReadTable()
		local filename = npcDataDirectory .. string.lower(deletednpc.name) .. ".txt"
		
		for k, npc in ipairs(spawnableNPCs) do
			if npc.name == deletednpc.name then
				table.remove(spawnableNPCs, k)
			end
		end
		
		net.Start("SendArchivedNPCs")
			net.WriteTable(spawnableNPCs)
        net.Send(ply)

		file.Delete(filename)
	end)
end

if GetConVar("gmc_gamemode"):GetInt() < GAMEMODE_MONSTER_THRESHOLD then
	timer.Create( "NPCSpawner", GetConVar("gmc_spawnwave_time"):GetFloat(), 0, function()
		-- Call all neccesary variables outside of waveSize loop
		-- We need to do this to optimize the code
		local waveSize = GetConVar("gmc_spawnwave_size"):GetInt()
        local monstersBase = GetConVar("gmc_monsters_base"):GetInt()
        local monstersScale = GetConVar("gmc_monsters_scale"):GetInt()
        local maxNPCs = GetConVar("gmc_monsters_max"):GetInt()
        local maxLarge = GetConVar("gmc_largemonsters_max"):GetInt()
        local maxHuge = GetConVar("gmc_hugemonsters_max"):GetInt()
        local maxMassive = GetConVar( "gmc_massivemonsters_max" ):GetInt()
		local maxBoss = GetConVar( "gmc_boss_max" ):GetInt()
		local BossCooldown = GetConVar( "gmc_boss_cooldown" ):GetInt()
		local BossRandom = GetConVar( "gmc_boss_window" ):GetInt()
		
		local totalNPCs = monstersBase + (monstersScale * #player.GetHumans())
		
		for i = 0, waveSize do
			-- These two have to be called here because we need to account for the NPCs
			-- That were spawned in during the wave.
			local activeNPCs, activeLarge, activeHuge, activeMassive, activeBoss = 0, 0, 0, 0, 0
			local allEnts = ents.GetAll()
			
			for _, ent in pairs(allEnts) do
				if ent:IsNPC() then
					if ent.Minion == true then
						continue
					end

					-- Increment counters based on size/type
					activeNPCs = activeNPCs + 1
					if ent.Size == "Large" then
						activeLarge = activeLarge + 1
					elseif ent.Size == "Huge" then
						activeHuge = activeHuge + 1
					elseif ent.Size == "Massive" then
						activeMassive = activeMassive + 1
					elseif ent.Boss then
						activeBoss = activeBoss + 1
					end
				end
			end
			
			if (activeNPCs < totalNPCs and activeNPCs < maxNPCs) then
				local totalWeight = 1
				local npcData
				
				for k, npc in pairs(spawnableNPCs) do
					npc.minWin = totalWeight
					totalWeight = totalWeight + npc.weight
					npc.maxWin = totalWeight
				end
				
				local pickedNPC = math.random(1, totalWeight)
				
				for k, npc in pairs(spawnableNPCs) do
					if pickedNPC > npc.minWin && pickedNPC < npc.maxWin then
						npcData = npc
					end
				end
				
				local npclevel = 0
				for _, ply in pairs(player.GetHumans()) do
					npclevel = npclevel + ply:GetNWInt("plyLevel")
				end
					
				npclevel = math.Round(npclevel/(table.Count(player.GetHumans())))
				
				local potentialspawns = {}
				
				for _, spawnpoint in ipairs(spawnpoints) do
					local position = spawnpoint.Position
					local category = spawnpoint.Category
					local spawntype = spawnpoint.Type
					local bossSpawn = tobool(spawnpoint.Option1)
				
					local entitiesNearSpawn = ents.FindInSphere(position, 50)
						
					local isBlocked = false
						
					for _, entity in pairs(entitiesNearSpawn) do
						if IsValid(entity) and (entity:IsPlayer() || entity:IsNPC()) then
							isBlocked = true
							break 
						end
					end
						
					-- Only add potential spawns if not blocked and the conditions are met
					if not isBlocked && npcData != nil && category == "NPCs" then
						-- Boss Spawns
						if (bossSpawn && tobool(npcData.isboss) && activeBoss < maxBoss) && !timer.Exists("Boss Cooldown") then
							if (spawntype == "Large" && tobool(npcData.islarge) && activeLarge < maxLarge) then
								table.insert(potentialspawns, position)
								BossCooldown = BossCooldown + math.Rand(0, BossRandom)
								timer.Create( "Boss Cooldown", BossCooldown, 1, function() end)
							elseif (spawntype == "Huge" && tobool(npcData.ishuge) && activeLarge < maxLarge) then
								table.insert(potentialspawns, position)
								BossCooldown = BossCooldown + math.Rand(0, BossRandom)
								timer.Create( "Boss Cooldown", BossCooldown, 1, function() end)
							elseif (spawntype == "Massive" && tobool(npcData.ismassive) && activeLarge < maxLarge) then
								table.insert(potentialspawns, position)
								BossCooldown = BossCooldown + math.Rand(0, BossRandom)
								timer.Create( "Boss Cooldown", BossCooldown, 1, function() end)
							elseif (spawntype == "Normal" && tobool(npcData.islarge) == false) then
								table.insert(potentialspawns, position)
								BossCooldown = BossCooldown + math.Rand(0, BossRandom)
								timer.Create( "Boss Cooldown", BossCooldown, 1, function() end)
							end
						end
						-- Non-boss Spawns
						if (!bossSpawn && !tobool(npcData.isboss)) then
							if (spawntype == "Large" && tobool(npcData.islarge) && activeLarge < maxLarge) then
								table.insert(potentialspawns, position)
							elseif (spawntype == "Huge" && tobool(npcData.ishuge) && activeHuge < activeHuge) then
								table.insert(potentialspawns, position)
							elseif (spawntype == "Massive" && tobool(npcData.ismassive) && activeMassive < activeMassive) then
								table.insert(potentialspawns, position)
							elseif (spawntype == "Normal" && tobool(npcData.islarge) == false) then
								table.insert(potentialspawns, position)
							end
						end
					end
				end
				if #potentialspawns > 0 && npcData != nil then
					local selectedpos = table.Random(potentialspawns)
					ParticleEffect( "teleportedin_neutral", selectedpos, Angle( 0, 0, 0 ) )
					local enemy = ents.Create(npcData.class)
					enemy.Level = npclevel
					enemy.EXP = ((npcData.baseexp + (npcData.explvl * enemy.Level)))
					enemy.Name = npcData.name
					enemy.Team = "Monsters"
					enemy.Damage = ((npcData.basedamage + (npcData.damagelvl * enemy.Level)))
					if tobool(npcData.islarge) then
						enemy.Size = "Large"
					elseif tobool(npcData.ishuge) then
						enemy.Size = "Huge"
					elseif tobool(npcData.ismassive) then
						enemy.Size = "Massive"
					else
						enemy.Size = "Normal"
					end
					if tobool(npcData.isboss) then
						enemy.Boss = true
					end
					if tobool(npcData.isminion) then
						enemy.Minion = true
					else
						enemy.Minion = false
					end
					enemy:SetPos(selectedpos)
					enemy:SetModelScale(npcData.scale, 0)
					enemy:SetColor(Color(npcData.color.red, npcData.color.blue, npcData.color.green, npcData.color.alpha))
					enemy:Spawn()
					if npcData.weapon && npcData.weapon != "None" then
						enemy:Give(npcData.weapon)
					end
					enemy:SetHealth((npcData.basehealth + (npcData.healthlvl * enemy.Level)))
					enemy:SetMaxHealth((npcData.basehealth + (npcData.healthlvl * enemy.Level)))
					enemy:SetNWInt("NPCLevel", enemy.Level)
					enemy:SetNWString("NPCName", enemy.Name)
					enemy:SetNPCState(NPC_STATE_ALERT)
				end	
			end
		end
	end)
end

function GM:Initialize()
	spawnpoints = LoadSpawnConfigurationFromFile()
end

cvars.AddChangeCallback("gmc_gamemode", function(convar, old, new)
    if tonumber(new) < GAMEMODE_MONSTER_THRESHOLD then
		if timer.Exists("NPCSpawner") then
			timer.Start("NPCSpawner")
		end
	else
		if timer.Exists("NPCSpawner") then
			timer.Stop("NPCSpawner")
			local allEnts = ents.GetAll()
			for _, ent in pairs(allEnts) do
				if ent:IsNPC() && ent.Team == "Monsters" then
					local d = DamageInfo()
					d:SetDamage( ent:Health() * 100 )
					d:SetDamageType( DMG_DISSOLVE )
					ent:TakeDamageInfo( d )
					SafeRemoveEntityDelayed( ent, 3 )
				end
			end
		end
	end
end)

hook.Add("OnEntityCreated", "NPCStats", function(entity)
	if IsValid(entity) then
		
		if !entity:IsNPC() then
			if !entity:IsNextBot() then
			return end
		end
		
		local possibleNPCs = {}
		timer.Simple(0.01, function()
			local npclevel = 0
			for _, ply in pairs(player.GetHumans()) do
				npclevel = npclevel + ply:GetNWInt("plyLevel")
			end

			npclevel = math.Round(npclevel / (table.Count(player.GetHumans())))

			-- Check if the entity and its owner are both valid
			if IsValid(entity) and IsValid(entity:GetOwner()) then
				for _, npc in pairs(spawnableNPCs) do
					if npc.class == entity:GetClass() then
						table.insert(possibleNPCs, npc)
					end
				end

				if #possibleNPCs == 0 then
					entity:Remove()
					print("Something just attempted to create an NPC that isn't accounted for by your NPC list. Please add " .. entity:GetClass() .. " to the spawn pool. If you don't want it to spawn naturally, set spawn weight to 0")
				else
					local npcData = table.Random(possibleNPCs)
					entity.Level = npclevel
					entity.EXP = ((npcData.baseexp + (npcData.explvl * entity.Level)))
					entity.Name = npcData.name
					entity.Team = "Monsters"
					entity.Damage = ((npcData.basedamage + (npcData.damagelvl * entity.Level)))
					entity:SetModelScale(npcData.scale, 0)
					entity:SetColor(Color(npcData.color.red, npcData.color.blue, npcData.color.green, npcData.color.alpha))
					entity:SetHealth((npcData.basehealth + (npcData.healthlvl * entity.Level)))
					entity:SetMaxHealth((npcData.basehealth + (npcData.healthlvl * entity.Level)))
					entity:SetNWInt("NPCLevel", entity.Level)
					entity:SetNWString("NPCName", entity.Name)
				end
			end
			
			local allEnts = ents.GetAll()
			for _, ent in pairs(allEnts) do
				if IsValid(ent) && IsValid(entity) then
					if (ent:IsNPC() || ent:IsNextBot()) && ent.Team == entity.Team then
						entity:AddEntityRelationship( ent, D_LI, math.huge )
						ent:AddEntityRelationship( entity, D_LI, math.huge )
					elseif ent:IsNPC() || ent:IsNextBot() then
						entity:AddEntityRelationship( ent, D_HT, math.huge )
						ent:AddEntityRelationship( entity, D_HT, math.huge )
					elseif ent:IsPlayer() then
						entity:AddEntityRelationship( ent, D_HT, math.huge )
					end
				end
			end
		end)
	end
end)