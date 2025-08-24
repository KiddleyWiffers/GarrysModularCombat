ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "GMC Map Entity"
ENT.Author = "Kiddley"
ENT.Purpose = "Place these around the maps to set spawn points for props and entities in Garry's Modular Combat"
ENT.Instructions = "Use the entity to open the prop selector GUI. The frozen state will persist, meaning if you freeze the object with the physgun and then save, that object will be frozen in GMC. Use gmc_savespawns to save all entities on the map."
ENT.Spawnable = true
ENT.Category = "Garry's Modular Combat"

if engine.ActiveGamemode() != "gmc" then
	concommand.Add("gmc_convert_props_to_mapents", function(ply, cmd, args, argStr)
		for k, prop in pairs(ents.GetAll()) do
			if prop:GetClass() == "prop_physics" and not prop:CreatedByMap() then
				local mapent = ents.Create("gmc_mapent")
				local propphys = prop:GetPhysicsObject()
				if IsValid(propphys) then
					local frozen = propphys:IsMotionEnabled()
					mapent:Spawn()
					mapent:SetModel(prop:GetModel())
					mapent:PhysicsInit(SOLID_VPHYSICS)
					mapent:SetMoveType(MOVETYPE_VPHYSICS)
					mapent:SetNWString("Entry", prop:GetModel())
					mapent:SetPos(prop:GetPos())
					mapent:SetAngles(prop:GetAngles())
					prop:Remove()
					mapent:PhysWake()
					mapent:GetPhysicsObject():EnableMotion(frozen)
				end
			end
		end
	end)
	
	concommand.Add("print_all_vehicles", function(ply, cmd, args, argStr)
		local allVechs = list.Get("Vehicles")
		PrintTable(allVechs)
	end)
end