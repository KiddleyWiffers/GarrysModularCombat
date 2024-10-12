AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Incendiary Grenade"
ENT.Author = "Kiddley"
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = true
ENT.AdminOnly = false

-- Define customizable values
ENT.BurnTime = 10
ENT.Damage = 4
ENT.IgniteRadius = 300

function ENT:Initialize()
    self:SetModel("models/weapons/w_models/w_flaregun_shell.mdl")
    
    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(0)
		phys:EnableDrag(true)
		phys:EnableGravity(true)
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
    if ent:GetClass() == "gmc_fire_grenade" then
        ent.Owner = ply
        ent:SetNWEntity("Owner", ply)
		ent.IsHeldByPlayer = true
    end
end)

hook.Add("GravGunOnDropped", "TrackGravGunDrop_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_fire_grenade" then
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

if SERVER then
    function ENT:Detonate()
        local proxy = ents.Create("proxyent_fire_grenade")
        if IsValid(proxy) then
            proxy:SetPos(self:GetPos())
            proxy.Owner = self.Owner
            proxy.BurnTime = self.BurnTime
            proxy.Damage = self.Damage
            proxy.IgniteRadius = self.IgniteRadius
            proxy:Spawn()
            proxy:Activate()
        end

        local explosiondata = EffectData()
        explosiondata:SetOrigin(self:GetPos())
        util.Effect("Explosion", explosiondata)

        self:Remove()
    end
end

function ENT:PhysicsCollide(data, phys)
    if not self.Detonated then
        self.Detonated = true
        self:Detonate()
    end
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

    -- Call Think every frame
    self:NextThink(CurTime())
    return true
end