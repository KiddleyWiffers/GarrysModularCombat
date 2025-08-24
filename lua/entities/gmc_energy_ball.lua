AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")  -- Define a base class for the entity

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Energy Ball"
ENT.Author = "Kiddley"
ENT.Information = "A custom combine ball."
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = true
ENT.AdminOnly = false

-- Define customizable values
ENT.Damage = 100 -- Default damage
ENT.HP = 100 -- Total health to represent its lifespan, can be modified
ENT.Hit = 5 -- Damage taken on colliding with something.
ENT.Speed = 1000 -- Speed in hammer units per second
ENT.LastWhizTime = 0 -- To store the last time the whiz sound was played
ENT.IsHeldByPlayer = false -- Track if entity is being held
ENT.Owner = nil -- The Entities owner
ENT.BeingPunted = false -- If the entity is being punted with the gravity gun or not
ENT.HoldSound = nil -- The ID of the holdsound
ENT.Unbreakable = false
ENT.Level = nil
ENT.FriendlyFire = true

function ENT:Initialize()
	self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
	self:DrawShadow( false )
	self:SetMaterial("Models/effects/comball_sphere")
	
	if engine.ActiveGamemode() == "gmc" and self.Level then
		self.Damage = 50 + (10 * self.Level)
		self.HP = 100 + (10 * self.Level)
		self.FriendlyFire = false
	end
	
	self:PhysicsInitSphere(20, SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if ( !IsValid( phys ) ) then return end
	
	self:SetHealth(self.HP)
	
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	phys:EnableGravity(false)
	phys:EnableDrag(false)
end

function ENT:SpawnFunction(ply, tr, class)
	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( class )
	ent:SetPos( SpawnPos )
	ent.Owner = ply
	ent:Spawn()
	ent:Activate()

	return ent
end

hook.Add("PhysgunPickup", "TrackPhysgunPickup_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_energy_ball" then
        ent.IsHeldByPlayer = true
    end
end)

hook.Add("PhysgunDrop", "TrackPhysgunDrop_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_energy_ball" then
        ent.IsHeldByPlayer = false
    end
end)

function ENT:GravGunPunt(ply)
	if self.IsHeldByPlayer then
		self.BeingPunted = true
		return true
	end
end

hook.Add("GravGunOnPickedUp", "TrackGravGunPickup_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_energy_ball" then
        ent.IsHeldByPlayer = true
		ent.Owner = ply
		ent:SetNWBool("IsHeldByPlayer", true)
		ent:SetNWEntity("Owner", ply)
    end
end)

hook.Add("GravGunOnDropped", "TrackGravGunDrop_" .. ENT.PrintName, function(ply, ent)
    if ent:GetClass() == "gmc_energy_ball" then
        ent.IsHeldByPlayer = false
		ent:SetNWBool("IsHeldByPlayer", false)
		
		if !ent.BeingPunted then
			local phys = ent:GetPhysicsObject()

			if IsValid(phys) then
                -- Get the player's forward direction
                local playerForward = ply:GetForward()

                -- Generate a random angle between -90 and 90 degrees (for a 180-degree cone)
                local randomAngle = math.Rand(-90, 90)

                -- Rotate the player's forward vector by the random angle
                local launchDirection = playerForward:Angle()
                launchDirection:RotateAroundAxis(ply:GetUp(), randomAngle) -- Randomly adjust left/right
                
                -- Convert the launch angle back to a direction vector
                local randomDirection = launchDirection:Forward()

                -- Apply the velocity in the chosen direction with the desired speed
                local launchVelocity = randomDirection * ent.Speed
                phys:SetVelocity(launchVelocity)
            end
		else
			ent.BeingPunted = false
		end
    end
end)

function ENT:Think()
    local curTime = CurTime()
    local phys = self:GetPhysicsObject()
	
	if self.IsHeldByPlayer && self.HoldSound == nil then
		self.HoldSound = self:StartLoopingSound("NPC_CombineBall.HoldingInPhysCannon")
	elseif !self.IsHeldByPlayer && self.HoldSound != nil then
		self:StopLoopingSound(self.HoldSound)
		self.HoldSound = nil
	end

    -- Check if the entity is moving at full speed
    if IsValid(phys) and phys:GetVelocity():Length() >= self.Speed then
        local entitiesNearby = ents.FindInSphere(self:GetPos(), 300)

        -- Iterate through nearby entities and check if any are players
        for _, ent in ipairs(entitiesNearby) do
            if ent:IsPlayer() && !self.IsHeldByPlayer then
                if curTime - self.LastWhizTime >= 1 then
                    self:EmitSound("NPC_CombineBall.WhizFlyby", 10, 100, 0.1)
                    self.LastWhizTime = curTime
                end
                break
            end
        end
    end
	
	if SERVER then
		if !timer.Exists("EnergyBallLifetime" .. self:EntIndex()) and !self:GetPhysicsObject():IsAsleep() && !self.Unbreakable then
			self:StartLifetimeDecay()
		end
		
		if self:Health() <= 0 then
			local effectData = EffectData()
			effectData:SetOrigin(self:GetPos())
			util.Effect("AR2Explosion", effectData)
			
			self:EmitSound("NPC_CombineBall.Explosion")
			util.ScreenShake(self:GetPos(), 20, 150, 1, 1250)
					
			effects.BeamRingPoint(self:GetPos(), 0.2, 12, 1024, 64, 0, Color(255,255,225,32),{
				speed=0,
				spread=0,
				delay=0,
				framerate=2,
				material="sprites/lgtning.vmt"
			})
			
			self.IsHeldByPlayer = false
			if self.HoldSound != nil then 
				self:StopLoopingSound(self.HoldSound) 
			end
			self:Remove()
		end
	end

    self:NextThink(CurTime())
    return true
end

if SERVER then
	function ENT:StartLifetimeDecay()
		-- Create a timer that ticks every 0.1 seconds
		timer.Create("EnergyBallLifetime" .. self:EntIndex(), 0.1, self.HP, function()
			if not IsValid(self) then return end
			
			-- Reduce health (lifetime)
			self:SetHealth(self:Health() - 1)
		end)
	end
end

function ENT:OnRemove()
    timer.Remove("EnergyBallLifetime" .. self:EntIndex())
end

function ENT:PhysicsCollide(data, phys)
    local hitEntity = data.HitEntity

    if IsValid(hitEntity) && !self.IsHeldByPlayer then
        -- Inflict damage to the entity
        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage(self.Damage)
		if IsValid(self.Owner) then
			dmgInfo:SetAttacker(self.Owner)
		else
			dmgInfo:SetAttacker(self)
		end
        dmgInfo:SetInflictor(self)
        dmgInfo:SetDamageType(DMG_DISSOLVE)

		if self.FriendlyFire then
			hitEntity:TakeDamageInfo(dmgInfo)
		else
			local plyteam = self.Owner:Team()
			local hitteam = hitEntity.GMCTeam
			if hitteam == nil and hitEntity:IsPlayer() then
				hitteam = hitEntity:Team()
			end
			if plyteam == 5 and hitEntity.Owner != self.Owner and hitEntity != self.Owner then
				hitEntity:TakeDamageInfo(dmgInfo)
			elseif plyteam == hitteam or plyteam then
				hitEntity:TakeDamageInfo(dmgInfo)
			end
		end
		
		if dmgInfo:GetDamage() >= hitEntity:Health() && hitEntity:GetMaxHealth() > 1 then
			EmitSound( "NPC_CombineBall.KillImpact", self:GetPos(), 0, CHAN_AUTO, 1, 75 )
			self:SetConstantSpeed(data, phys)
		else
			self:Bounce(data, phys)
		end
    else
		local effectData = EffectData()
        effectData:SetOrigin(data.HitPos)
        effectData:SetNormal(data.HitNormal)
		effectData:SetRadius(15)
		effectData:SetScale(1)
		util.Effect("cball_bounce", effectData)
		
        self:Bounce(data, phys)
    end
end

-- Function to handle bouncing with constant speed
function ENT:Bounce(data, phys)
	local velocity = phys:GetVelocity()
	local hitdamage = self.Hit
    
    phys:SetVelocity(velocity:GetNormalized() * self.Speed)
	self:SetHealth(self:Health() - hitdamage)
	EmitSound("NPC_CombineBall.Impact", self:GetPos(), 0, CHAN_AUTO, 1, SNDLVL_70dB)
end

-- Function to ensure ball always moves at the constant speed
function ENT:SetConstantSpeed(data, phys)
    local oldVelocity = data.OurOldVelocity

    local direction = oldVelocity:GetNormalized()

    phys:SetVelocity(direction * self.Speed)
end

if CLIENT then
	function ENT:Draw()
		if self:GetNWEntity("Owner") == LocalPlayer() && self:GetNWBool("IsHeldByPlayer", false) then
            local pos = self:GetPos()
            local ang = (LocalPlayer():EyePos() - pos):Angle()

            render.Model({
                model = "models/effects/combineball.mdl",
                pos = pos,
                angle = ang
            })
		else
			render.SetMaterial(Material("effects/ar2_altfire1"))
			render.DrawSprite( self:GetPos(), 20, 20, Color(255, 255, 255) )
		end
		local dlight = DynamicLight(self:EntIndex())
		if (dlight) then
			dlight.pos = self:GetPos()
			dlight.r = 200
			dlight.g = 150 
			dlight.b = 130
			dlight.brightness = 2
			dlight.Decay = 50
			dlight.Size = 100
			dlight.DieTime = CurTime() + 0.1
		end
	end
end