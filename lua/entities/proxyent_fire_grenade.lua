AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Fire Grenade Proxy"
ENT.Author = "Kiddley"
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetNoDraw(true)

    self:PhysicsInit(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)

    if SERVER then
        self:StartBurning()
    end
end

if SERVER then
	util.AddNetworkString("FireBombParticles")
    function ENT:StartBurning()
        local entities = ents.FindInSphere(self:GetPos(), self.IgniteRadius)
        for _, ent in ipairs(entities) do
            if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                self:StartBurnDamage(ent, self.Owner)

                net.Start("FireBombParticles")
                net.WriteEntity(ent)
				net.WriteInt(self.BurnTime, 8)
                net.Broadcast()
            end
        end

        timer.Simple(self.BurnTime, function()
            if IsValid(self) then
                self:Remove()
            end
        end)
    end

    function ENT:StartBurnDamage(ent, attacker)
        local burnDuration = self.BurnTime
        local burnDamage = self.Damage

        timer.Create("BurnDamage_" .. ent:EntIndex(), 0.5, burnDuration * 2, function()
            if IsValid(ent) and ent:WaterLevel() < 2 and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
                local dmgInfo = DamageInfo()
                dmgInfo:SetDamage(burnDamage)
                dmgInfo:SetAttacker(attacker or self)
                dmgInfo:SetInflictor(self)
                dmgInfo:SetDamageType(DMG_SLOWBURN)
                ent:TakeDamageInfo(dmgInfo)
            else
                timer.Remove("BurnDamage_" .. ent:EntIndex())
            end
        end)

        hook.Add("OnEntityKilled", "StopBurnEffect_" .. ent:EntIndex(), function(victim)
            if victim == ent then
                timer.Remove("BurnDamage_" .. ent:EntIndex())
                hook.Remove("OnEntityKilled", "StopBurnEffect_" .. ent:EntIndex())
            end
        end)
    end
end

if CLIENT then
	net.Receive("FireBombParticles", function()
        local ent = net.ReadEntity()
		local burnTime = net.ReadInt(8)
		
        if IsValid(ent) then
            local flame = CreateParticleSystem(ent, "onfire", PATTACH_ABSORIGIN_FOLLOW)
			local viewflame = nil
            local timerName = "FireBombEffect_" .. ent:EntIndex()

            timer.Create(timerName, 0.1, burnTime * 10, function()
                if IsValid(ent) and IsValid(flame) then
					if ent:IsPlayer() and IsValid(ent:GetViewModel()) and !IsValid(viewflame) then
						viewflame = CreateParticleSystem(ent:GetViewModel(), "onfire", PATTACH_ABSORIGIN_FOLLOW)
					end
				
                    if ent:WaterLevel() > 1 then
                        flame:StopEmission(false, true, false)
                        timer.Remove(timerName)
                    end
                else
                    timer.Remove(timerName)
                end
            end)

            timer.Simple(burnTime, function()
                if IsValid(flame) then
                    flame:StopEmission(false, false, false)
                end
				if IsValid(viewflame) then
					viewflame:StopEmission(false, false, false)
				end
            end)
        end
    end)
end

gameevent.Listen( "entity_killed" )
hook.Add( "entity_killed", "StopFlameTimers", function( data ) 
	local inflictor_index = data.entindex_inflictor
	local attacker_index = data.entindex_attacker
	local damagebits = data.damagebits
	local victim_index = data.entindex_killed
	
	local ent = Entity(victim_index)
	
	if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
        local particletimerName = "FireBombEffect_" .. ent:EntIndex()
		local damagetimerName = "BurnDamage_" .. ent:EntIndex()
        if timer.Exists(particletimerName) then
            timer.Remove(particletimerName)
        end
		if timer.Exists(damagetimerName) then
            timer.Remove(damagetimerName)
        end

        if CLIENT then
            if IsValid(ent) then
                ent:StopParticlesNamed( "onfire" )
            end
        end
    end
end )