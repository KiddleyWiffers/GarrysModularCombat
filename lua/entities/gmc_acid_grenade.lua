AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Acid Grenade"
ENT.Author = "Kiddley"
ENT.Information = "A custom acid grenade."
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Damage = 10
ENT.Owner = nil
ENT.Detonated = false
ENT.Radius = 150
ENT.Lifetime = 10

function ENT:Initialize()
    self:SetModel("models/spitball_large.mdl")
    self:SetAngles(Angle(math.Rand(-360, 360), math.Rand(-360, 360), math.Rand(-360, 360)))
    self:SetModelScale(2, 0.1)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(0)
    end

    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
end

function ENT:PhysicsCollide(data, phys)
    if not self.Detonated then
        self:Detonate()
    end
end

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
    if self.Detonated then return end
    self.Detonated = true
    self:SetNoDraw(true)
    self:EmitSound("NPC_Antlion.PoisonBurstExplode")
    
    -- Create the proxy entity to manage the acid pool
    local proxy = ents.Create("proxyent_acid_grenade")
    if IsValid(proxy) then
        proxy:SetPos(self:GetPos())
        proxy.Owner = self.Owner
        proxy.Damage = self.Damage
        proxy.Radius = self.Radius
        proxy.Lifetime = self.Lifetime
        proxy:Spawn()
        proxy:Activate()
    end

    -- Remove the grenade after detonation
    self:Remove()
end

hook.Add("GravGunOnPickedUp", "TrackGravGunPickup_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_acid_grenade" then
        ent.Owner = ply
        ent:SetNWEntity("Owner", ply)
    end
end)

hook.Add("GravGunOnDropped", "TrackGravGunDrop_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_acid_grenade" then
        ent.IsHeldByPlayer = false
    end
end)