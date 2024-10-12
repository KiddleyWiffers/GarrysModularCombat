AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Acid Pool Proxy"
ENT.Author = "Kiddley"
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = false
ENT.AdminOnly = false

if SERVER then
    util.AddNetworkString("AcidPoolParticles")

    function ENT:Initialize()
        self:SetModel("models/props_junk/PopCan01a.mdl")
        self:SetNoDraw(true)
        
        self:PhysicsInit(SOLID_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)

        self:StartAcidPool()
    end

    function ENT:StartAcidPool()
        timer.Simple(0.1, function()
			if IsValid(self) then
				-- Notify clients to create particles
				net.Start("AcidPoolParticles")
				net.WriteEntity(self)
				net.WriteInt(self.Radius, 10)
				net.WriteInt(self.Lifetime, 6)
				net.Broadcast()
			end
		end)

        local ticksPerSecond = 5
        local totalTicks = self.Lifetime * ticksPerSecond
        local tickDamage = math.Round(self.Damage / ticksPerSecond)

        -- Damage over time logic
        timer.Create("AcidPoolDamage_" .. self:EntIndex(), (1 / ticksPerSecond), totalTicks, function()
            if not IsValid(self) then
                timer.Remove("AcidPoolDamage_" .. self:EntIndex())
                return
            end
            self:DealAcidDamage(tickDamage)
        end)

        -- Remove the entity after the lifetime
        timer.Simple(self.Lifetime, function()
            if IsValid(self) then
                self:Remove()
            end
        end)
    end

    function ENT:DealAcidDamage(damagePerTick)
        local pos = self:GetPos()
        local entities = ents.FindInSphere(pos, self.Radius)

        for _, ent in pairs(entities) do
            if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
                if self:HasLineOfSight(ent) then
                    local dmgInfo = DamageInfo()
                    dmgInfo:SetAttacker(self.Owner or self)
                    dmgInfo:SetInflictor(self)
                    dmgInfo:SetDamage(damagePerTick)
                    dmgInfo:SetDamageType(DMG_ACID)
                    ent:TakeDamageInfo(dmgInfo)
                end
            end
        end
    end

    function ENT:HasLineOfSight(target)
        local trace = util.TraceLine({
            start = self:GetPos(),
            endpos = target:LocalToWorld(target:OBBCenter()),
            filter = {self, target}
        })

        return not trace.Hit
    end
end

if CLIENT then
	local radius = nil
	local life = nil

    net.Receive("AcidPoolParticles", function()
        local ent = net.ReadEntity()
		radius = net.ReadInt(10)
		life = net.ReadInt(6)
        if IsValid(ent) then
            ent:CreateAcidPoolParticles()  -- Call the particle creation function

            -- Automatically stop particles after the lifetime
            timer.Simple(life, function()
                if IsValid(ent) then
                    ent:StopParticles()
                end
            end)
        end
    end)

    -- Function to create acid pool particles
    function ENT:CreateAcidPoolParticles()
        local particleRadius = 8  -- Size of each particle effect
        local maxParticles = 50  -- Maximum number of particles to spawn
        local maxRadius = radius  -- Maximum radius to cover
        local offset = particleRadius * 2  -- Distance between particle centers
        local currentParticleCount = 0  -- Counter for the number of particles spawned

        -- Spawn the central particle
        self:PlaceParticle(Vector(0, 0, 0))

        -- Place particles in layers outwards in a circular pattern
        local currentRadius = offset
        while currentRadius <= maxRadius and currentParticleCount < maxParticles do
            currentParticleCount = currentParticleCount + self:PlaceParticleCircle(currentRadius, maxParticles - currentParticleCount)
            currentRadius = currentRadius + offset
        end
    end

    -- Function to place particles in a circular pattern at a given radius
    function ENT:PlaceParticleCircle(radius, maxParticles)
        local particleRadius = 40  -- Size of each particle effect
        local particleCount = math.min(maxParticles, math.floor((2 * math.pi * radius) / particleRadius))  -- Limit particles by remaining available particles
        local angleStep = 360 / particleCount  -- Calculate angle step to distribute particles evenly in the circle
        local placedParticles = 0

        -- Loop to create particles in a circular pattern around the entity
        for i = 0, particleCount - 1 do
            if placedParticles >= maxParticles then break end  -- Stop if we've hit the max number of particles
            local angle = math.rad(i * angleStep)
            local x = math.cos(angle) * radius
            local y = math.sin(angle) * radius

            local noiseX = math.Rand(-particleRadius * 0.2, particleRadius * 0.2)
            local noiseY = math.Rand(-particleRadius * 0.2, particleRadius * 0.2)
            local position = self:GetPos() + Vector(x + noiseX, y + noiseY, 0)

            -- Perform a line-of-sight check from the entity to the particle position
            if self:HasLineOfSightTo(position) then
                -- Check surface slope and line of sight at the position
                local trace = util.TraceLine({
                    start = position + Vector(0, 0, 50),  -- Start above ground
                    endpos = position - Vector(0, 0, 100),  -- Trace downward to find the ground
                    filter = self
                })

                if trace.Hit and trace.HitNormal:Dot(Vector(0, 0, 1)) > math.cos(math.rad(45)) then
                    -- Create the particle system using CreateParticleSystem
                    local acid = CreateParticleSystemNoEntity("acidpool", trace.HitPos)
					timer.Simple(life, function()
						acid:StopEmission(false, true, false)
					end)
                    placedParticles = placedParticles + 1
                end
            end
        end

        return placedParticles
    end

    -- Function to place a single particle at a relative position
    function ENT:PlaceParticle(relativePosition)
        local position = self:GetPos() + relativePosition

        -- Perform a line-of-sight check from the entity to the particle position
        if self:HasLineOfSightTo(position) then
            -- Check surface slope and line of sight
            local trace = util.TraceLine({
                start = position + Vector(0, 0, 50),  -- Start above ground
                endpos = position - Vector(0, 0, 100),  -- Trace downward to find the ground
                filter = self
            })

            if trace.Hit and trace.HitNormal:Dot(Vector(0, 0, 1)) > math.cos(math.rad(45)) then
                -- Create the particle system using CreateParticleSystem
                local acid = CreateParticleSystemNoEntity("acidpool", trace.HitPos)
				timer.Simple(life, function()
					acid:StopEmission(false, true, false)
				end)
            end
        end
    end

    -- Function to check line-of-sight from the entity to a target position
    function ENT:HasLineOfSightTo(position)
        local trace = util.TraceLine({
            start = self:GetPos(),  -- Start the trace from the center of the entity
            endpos = position,  -- End the trace at the target particle position
            filter = self  -- Ignore the entity itself in the trace
        })

        -- If the trace hits something before reaching the target position, return false
        return not trace.Hit
    end
end