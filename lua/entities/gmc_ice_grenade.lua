AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")  -- Define a base class for the entity

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Cryo Grenade"
ENT.Author = "Kiddley"
ENT.Information = "A custom cryo grenade."
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Damage = 0
ENT.Owner = nil
ENT.FreezeTime = 8
ENT.FreezeAmount = 0.5
ENT.FreezeRadius = 200
ENT.Detonated = false
ENT.Level = nil
ENT.FriendlyFire = true

list.Set("OverrideMaterials", "status/frozen", "status/frozen")

function ENT:Initialize()
    self:SetModel("models/weapons/w_models/w_flaregun_shell.mdl")
    self:SetSkin(1)
	
	if engine.ActiveGamemode() == "gmc" and self.Level then
		self.FreezeAmount = (0.1 * self.Level)
		self.FriendlyFire = true
	end
    
    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(0)
	end
    
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
end

hook.Add("PhysgunPickup", "PoisonDartPhysgunPickup", function(ply, ent)
	if ent:GetClass() == "gmc_fire_grenade" then
		ent.HeldByPhysgun = true
	end
end)

hook.Add("PhysgunDrop", "PoisonDartPhysgunDrop", function(ply, ent)
	if ent:GetClass() == "gmc_fire_grenade" then
		ent.HeldByPhysgun = false
	end
end)

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
    local entities = ents.FindInSphere(self:GetPos(), self.FreezeRadius)
    for _, ent in ipairs(entities) do
	if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() and !ent.IsFrozen then
			if self.FriendlyFire then
				self:ApplyFreezeEffect(ent)
			else
				local plyteam = self.Owner:Team()
				local hitteam = ent.GMCTeam or ent:Team()
				if plyteam == 5 and ent.Owner != self.Owner and ent != self.Owner then
					self:ApplyFreezeEffect(ent)
				elseif plyteam == hitteam then
					self:ApplyFreezeEffect(ent)
				end
			end
        end
    end

    self:EmitSound("weapons/gas_can_explode.wav")
	ParticleEffect("ice_bomb", self:GetPos(), Angle(0,0,0))
    self:Remove()
end

function ENT:ApplyFreezeEffect(ent)
	if !ent:GetNWBool("FreezeActive", false) then
		if ent:IsPlayer() then
			ent.originalWalkSpeed = ent:GetWalkSpeed()
			ent.originalRunSpeed = ent:GetRunSpeed()
			if self.FreezeAmount > 0 then
				ent:SetWalkSpeed(math.Clamp(ent.originalWalkSpeed - (ent.originalWalkSpeed * self.FreezeAmount), 1, 400))
				ent:SetRunSpeed(math.Clamp(ent.originalRunSpeed - (ent.originalRunSpeed * self.FreezeAmount), 1, 400))
			else
				ent:SetWalkSpeed(1)
				ent:SetRunSpeed(1)
			end
			
			ent:SetMaterial("status/frozen")
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("status/frozen")
			end
			
			ent:SetNWBool("FreezeActive", true)
		elseif ent:IsNPC() then
			ent:SetNWBool("FreezeActive", true)
			ent:SetMaterial("status/frozen")
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("status/frozen")
			end
			
			ent.FrozenAngles = ent:GetAngles()
			ent.FrozenPos = ent:GetPos()
			ent:NextThink(CurTime() + self.FreezeTime)
		elseif ent:IsNextBot() then
			ent:SetNWBool("FreezeActive", true)
			ent:SetMaterial("status/frozen")
			
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("status/frozen")
			end
			
			ent.FrozenPos = ent:GetPos()
			ent:NextThink(CurTime() + self.FreezeTime)
		end

		timer.Simple(self.FreezeTime, function()
			if IsValid(ent) then
				Thaw(ent)
			end
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
	if IsValid(ent) and ent:GetNWBool("FreezeActive", false) then
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
					ent:SetNWBool("FreezeActive", false)
				end
			end
		elseif ent:IsNextBot() then
			ent:SetPos(ent.FrozenPos)
		end
		
		ent:SetNWBool("FreezeActive", false)
		ent:SetMaterial("")
		
		local weapon = ent:GetActiveWeapon()
        if IsValid(weapon) then
			weapon:SetMaterial("")
        end
	end
end

if CLIENT then
	hook.Add("RenderScreenspaceEffects", "FrozenEffect", function()
		local ply = LocalPlayer()
		if ply:GetNWBool("FreezeActive", false) then
			DrawMaterialOverlay("status/frozenoverlay", 0)
		end
	end)
end

function ENT:Think()
    if SERVER and not self.HeldByPhysgun then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            local velocity = phys:GetVelocity()
			if velocity:Length() > 10 then
				local desiredDir = velocity:GetNormalized()
				local targetAng = desiredDir:Angle()
				self:SetAngles(targetAng)
				phys:SetVelocity(velocity)
			end
        end
    end

    self:NextThink(CurTime())
    return true
end

hook.Add("EntityTakeDamage", "FrozenDeathHandler", function(ent, dmginfo)
    if ent:Health() <= dmginfo:GetDamage() and ent:GetNWBool("FreezeActive", false) then
		EmitSound("physics/glass/glass_sheet_break2.wav", ent:GetPos(), 0, CHAN_STATIC, 2, 75)
		--ParticleEffectAttach("ice_bomb_shatter", PATTACH_ABSORIGIN, ent, 0)
		if ent:IsPlayer() then
			ent:SetMaterial("")
				
			local weapon = ent:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetMaterial("")
			end
				
			ent:SetNWBool("FreezeActive", false)
		end
    end
end)

hook.Add("CreateClientsideRagdoll", "RemoveFrozenRagdoll", function(ent, ragdoll)
    if ent:GetNWBool("FreezeActive", false) then
        timer.Simple(0, function()
			ragdoll:CreateParticleEffect("ice_bomb_shatter", 0, {PATTACH_ABSORIGIN, nil, nil,})
            if IsValid(ragdoll) then
                ragdoll:Remove()
            end
        end)
    end
end)