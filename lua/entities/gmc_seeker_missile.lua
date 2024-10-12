AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")  -- Define a base class for the entity

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Seeker Missile"
ENT.Author = "Kiddley"
ENT.Information = "A custom missile."
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = false
ENT.AdminOnly = false

-- Define customizable values
ENT.Damage = 0
ENT.Owner = nil
ENT.FreezeTime = 8
ENT.FreezeAmount = 0.5
ENT.FreezeRadius = 200
ENT.Detonated = false

if SERVER then
	util.AddNetworkString("SetFrozenMaterial")
	util.AddNetworkString("ClearFrozenMaterial")
end

function ENT:Initialize()
    self:SetModel("models/weapons/w_models/w_flaregun_shell.mdl")
    self:SetSkin(1)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(0)
	end
    
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
end

hook.Add("GravGunOnPickedUp", "TrackGravGunPickup_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_ice_grenade" then
		ent.Owner = ply
		ent:SetNWEntity("Owner", ply)
    end
end)

hook.Add("GravGunOnDropped", "TrackGravGunDrop_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_ice_grenade" then
        ent.IsHeldByPlayer = false
    end
end)

function ENT:SpawnFunction(ply, tr, class)
    if not tr.Hit then return end
    local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create(class)
    ent:SetPos(SpawnPos)
    ent.Owner = ply
    ent:Spawn()
    ent:Activate()
    return ent
end

function ENT:Detonate()
    -- Find entities within the freeze radius
    local entities = ents.FindInSphere(self:GetPos(), self.FreezeRadius)
    for _, ent in ipairs(entities) do
        -- If the entity is an NPC or player, apply the freeze effect
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() and !ent.IsFrozen then
            self:ApplyFreezeEffect(ent)
        end
    end

    -- Play detonation sound and remove the grenade entity
    self:EmitSound("weapons/gas_can_explode.wav")
    self:Remove()
end

function ENT:ApplyFreezeEffect(ent)
	if !ent.FreezeActive then
		if ent:IsPlayer() then
			-- Slow down the player
			ent.originalWalkSpeed = ent:GetWalkSpeed()
			ent.originalRunSpeed = ent:GetRunSpeed()
			if self.FreezeAmount > 0 then
				ent:SetWalkSpeed(ent.originalWalkSpeed * self.FreezeAmount)
				ent:SetRunSpeed(ent.originalRunSpeed * self.FreezeAmount)
			else
				ent:SetWalkSpeed(1)
				ent:SetRunSpeed(1)
			end
			
			ent:SetMaterial("status/frozen")
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("status/frozen")  -- Set the world model material
				local viewModel = ent:GetViewModel()  -- Get the viewmodel for the player
				if IsValid(viewModel) then
					net.Start("SetFrozenMaterial")
					net.Send(ent)
				end
			end
			
			ent.FreezeActive = true
		elseif ent:IsNPC() then
			-- Apply the freeze effect to NPCs
			ent.FreezeActive = true  -- Mark the entity as frozen
			
			ent:SetMaterial("status/frozen")
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("status/frozen")  -- Set the world model material
			end
			
			-- Freeze the NPC's angles (prevents turning)
			ent.FrozenAngles = ent:GetAngles()  -- Store original angles
			ent.FrozenPos = ent:GetPos()  -- Store original angles
			
			ent:NextThink(CurTime() + self.FreezeTime)
		elseif ent:IsNextBot() then
			-- Apply the freeze effect to NPCs
			ent.FreezeActive = true  -- Mark the entity as frozen
			
			ent:SetMaterial("status/frozen")
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("status/frozen")  -- Set the world model material
			end
			
			ent.FrozenPos = ent:GetPos()
			ent:NextThink(CurTime() + self.FreezeTime)
		end
		-- Restore speed after the freeze time
		timer.Simple(self.FreezeTime, function()
			Thaw(ent)
		end)
	end
end

function ENT:PhysicsCollide(data, phys)
	if !self.Detonated then
		self.Detonated = true
		self:Detonate()
	end
end

function Thaw(ent)
	if IsValid(ent) and ent.FreezeActive then
		if ent:IsNPC() then
			timer.Simple(0.01, function() 
				ent:SetPos(ent.FrozenPos)
			end)
		elseif ent:IsPlayer() then
			ent:SetWalkSpeed(ent.originalWalkSpeed)
			ent:SetRunSpeed(ent.originalRunSpeed)
			ent.originalWalkSpeed = nil
			ent.originalRunSpeed = nil
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				local viewModel = ent:GetViewModel()
				if IsValid(viewModel) then
					net.Start("ClearFrozenMaterial")
					net.Send(ent)
				end
			end
		elseif ent:IsNextBot() then
			ent:SetPos(ent.FrozenPos)
		end
		
		ent.FreezeActive = false
		ent:SetMaterial("")
		
		local weapon = ent:GetActiveWeapon()
        if IsValid(weapon) then
			weapon:SetMaterial("")  -- Clear the world model material
        end
	end
end

if CLIENT then
	hook.Add("PreDrawViewModel", "SetFrozenMaterialViewModel", function(vm, ply, weapon)
		if ply.FreezeActive then
			if IsValid(vm) then
				vm:SetMaterial("status/frozen")  -- Apply the frozen material
			end
			
			if IsValid(ply:GetHands()) then
				ply:GetHands():SetMaterial("status/frozen")
			end
			
			
		else
			if IsValid(vm) then
				vm:SetMaterial("")  -- Apply the frozen material
			end
			
			if IsValid(ply:GetHands()) then
				ply:GetHands():SetMaterial("")
			end
		end
	end)
	
	hook.Add( "RenderScreenspaceEffects", "FrozenEffect", function()
		local ply = LocalPlayer()
		if ply.FreezeActive then
			DrawMaterialOverlay( "status/frozenoverlay", 0 )
		end
	end )
	
	net.Receive("SetFrozenMaterial", function()
		local ply = LocalPlayer()
		ply.FreezeActive = true
	end)

	net.Receive("ClearFrozenMaterial", function()
		local ply = LocalPlayer()
		ply.FreezeActive = false
	end)
end