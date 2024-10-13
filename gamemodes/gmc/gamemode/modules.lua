AddCSLuaFile()
include("commands.lua")
include("particles.lua")

local baseMaxHealth = 100
local baseMaxArmor = 100
local baseWalkSpeed = 220
local baseRunSpeed = 280
local baseAUX = 100

MOD_VIT = GetConVar( "gmc_mod_vitality_increase" ):GetInt()
MOD_VIT_DESC = ("The Cellular Fortification Nanites Module deploys microscopic machines that reinforce the structural integrity of the user's cells granting " .. MOD_VIT .. " additional health.")

MOD_ARM = GetConVar( "gmc_mod_shield_increase" ):GetInt()
MOD_ARM_DESC = ("The Reinforced Shield Generator Module incorporates more robust energy generation components into the shield's design. This results in a shield that can create and maintain a stronger protective field, granting an additional " .. MOD_ARM .. " points of shield capacity")

MOD_AUX = GetConVar( "gmc_mod_battery_increase" ):GetInt()
MOD_AUX_DESC = ("The Energy Cell Efficiency Module represents a series of subtle but effective optimizations to the suit's energy cell granting the user " .. MOD_AUX .. " more AUX power.")

MOD_ARMR = GetConVar( "gmc_mod_shieldrecharge_increase" ):GetInt()
MOD_ARMR_DELAY = GetConVar( "gmc_mod_shieldrecharge_delay" ):GetInt()
MOD_ARMR_DRAIN = GetConVar( "gmc_mod_shieldrecharge_drain" ):GetInt()
MOD_ARMR_MINAUX = GetConVar( "gmc_mod_shieldrecharge_minaux" ):GetInt()
MOD_ARMR_DESC = ("The Shield Resurgance module recharges shield at a rate of " .. MOD_ARMR .. " per " .. MOD_ARMR_DELAY .. " seconds. This drains " .. MOD_ARMR_DRAIN .. " per armor restored, but won't drain less than " .. MOD_ARMR_MINAUX .. "% max AUX power.")

MOD_AUXR = math.Round(GetConVar( "gmc_mod_batteryrecharge_increase" ):GetFloat(), 2)
MOD_AUXR_DESC = ("The Subspace Energy Amplifier Module enhances the suit's SEC by fine-tuning its connection to the alternate dimension. This augmentation accelerates the rate at AUX recharges by " .. MOD_AUXR .. " per tick.")

MOD_DMG = 0.05
MOD_DMG_DESC = ("The Magnetic Flux Catalyst Module enhances weapon performance by utilizing advanced magnetic field manipulation to increase projectile speed and energy, resulting in a " .. MOD_DMG * 100 .. "% higher damage output.")

MOD_BLUNT = 0.1
MOD_BLUNT_BUFF = 0.05
MOD_BLUNT_TIME = 15
MOD_BLUNT_DESC = ("The Psi-Blade Augmentation Suite enhances the user's melee weapon with advanced energy manipulation, giving a ".. (MOD_BLUNT * 100) .. "% increase to melee damage. After a melee kill, the suite harnesses residual energy to empower all equipped weapons, granting a " .. (MOD_BLUNT_BUFF * 100) .. "% damage increase for " .. (MOD_BLUNT_TIME) .. " seconds.")

MOD_AMMORES = 0.2
MOD_AMMORES_DESC = ("The Smart Ammo Rack System employs intelligent sorting and storage algorithms to maximize the number of rounds that can be carried by ".. (MOD_AMMORES * 100) .. "% without any increase in the suit's bulk.")

MOD_SPD = 0.03
MOD_SPD_DESC = ("The Hyper-Dynamic Locomotion Module employs advanced micro-thrusters and AI-assisted motion prediction to optimize the wearer's stride and balance. This results in the user moving " .. (MOD_SPD * 100) .. "% faster.")

MOD_HEAL = 10
MOD_HEAL_TIME = 5
MOD_HEAL_DESC = ("The Trauma Response Nanite Swarm can be released to provide " .. MOD_HEAL .. " health per level over " .. MOD_HEAL_TIME .. " seconds.")
MOD_HEAL_COST = MOD_HEAL/2

MOD_JETPACK = 10
MOD_JETPACK_DESC = ("The jetpack allows you to fly by holding your jump button, this expends AUX over time. Press your jump button while in the air to active it.")

MOD_SHAMP = 1
MOD_SHAMP_COST = 20
MOD_SHAMP_COOLDOWN = 15
MOD_SHAMP_DESC = ("The Shield Overcharge module will increase a targets shield to 200 for a few seconds. This overloads the shield, causing it to completely drain after the effect ends. The module will have to recharge and cool down, so it cannot be used on the same target for " .. MOD_SHAMP_COOLDOWN .. " seconds after the effect ends.")

MOD_CONFUSE = 5
MOD_CONFUSE_PLAYERS = 2
MOD_CONFUSE_DESC = ("The Neuro-Havoc Module scrambles the brain of a monster, compelling them to target any entity within their vicinity. For creatures with higher intelligence, it induces only slight motor dysfunction, inverting their controls for a limited time.")
MOD_CONFUSE_COST = 10

MOD_CRIT = 0.5
MOD_CRIT_COST = 15
MOD_CRIT_SLOWDOWN = 0.2
MOD_CRIT_UPGRADE = 0.02
MOD_CRIT_DESC = ("The Power Strike Module channels an immense amount of energy into the user's weapon systems, increasing damage by ".. (MOD_CRIT * 100) .. "%. However, this uses " .. MOD_CRIT_COST .. " AUX power per second and redirects power from the suits motors, causing movement speed to be reduced to " .. (MOD_CRIT_SLOWDOWN * 100) .. "%. Each level decreases the movement speed debuff by " .. (MOD_CRIT_UPGRADE * 100) .. "%.")

MOD_ENERGYBALL_DAMAGE = 50
MOD_ENERGYBALL_DAMAGEUP = 10
MOD_ENERGYBALL_LIFE = 100
MOD_ENERGYBALL_LIFEUP = 10
MOD_ENERGYBALL_COST = 15
MOD_ENERGYBALL_COOLDOWN = 10
MOD_ENERGYBALL_DESC = ("A powerful ball of energy dealing ")

modules = {
	--Passive Modules================================================================================================================================================================================================================================================
    -- Increases max health
	{
        id = "vitality",
        PrintName = "Max Health",
        Description = MOD_VIT_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/vitality",
        MAXLEVEL = 10,
		BASE = 100,
        STAT = {
			{MOD_VIT, "Health"}
		}
    },
    -- Increase max shield
    {
        id = "shieldamount",
        PrintName = "Shield Integrity",
        Description = MOD_ARM_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/armoramount",
        MAXLEVEL = 10,
		BASE = 100,
        STAT = {
			{MOD_ARM, "Shield"}
		}
    },
    -- Regenerates Shield
    {
        id = "shieldregen",
        PrintName = "Shield Recharge",
        Description = MOD_ARMR_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/armorregen.vtf",
        MAXLEVEL = 10,
		BASE = 0,
        STAT = {
            {MOD_ARMR, "Regen"},
            {MOD_ARMR_DRAIN, "Drain"}
        }
    },
    -- Increases max AUX
    {
        id = "auxamount",
        PrintName = "AUX Batteries",
        Description = MOD_AUX_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/auxamount",
        MAXLEVEL = 10,
		BASE = GetConVar( "gmc_aux_base" ):GetInt(),
        STAT = {
            {MOD_AUX, "AUX"}
        }
    },
    -- Regenerates additional AUX
    {
        id = "auxregen",
        PrintName = "AUX Recharge",
        Description = MOD_AUXR_DESC,
        Category = "Passive",
        MAXLEVEL = 10,
		BASE = 0.1,
        Icon = "vgui/gui/gmc/modules/auxregen",
        STAT = {
            {MOD_AUXR, "Regen"}
        }
    },
	-- Increases movement speed
	{
        id = "movespeed",
        PrintName = "Base Speed",
        Description = MOD_SPD_DESC,
        Category = "Passive",
        MAXLEVEL = 10,
		BASE = 0,
        Icon = "vgui/gui/gmc/modules/movespeed",
        STAT = {
            {math.Round(baseWalkSpeed * MOD_SPD), "Walk"},
			{math.Round(baseRunSpeed * MOD_SPD), "Run"}
        }
    },
	-- Weapon Modules=====================================================================================================================
    -- Increases weapon damage
    {
        id = "weapondmg",
        PrintName = "Damage",
        Description = MOD_DMG_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/weapondmg",
        MAXLEVEL = 10,
		BASE = 0,
        STAT = {
            {MOD_DMG * 100, "Damage"}
        }
    },
	{
        id = "meleedamage",
        PrintName = "Melee Damage",
        Description = MOD_BLUNT_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/bluntforce",
        MAXLEVEL = 10,
		BASE = 0,
        STAT = {
            {MOD_BLUNT * 100, "Damage"},
			{MOD_BLUNT_BUFF * 100, "Buff"}
        }
    },
	{
        id = "ammoreserve",
        PrintName = "Ammo Reserve",
        Description = MOD_AMMORES_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/ammoreserve",
        MAXLEVEL = 10,
		BASE = 1,
        STAT = {
            {MOD_AMMORES, "Multiplier"}
        }
    },
	-- Crits
	{
        id = "crits",
        PrintName = "Crits",
        Description = MOD_CRIT_DESC,
        Category = "Weapons",
		Active = true,
        MAXLEVEL = 10,
		BASE = MOD_CRIT_SLOWDOWN,
        Icon = "vgui/gui/gmc/modules/crits",
        STAT = {
            {MOD_CRIT_UPGRADE, "Speed"}
        }
    },
	-- Target Modules=====================================================================================================================
	{
		id = "restorehp",
		PrintName = "Heal",
		Description = MOD_HEAL_DESC,
		Category = "Target",
		Icon = "vgui/gui/gmc/modules/heal",
		Active = true,
		MAXLEVEL = 10,
		BASE = 0,
		STAT = {
			{MOD_HEAL, "Heal"},
			{MOD_HEAL/2, "Cost"}
		}
	},
	{
		id = "shieldamp",
		PrintName = "Shield Overload",
		Description = MOD_SHAMP_DESC,
		Category = "Target",
		Icon = "vgui/gui/gmc/modules/shieldamp",
		Active = true,
		MAXLEVEL = 10,
		BASE = 0,
		STAT = {
			{MOD_SHAMP, "Time"},
		}
	},
	-- Movement Modules==================================================================================================================
	{
		id = "jetpack",
		PrintName = "Jetpack",
		Description = MOD_JETPACK_DESC,
		Category = "Movement",
		Icon = "vgui/gui/gmc/modules/jetpack",
		Active = false,
		MAXLEVEL = 5,
		BASE = 10,
		INVERTED = true,
		STAT = {
			{1, "Cost"},
		}
	}
}
--Module logic starts here.

-- Passive modules
timer.Create("Armor Regen", 1, 0, function()
	for k,ply in pairs(player.GetAll()) do
		local armreg = ply:GetNWInt("shieldregen")
		local plyAUX = ply:GetAUX()
		local plyMaxAUX = ply:GetMaxAUX()
		if SERVER && (armreg > 0 && !(ply:Armor() >= ply:GetMaxArmor())) then
			local armorincrease = ply:Armor() + (MOD_ARMR*armreg)
			if plyAUX > (plyMaxAUX * (MOD_ARMR_MINAUX/100)) then
				if armorincrease < ply:GetMaxArmor() then
					ply:SetArmor(armorincrease)
					ply:SetAUX(plyAUX - (MOD_ARMR * armreg))
				else
					ply:SetArmor(ply:GetMaxArmor())
					ply:SetAUX(plyAUX - (armorincrease - ply:GetMaxArmor()))
				end
			end
		end
	end
end)
	
-- Modules to apply on spawn (Speed, Health, Armor, ect.)
hook.Add( "PlayerSpawn", "SetStats", function(ply)
	ply:SetMaxHealth(ply:GetMaxHealth() + (ply:GetNWInt("vitality") * MOD_VIT))
	ply:SetHealth(ply:Health() + (ply:GetNWInt("vitality") * MOD_VIT))
	ply:SetMaxArmor(ply:GetMaxArmor() + (ply:GetNWInt("shieldamount") * MOD_ARM))
	ply:SetWalkSpeed(baseWalkSpeed + (math.Round(baseWalkSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD)))))
	ply:SetRunSpeed(baseRunSpeed + (math.Round(baseRunSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD)))))
end)
	
statuses = {
	"Bluntforce",
	"Shield Amp",
	"SA Cooldown",
}
if SERVER then
	util.AddNetworkString("HealParticles")
	util.AddNetworkString("GMCast")
	
	net.Receive("GMCast", function(len, ply)
        local modid = net.ReadString()

		ReceiveSecurity(ply, 10)
        GMCCast(ply, modid)
    end)
	
	-- Quick timer to simulate a think function but not as resource heavy.
	timer.Create("SERVERModuleThink", 0.1, 0, function()
		for k,ply in pairs(player.GetAll()) do
			local weapon = ply:GetActiveWeapon()
			effectcolor = ply:GetNWVector("EffectColor", Vector(1,1,1)):ToColor()
			
			local plyAUX = ply:GetAUX()
			
			if ply:GetNWBool("Crits Active") && plyAUX >= 0 && weapon:IsValid() then
				ply:SetAUX(plyAUX - (MOD_CRIT_COST/10))
				weapon:SetMaterial("models/alyx/emptool_glow")
				weapon:SetColor(effectcolor)
			elseif ply:GetNWBool("Crits Active") && plyAUX <= 0 then
				ply:SetNWBool("Crits Active", false)
				ply:SetWalkSpeed(baseWalkSpeed + (math.Round(baseWalkSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD)))))
				ply:SetRunSpeed(baseRunSpeed + (math.Round(baseRunSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD)))))
				RemoveTF2CritGlow(ply)
				RemoveTF2CritGlow(weapon)
			end
			
			if !ply:GetNWBool("Crits Active") && weapon:IsValid() then
				weapon:SetMaterial("")
				weapon:SetColor(Color(255, 255, 255, 255))
			end
		end
	end)
end

if CLIENT then
	-- Quick timer to simulate a think function but not as resource heavy.
	timer.Create("CLIENTModuleThink", 0.1, 0, function()
		for k,ply in pairs(player.GetAll()) do
			local viewmodel = ply:GetViewModel( 0 )
			effectcolor = ply:GetNWVector("EffectColor", Vector(1,1,1)):ToColor()
			
			local plyAUX = ply:GetAUX()
			for k,status in pairs(statuses) do
				-- So for some reason doing an else statement to set the timer makes the screen flash rapidly. So we just gotta do that in the modules.
				if timer.Exists(status .. "_" .. ply:EntIndex()) then
					ply:SetNWInt(status .. "Timer", timer.TimeLeft(status .. "_" .. ply:EntIndex()))
				end
			end
			
			if ply:GetNWBool("Crits Active") && plyAUX > 0 && viewmodel:IsValid() then
				viewmodel:SetMaterial("models/alyx/emptool_glow")
				viewmodel:SetColor(effectcolor)
			end
			if !ply:GetNWBool("Crits Active") && viewmodel:IsValid() then
				viewmodel:SetMaterial("")
				viewmodel:SetColor(Color(255, 255, 255, 255))
			end
		end
	end)
	
	-- Particle Recieves
	net.Receive("HealParticles", function()
		local ent = net.ReadEntity()
		
		if IsValid(ent) then
			local healparticle = CreateParticleSystem(ent, "healing_effect", PATTACH_ABSORIGIN_FOLLOW, 0, ent:OBBCenter())
			
			healparticle:SetControlPointEntity(1, ent)
			timer.Simple(MOD_HEAL_TIME, function()
				healparticle:StopEmission(false, false, false)
			end)
		end
	end)
end

-- Damage modifier implmentation
hook.Add( "EntityTakeDamage", "DamageModules", function(target, dmg)
	if IsValid(target) and IsValid(dmg:GetAttacker()) and dmg:GetAttacker():IsPlayer() then
		local player = dmg:GetAttacker()
		local enemy = target
		local damage = dmg:GetDamage()
		
		if(player:GetNWInt("weapondmg") > 0) then
			dmg:SetDamage(math.Round(damage + (damage * (MOD_DMG * player:GetNWInt("weapondmg")))))
			damage = dmg:GetDamage()
		end
		
		-- List of extra weapons that aren't registered by the find function.
		-- We can also use false on this list to set non-melee weapons that are being registered as melee.
		local meleeweaponlist = {
			weapon_crowbar = true,
		}
		
		-- Apply meleedamage damage
		if(player:GetNWInt("meleedamage") > 0) then
			if meleeweaponlist[player:GetActiveWeapon():GetClass()] then
				dmg:SetDamage(math.Round(damage + (damage * (MOD_BLUNT * player:GetNWInt("meleedamage")))))
				damage = dmg:GetDamage()
				player:SetNWBool("LastAttackWasMelee", true)
			elseif !(dmg:IsBulletDamage() && dmg:IsExplosionDamage()) && (dmg:GetInflictor() == player:GetActiveWeapon()) && (player:GetPos():Distance(target:GetPos()) < 100) && (meleeweaponlist[player:GetActiveWeapon():GetClass()] != false) then
				dmg:SetDamage(math.Round(damage + (damage * (MOD_BLUNT * player:GetNWInt("meleedamage")))))
				damage = dmg:GetDamage()
				player:SetNWBool("LastAttackWasMelee", true)
			else
				player:SetNWBool("LastAttackWasMelee", false)
			end
		end
		
		-- Apply Bluntforce damage
		if(player:GetNWInt("Bluntforce") > 0) then
			dmg:SetDamage(damage + math.Round((damage * (MOD_BLUNT_BUFF * player:GetNWInt("Bluntforce")))))
			damage = dmg:GetDamage()
		end
		
		-- Apply Crit damage
		if player:GetNWBool("Crits Active") then
			dmg:SetDamage(damage + math.Round(damage * MOD_CRIT))
			damage = dmg:GetDamage()
		end
	end
end)
	
-- On Kill effects
hook.Add( "OnNPCKilled", "NPCKillEffect", function(victim, attacker, inflictor)
	if IsValid(attacker) and IsValid(victim) then
		if attacker:GetNWInt("meleedamage") > 0 && attacker:GetNWBool("LastAttackWasMelee") == true then
			if timer.Exists("Bluntforce_" .. attacker:EntIndex()) then
				timer.Start("Bluntforce_" .. attacker:EntIndex())
			else
				timer.Create("Bluntforce_" .. attacker:EntIndex(), MOD_BLUNT_TIME, 1, function()
					attacker:SetNWInt("Bluntforce", 0)
					attacker:SetNWInt("BluntforceTimer", 0)
				end)
			end
			if attacker:GetNWInt("Bluntforce") < attacker:GetNWInt("meleedamage") then
				attacker:SetNWInt("Bluntforce", attacker:GetNWInt("Bluntforce") + 1)
			end
		end
	end
end)
	
hook.Add( "PlayerDeath", "PlayerKillEffect", function(victim, attacker, inflictor)
	victim:SetNWBool("Crits Active", false)
	if IsValid(attacker) and IsValid(victim) then
		if attacker:GetNWInt("meleedamage") > 0 && attacker:GetNWBool("LastAttackWasMelee") == true then
			if timer.Exists("Bluntforce_" .. attacker:EntIndex()) then
				timer.Start("Bluntforce_" .. attacker:EntIndex())
			else
				timer.Create("Bluntforce_" .. attacker:EntIndex(), MOD_BLUNT_TIME, 1, function()
					attacker:SetNWInt("Bluntforce", 0)
					attacker:SetNWInt("BluntforceTimer", 0)
				end)
			end
			if attacker:GetNWInt("Bluntforce") < attacker:GetNWInt("meleedamage") then
				attacker:SetNWInt("Bluntforce", attacker:GetNWInt("Bluntforce") + 1)
			end
		end
	end
end)

--Active Modules casting
-- General module code

function CheckModuleRange(ply, range)
    local tr = ply:GetEyeTraceNoCursor()
    local hitDistance = (ply:EyePos() - tr.HitPos):Length()
    local ent = tr.Entity

    if hitDistance <= range and IsValid(ent) then
        return true, ent
    else
        return false, nil
    end
end

function SameTeam(ent1, ent2)
    if (ent1:IsPlayer() and ent2:IsPlayer()) then
		return ent1:Team() == ent2:Team()
	elseif (ent1:IsPlayer() and (ent2:IsNPC() or ent2:IsNextBot())) then
		return ent1:Team() == ent2.Team
	end
end

local function ReduceAuxPower(ply, amount)
	local plyAUX = ply:GetAUX()
	if plyAUX >= amount then
		ply:SetAUX(plyAUX - amount)
		return true
	else
		return false
	end
end

function FireProjectile(ply, projectileType, speed, delay, sound)
    if not IsValid(ply) then return end

    delay = delay or 0
    sound = sound or nil

    local function DoFire()
        local startPos = ply:GetShootPos()
        local aimDir = ply:GetAimVector()

        local projectile = ents.Create(projectileType)
        if not IsValid(projectile) then return end

        projectile:SetPos(startPos)
        projectile.Owner(ply)
        projectile:Spawn()

        local velocity = aimDir * speed
        local phys = projectile:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetVelocity(velocity)
        end

        if sound then
            ply:EmitSound(sound)
        end
    end

    if delay > 0 then
        timer.Simple(delay, DoFire)
    else
        DoFire()
    end
end

-- Specific Module code
local function StartHealTimer(healer, healing, plyAUX)
	timer.Create("Heal_" .. healing:EntIndex(), 1, MOD_HEAL_TIME, function()
		if plyAUX > (MOD_HEAL/2) then
			ReduceAuxPower(healer, MOD_HEAL/2)
			
			if (healing:Health() + MOD_HEAL) < healing:GetMaxHealth() then
				healing:SetHealth(healing:Health() + math.Round((MOD_HEAL/MOD_HEAL_TIME) * healer:GetNWInt("restorehp")))
			else
				healing:SetHealth(healing:GetMaxHealth())
				timer.Remove("Heal_" .. healing:EntIndex())
			end
		else
			timer.Remove("Heal_" .. healing:EntIndex())
			return
		end
	end)
	
	net.Start("HealParticles")
        net.WriteEntity(healing)
    net.Broadcast()
end

local function StartShieldTimer(ply, ent, plyAUX)
	if plyAUX > (MOD_SHAMP_COST) && ent:GetNWInt("SA CooldownTimer") < 1  then
		ent:SetAUX(plyAUX - (MOD_SHAMP_COST))
		ent:EmitSound( "npc/scanner/scanner_electric2.wav", 75, 100, 1, CHAN_AUTO)
		timer.Create("Shamp_" .. ent:EntIndex(), 0.2, ply:GetNWInt("shieldamp") * 5, function()
			ent:SetNWInt("Shield AmpTimer", timer.RepsLeft("Shamp_" .. ent:EntIndex())/5)
			ent:SetArmor(200)
			if timer.RepsLeft("Shamp_" .. ent:EntIndex()) <= 0 then
				ent:SetArmor(0)
				ent:EmitSound( "ambient/levels/labs/electric_explosion5.wav", 75, 100, 1, CHAN_AUTO)
				ent:SetNWInt("SA CooldownTimer", 15)
				timer.Create("SA Cooldown_" .. ent:EntIndex(), 1, MOD_SHAMP_COOLDOWN, function() 
					ent:SetNWInt("SA CooldownTimer", timer.RepsLeft("SA Cooldown_" .. ent:EntIndex()))
				end)
			end
		end)
	end
end

function GMCCast(ply, modid)
	if modid then
		local plyAUX = ply:GetAUX()
		local weapon = ply:GetActiveWeapon()
		
		if ply:GetNWInt(modid) > 0 then
		
			-- Heal Module
			if modid == "restorehp" then
				local InRange, ent = CheckModuleRange(ply, 200)
				
				if (InRange and SameTeam(ply, ent)) then
					local enthp = ent:Health()
					local entmaxhp = ent:GetMaxHealth()
					
					if(enthp < entmaxhp && plyAUX > (MOD_HEAL/2)) then
						StartHealTimer(ply, ent, plyAUX)
					end
				elseif(ply:Health() < ply:GetMaxHealth()) then
					StartHealTimer(ply, ply, plyAUX)
				end
				
			-- Shield Amp
			elseif modid == "shieldamp" then
				local InRange, ent = CheckModuleRange(ply, 200)
				if (InRange && ent:IsPlayer() && SameTeam(ply, ent)) then
					StartShieldTimer(ply, ent, plyAUX)
				else
					StartShieldTimer(ply, ply, plyAUX)
				end
			-- Crits
			elseif modid == "crits" then
				if(plyAUX > MOD_CRIT_COST && !ply:GetNWBool("Crits Active", false)) then
					ply:SetAUX(plyAUX - (MOD_CRIT_COST))
					ply:SetNWBool("Crits Active", true)
					ply:SetWalkSpeed(math.Round(ply:GetWalkSpeed() * (MOD_CRIT_SLOWDOWN + MOD_CRIT_UPGRADE)))
					ply:SetRunSpeed(math.Round(ply:GetRunSpeed() * (MOD_CRIT_SLOWDOWN + MOD_CRIT_UPGRADE)))
					critcolor = ply:GetNWVector("EffectColor", Vector(1,1,1)):ToColor()
					if SERVER then
						GiveMatproxyTF2CritGlow(ply, crits, critcolor.r, critcolor.g, critcolor.b)
						GiveMatproxyTF2CritGlow(weapon, crits, critcolor.r, critcolor.g, critcolor.b)
					end
				elseif ply:GetNWBool("Crits Active") then
					ply:SetNWBool("Crits Active", false)
					ply:SetWalkSpeed(baseWalkSpeed + (math.Round(baseWalkSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD)))))
					ply:SetRunSpeed(baseRunSpeed + (math.Round(baseRunSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD)))))
					if SERVER then
						RemoveTF2CritGlow(ply)
						RemoveTF2CritGlow(weapon)
					end
				end
			else
				print("Invalid module id: " .. modid)
			end
		end
	end
end

-- End of module logic

-- Update passive modules when they are upgraded.
net.Receive("UpdateModules", function(len, ply)
	ReceiveSecurity(ply, 11)
	local mod = net.ReadString()
	local lvl = net.ReadInt(8)
	local curlvl = ply:GetNWInt(mod)
	
	for _, module in pairs(modules) do
        if module.id == moduleID then
            local maxlvl = module.MAXLEVEL
        end
    end
	
	if lvl != (curlvl + 1) && ply:GetSP() < 0 && lvl <= maxlvl then
		PrintMessage(HUD_PRINTTALK, "Attempted cheating detected, " .. ply:Nick() .. "(SteamID: " .. ply:SteamID() .. ") attempted to set their modules in an impossible manner.")
	else
		ply:SetNWInt(mod, lvl)
		ply:SetSP(ply:GetSP() - 1)
		if mod == "vitality" then
			ply:SetMaxHealth(baseMaxHealth + (ply:GetNWInt("vitality") * MOD_VIT))
			ply:SetHealth(ply:Health() + MOD_VIT)
		end
		if mod == "shieldamount" then
			ply:SetMaxArmor(ply:GetMaxArmor() + (ply:GetNWInt("shieldamount") * MOD_ARM))
		end
		if mod == "movespeed" then
			ply:SetWalkSpeed(baseWalkSpeed + (baseWalkSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD))))
			ply:SetRunSpeed(baseRunSpeed + (baseRunSpeed * (ply:GetNWInt("movespeed") * (MOD_SPD))))
		end
		if mod == "auxamount" then
			ply:SetMaxAUX(baseAUX + (ply:GetNWInt("auxamount") * (MOD_AUX)))
		end
	end
end)

-- Update module tables on the client and server