AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.Model = "models/items/medkit_large.mdl"
ENT.RespawnTime = 10

function ENT:Initialize()
    self:SetModel(self.Model)
	if gmod.GetGamemode().Name == "Sandbox" then
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
	else
		self:PhysicsInit(SOLID_NONE)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_NONE)
	end

    self:SetCooldown(false)
end

function ENT:SetCooldown(state)
    if state then
        self:SetNoDraw(true)
        self.Cooldown = true
    else
        self:SetNoDraw(false)
        self.Cooldown = false
    end
end

function ENT:Think()
    if self.Cooldown then return end

    local touchRadius = 20
    local startPos = self:GetPos()

    local entitiesInSphere = ents.FindInSphere(startPos, touchRadius)

    for _, entity in pairs(entitiesInSphere) do
        if IsValid(entity) and entity:IsPlayer() && entity:Alive() then
            local healthIncrease = entity:Health() + (entity:GetMaxHealth())

            if entity:Health() < entity:GetMaxHealth() then
                if healthIncrease <= entity:GetMaxHealth() then
                    entity:SetHealth(healthIncrease)
                else
                    entity:SetHealth(entity:GetMaxHealth())
                end
                entity:EmitSound("gmc/medkit.wav", 50, 100, 1, CHAN_AUTO)

                self:SetCooldown(true)

                timer.Simple(self.RespawnTime, function()
                    if IsValid(self) then
                        self:SetCooldown(false)
                    end
                end)
            end
        end
    end
end