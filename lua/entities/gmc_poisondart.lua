AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Poison Dart"
ENT.Author = "Kiddley"
ENT.Information = "A custom poison dart."
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Damage = 0.5
ENT.Healing = 0.8
ENT.HealTicks = 10
ENT.Owner = nil
ENT.StickTime = 5
ENT.FriendlyFire = true

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create(ClassName)
	ent:SetPos(SpawnPos)
	ent.Owner = ply
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Initialize()
	self:SetModel("models/weapons/hunter_flechette.mdl")
	self:SetMaterial("models/weapons/poison_dart")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	
	if engine.ActiveGamemode() == "gmc" and self.Level then
		self.Damage = 0.25 + (0.05 * self.Level)
		self.HealTicks = 10 + math.floor(0.5 * self.Level)
		self.FriendlyFire = false
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableDrag(false)
		phys:SetMass(0)
	end

	self.Stuck = false
	self.HeldByPhysgun = false
	self.HitEntity = nil
end

hook.Add("PhysgunPickup", "PoisonDartPhysgunPickup", function(ply, ent)
	if ent:GetClass() == "gmc_poisondart" then
		ent.HeldByPhysgun = true
	end
end)

hook.Add("PhysgunDrop", "PoisonDartPhysgunDrop", function(ply, ent)
	if ent:GetClass() == "gmc_poisondart" then
		ent.HeldByPhysgun = false
	end
end)

hook.Add("GravGunOnPickedUp", "PoisonDartGravGunPickup", function(ply, ent)
	if ent:GetClass() == "gmc_poisondart" then
		ent.Owner = ply
		ent.HeldByPhysgun = true
		return true
	end
end)

hook.Add("GravGunOnDropped", "PoisonDartGravGunOnDropped", function(ply, ent)
	if ent:GetClass() == "gmc_poisondart" then
		ent.Owner = ply
		ent.HeldByPhysgun = false
	end
end)

function ENT:PhysicsCollide(data, phys)
	if self.Stuck then return end
	self.Stuck = true

	local hitEntity = data.HitEntity
	local hitPos = data.HitPos
	local hitNormal = data.HitNormal

	if IsValid(hitEntity) then
		self:EmitSound("NPC_Hunter.FlechetteHitBody")
		
		local PdmgInfo = DamageInfo()
		PdmgInfo:SetAttacker(self.Owner or self)
		PdmgInfo:SetInflictor(self)
		-- Set the damage to a percentage of the entities health, but doesn't let this damage go over 200. This prevents tanky NPCs from being nullified by the dart.
		PdmgInfo:SetDamage(0)
		PdmgInfo:SetDamageType(DMG_POISON)
		
		local HealthReduction = hitEntity:Health() - math.Clamp((hitEntity:GetMaxHealth() * self.Damage), 0, math.min((hitEntity:Health() - 1), 200))
		local HealAmount = HealthReduction * self.Healing
		local HealTime = self.HealTicks
		
		local function DoLogic()
			hitEntity:TakeDamageInfo(PdmgInfo)
			hitEntity:SetHealth(HealthReduction)
		
			for i = 1, HealTime do
				timer.Simple(i, function()
					if IsValid(hitEntity) and hitEntity:Health() > 0 then
						hitEntity:SetHealth(math.min(hitEntity:Health() + math.Round(HealAmount/HealTime), hitEntity:GetMaxHealth()))
					end
				end)
			end
		end
		
		if self.FriendlyFire then
			DoLogic()
		else
			local plyteam = self.Owner:Team()
			local hitteam = hitEntity.GMCTeam or hitEntity:Team()
			if plyteam == 5 and hitEntity.Owner != self.Owner and hitEntity != self.Owner then
				DoLogic()
			elseif plyteam == hitteam then
				DoLogic()
			end
		end
		self:Remove()
	else
		-- Stick to wall and remove after 5 seconds
		local trace = util.TraceLine({
			start = hitPos - hitNormal * 10,
			endpos = hitPos + hitNormal * 10,
			filter = {self},
			mask = MASK_SHOT
		})

		if trace.Hit then
			self:SetPos(trace.HitPos + trace.HitNormal * 3)
			phys:EnableMotion(false)
			
			self:EmitSound("NPC_Hunter.FlechetteHitWorld")
			timer.Simple(0.1, function()
				if IsValid(self) then
					self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				end
			end)
			
			timer.Simple(self.StickTime, function()
				if IsValid(self) then
					self:Remove()
				end
			end)
		end
	end
end

function ENT:Think()
	if not self.Stuck and not self.HeldByPhysgun and SERVER then
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