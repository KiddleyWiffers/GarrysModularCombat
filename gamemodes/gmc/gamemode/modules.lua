AddCSLuaFile()
include("commands.lua")
include("particles.lua")

local baseMaxHealth = 100
local baseMaxArmor = 100
local baseWalkSpeed = 200
local baseRunSpeed = 300
local baseAUX = 100

local TYPE_NORMAL = 0
local TYPE_PERCENTAGE = 1
local TYPE_WHOLE = 2
local TYPE_FLOOR = 3
local TYPE_INVERTED = 4
local TYPE_INVERTED_PERCENTAGE = 5

local FAILSOUND = "player/suit_denydevice.wav"

MOD_VIT = GetConVar("gmc_mod_vitality_increase"):GetInt()
MOD_VIT_DESC = ("Increases maximum health.")

MOD_ARM = GetConVar("gmc_mod_shield_increase"):GetInt()
MOD_ARM_DESC = ("Increases maximum armor.")

MOD_AUX = GetConVar("gmc_mod_battery_increase"):GetInt()
MOD_AUX_DESC = ("Increases maximum AUX power.")

MOD_ARMR = GetConVar("gmc_mod_shieldrecharge_increase"):GetInt()
MOD_ARMR_DELAY = GetConVar("gmc_mod_shieldrecharge_delay"):GetInt()
MOD_ARMR_DRAIN = GetConVar("gmc_mod_shieldrecharge_drain"):GetInt()
MOD_ARMR_MINAUX = GetConVar("gmc_mod_shieldrecharge_minaux"):GetInt()
MOD_ARMR_DESC = ("Automatically recharges armor over time, consuming a small amount of AUX power as it does. Does not work while regen suppression is active.")

MOD_AUXR = math.Round(GetConVar("gmc_mod_batteryrecharge_increase"):GetFloat(), 2)
MOD_AUXR_DESC = ("Increases AUX recharge rate.")

MOD_DMG = 0.05
MOD_DMG_DESC = ("Increases all weapon damage output.")

MOD_BLUNT = 0.1
MOD_BLUNT_BUFF = 0.05
MOD_BLUNT_TIME = 15
MOD_BLUNT_DESC = ("Increases melee damage and increases damage with all weapons after getting a melee kill.")

MOD_AMMORES = 0.2
MOD_AMMORES_DESC = ("Increases ammo capacity.")

MOD_SPD = 0.03
MOD_SPD_DESC = ("Increases movement speed.")

MOD_PRES = 0.05
MOD_PRES_TYPES = {DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT, DMG_SLASH, DMG_NEVERGIB}
MOD_PRES_DESC = ("Provides resistance to penetrative damage, such as bullets or sharp weapons.")

MOD_KRES = 0.05
MOD_KRES_TYPES = {DMG_BLAST, DMG_BLAST_SURFACE, DMG_ALWAYS_GIB, DMG_CLUB, DMG_CRUSH, DMG_VEHICLE, DMG_SONIC}
MOD_KRES_DESC = ("Provides resistance to kinetic damage, such as explosions, blunt weapons, or high speed objects.")

MOD_HRES = 0.05
MOD_HRES_TYPES = {DMG_BURN, DMG_SLOWBURN, DMG_POISON, DMG_PARALYZE, DMG_NERVEGAS, DMG_ACID, DMG_ENERGYBEAM, DMG_DISSOLVE, DMG_PLASMA, DMG_RADIATION}
MOD_HRES_DESC = ("Provides more resistance to hazards such as high heat, toxins, electricity, and radiation.")

local DamageTypeResistances = {}
for _, dmgType in ipairs(MOD_PRES_TYPES) do
    DamageTypeResistances[dmgType] = "pres"
end
for _, dmgType in ipairs(MOD_KRES_TYPES) do
    DamageTypeResistances[dmgType] = "kres"
end
for _, dmgType in ipairs(MOD_HRES_TYPES) do
    DamageTypeResistances[dmgType] = "hres"
end

MOD_HEAL = 10
MOD_HEAL_TIME = 5
MOD_HEAL_DESC = ("Active: Gradually restores health over time, consuming a small amount of AUX power as it does. Healing is halved while regen suppresion is active.")

MOD_JETPACK = 20
MOD_JETPACK_UP = 2
MOD_JETPACK_DESC = ("Active: Allows the user to fly by holding the jump key while in the air.")

MOD_GLIDE = -100
MOD_GLIDE_UP = 25
MOD_GLIDE_DESC = ("Active: Allows the user to glide by holding the crouch key while in the air, costs no AUX.")

MOD_CLOAK = 0.2
MOD_CLOAK_BASE = 2
MOD_CLOAK_MOVEDRAIN = 4
MOD_CLOAK_COOLDOWN = 20
MOD_CLOAK_COOLUP = 2
MOD_CLOAK_MAT = "status/cloaked"
MOD_CLOAK_DESC = ("Active: Renders the user almost entirely invisible, draining 2 AUX per second and draining cloak faster while moving. This cloak will also prevent NPCs from attacking you. Firing disables cloak, and cloak has a cooldown after being disabled.")

sound.Add( {
	name = "teleportOverwhelm",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = {100, 100},
	sound = {"gmc/teleport/teleoverwhelm1.wav", "gmc/teleport/teleoverwhelm2.wav", "gmc/teleport/teleoverwhelm3.wav", "gmc/teleport/teleoverwhelm4.wav"}
} )

MOD_TELEPORT = 100
MOD_TELEPORT_BASE = 200
MOD_TELEPORT_MODEL = "models/editor/playerstart.mdl"
MOD_TELEPORT_COST = 50
MOD_TELEPORT_COOLDOWN = 5
MOD_TELEPORT_DESC = "Active: Allows you to teleport a short distance from your current position. This costs " .. MOD_TELEPORT_COST .. " AUX power and has a " .. MOD_TELEPORT_COOLDOWN .. " second cooldown. Press your ATTACK button (MOUSE1 by default) to teleport, press your ATTACK2 (MOUSE2 by default) to cancel. If you teleport into someone, the one with less health dies, and the survivor takes damage equal to the remaining health of the dead entity. If the targets current health is more than your max health, you die instantly and the target takes no damage."
MOD_TELE_SOUND = "gmc/teleport/blink.wav"
MOD_TELE_KILLSOUND = "ambient/levels/labs/electric_explosion1.wav"
MOD_TELE_OVERWHELM_SOUND = "teleportOverwhelm"

MOD_SHAMP = 1
MOD_SHAMP_COST = 20
MOD_SHAMP_COOLDOWN = 15
MOD_SHAMP_DESC = ("Active: Increases armor to maximum for a short duration, reducing armor to 0 after the duration.")

MOD_CONFUSE = 5
MOD_CONFUSE_PLAYERS = 2
MOD_CONFUSE_DESC = ("Disorients enemies, causing them to attack anything nearby (including you and your allies); confuses players by reversing their controls.")

MOD_CRIT = 0.5
MOD_CRIT_COST = 15
MOD_CRIT_SLOWDOWN = 0.2
MOD_CRIT_UPGRADE = 0.02
MOD_CRIT_MAT = "models/alyx/emptool_glow"
MOD_CRIT_DESC = ("Greatly increases damage while reducing movement speed and consuming AUX power.")

MOD_ENERGYBALL_DAMAGE = 100
MOD_ENERGYBALL_DAMAGEUP = 10
MOD_ENERGYBALL_LIFE = 100
MOD_ENERGYBALL_LIFEUP = 10
MOD_ENERGYBALL_COST = 25
MOD_ENERGYBALL_COOLDOWN = 10
MOD_ENERGYBALL_DESC = ("A powerful ball of energy dealing signifigant damage and dissolving after a short time. The energy ball bounces off of walls and objects, allowing it to hit multiple times. It costs " .. MOD_ENERGYBALL_COST .. " AUX to fire, and has a " .. MOD_ENERGYBALL_COOLDOWN .. " second recharge time.")

MOD_FIREBOMB_DURATION = 5
MOD_FIREBOMB_DURATIONUP = 1
MOD_FIREBOMB_RANGE = 200
MOD_FIREBOMB_RANGEUP = 20
MOD_FIREBOMB_COST = 15
MOD_FIREBOMB_COOLDOWN = 20
MOD_FIREBOMB_DESC = ("A grenade that explodes on contact, igniting all nearby enemies for 8 damage a second. Flaming enemies can put themselves out with waist-high water or a Ice Grenade. It costs " .. MOD_FIREBOMB_COST .. " AUX to fire, and has a " .. MOD_FIREBOMB_COOLDOWN .. " second recharge time.")

MOD_POISONDART = 0.25
MOD_POISONDART_UP = 0.05
MOD_POISONDART_DURATION = 10
MOD_POISONDART_DURATIONUP = 0.5
MOD_POISONDART_COOLDOWN = 20
MOD_POISONDART_COST = 20
MOD_POISONDART_DESC = ("A dart that deals a percentage of the targets health, healing a portion of the health back after a short time. It costs " .. MOD_POISONDART_COST .. " AUX to fire, and has a " .. MOD_POISONDART_COOLDOWN .. " second recharge time.")

MOD_ICEBOMB = 8
MOD_ICEBOMB_UP = 0.1
MOD_ICEBOMB_RANGE = 200
MOD_ICEBOMB_COOLDOWN = 20
MOD_ICEBOMB_COST = 20
MOD_ICEBOMB_DESC = ("A grenade that explodes on contact, freezing all nearby enemies for 8 seconds. This will completly stop monsters in their tracks, but doesn't work on bosses. Players will be slowed, but will still be able to attack. It costs " .. MOD_ICEBOMB_COST .. " AUX to fire, and has a " .. MOD_ICEBOMB_COOLDOWN .. " second recharge time.")

--[[ Modules Table
	["id"] = {
		PrintName = "",
		Order = 0,
		Description = MOD_,
		Category = ,
		Icon = "vgui/gui/gmc/modules/mod",
		MAXLEVEL = 10,
		STAT = {
			{Increase, Name, Base, Type)
		}
	},
]]
modules = {
    -- Passive Modules
    ["vitality"] = {
        PrintName = "Max Health",
		Order = 1,
        Description = MOD_VIT_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/vitality",
        MAXLEVEL = 10,
        STAT = {
            {MOD_VIT, "Health", 100, TYPE_WHOLE}
        }
    },
    ["shieldamount"] = {
        PrintName = "Shield Integrity",
		Order = 1,
        Description = MOD_ARM_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/armoramount",
        MAXLEVEL = 10,
        STAT = {
            {MOD_ARM, "Shield", 100, TYPE_WHOLE}
        }
    },
    ["shieldregen"] = {
        PrintName = "Shield Recharge",
		Order = 1,
        Description = MOD_ARMR_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/armorregen.vtf",
        MAXLEVEL = 10,
        STAT = {
            {MOD_ARMR, "Regen", 0, TYPE_WHOLE},
            {MOD_ARMR_DRAIN, "Drain", 0, TYPE_WHOLE}
        }
    },
    ["auxamount"] = {
        PrintName = "AUX Batteries",
		Order = 0,
        Description = MOD_AUX_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/auxamount",
        MAXLEVEL = 10,
        STAT = {
            {MOD_AUX, "AUX", GetConVar("gmc_aux_base"):GetInt(), TYPE_WHOLE}
        }
    },
    ["auxregen"] = {
        PrintName = "AUX Recharge",
		Order = 0,
        Description = MOD_AUXR_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/auxregen",
        MAXLEVEL = 10,
        STAT = {
            {MOD_AUXR, "Regen", 0.1, TYPE_NORMAL}
        }
    },
    ["movespeed"] = {
        PrintName = "Base Speed",
		Order = 1,
        Description = MOD_SPD_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/movespeed",
        MAXLEVEL = 10,
        STAT = {
            {math.Round(baseWalkSpeed * MOD_SPD), "Walk", baseWalkSpeed, TYPE_NORMAL},
            {math.Round(baseRunSpeed * MOD_SPD), "Run", baseRunSpeed, TYPE_NORMAL}
        }
    },
	["pres"] = {
        PrintName = "Penetration Resistance",
		Order = 2,
        Description = MOD_PRES_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/pres",
        MAXLEVEL = 10,
        STAT = {
            {MOD_PRES, "Resistance", 0, TYPE_PERCENTAGE}
        }
    },
    ["kres"] = {
        PrintName = "Kinetic Resistance",
		Order = 2,
        Description = MOD_KRES_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/kres",
        MAXLEVEL = 10,
        STAT = {
            {MOD_KRES, "Resistance", 0, TYPE_PERCENTAGE}
        }
    },
    ["hres"] = {
        PrintName = "Hazard Resistance",
		Order = 2,
        Description = MOD_HRES_DESC,
        Category = "Passive",
        Icon = "vgui/gui/gmc/modules/hres",
        MAXLEVEL = 10,
        STAT = {
            {MOD_HRES, "Resistance", 0, TYPE_PERCENTAGE}
        }
    },
    -- Weapon Modules
    ["weapondmg"] = {
        PrintName = "Damage",
		Order = 0,
        Description = MOD_DMG_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/weapondmg",
        MAXLEVEL = 10,
        STAT = {
            {MOD_DMG, "Damage", 0, TYPE_PERCENTAGE}
        }
    },
    ["meleedamage"] = {
        PrintName = "Melee Damage",
		Order = 0,
        Description = MOD_BLUNT_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/bluntforce",
        MAXLEVEL = 10,
        STAT = {
            {MOD_BLUNT, "Damage", 0, TYPE_PERCENTAGE},
            {MOD_BLUNT_BUFF, "Buff", 0, TYPE_PERCENTAGE}
        }
    },
    ["ammoreserve"] = {
        PrintName = "Ammo Reserve",
		Order = 0,
        Description = MOD_AMMORES_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/ammoreserve",
        MAXLEVEL = 10,
        STAT = {
            {MOD_AMMORES, "Multiplier", 1, TYPE_PERCENTAGE}
        }
    },
    ["crits"] = {
        PrintName = "Crits",
		Order = 0,
        Description = MOD_CRIT_DESC,
        Category = "Weapons",
        Icon = "vgui/gui/gmc/modules/crits",
        Active = true,
        MAXLEVEL = 10,
        STAT = {
            {MOD_CRIT_UPGRADE, "Speed", MOD_CRIT_SLOWDOWN, TYPE_PERCENTAGE}
        }
    },
    -- Target Modules
    ["restorehp"] = {
        PrintName = "Heal",
		Order = 0,
        Description = MOD_HEAL_DESC,
        Category = "Target",
        Icon = "vgui/gui/gmc/modules/heal",
        Active = true,
        MAXLEVEL = 10,
        STAT = {
            {MOD_HEAL, "Heal", 0, TYPE_WHOLE},
            {MOD_HEAL / 2, "Cost", 0, TYPE_WHOLE}
        }
    },
    ["shieldamp"] = {
        PrintName = "Shield Amp",
		Order = 0,
        Description = MOD_SHAMP_DESC,
        Category = "Target",
        Icon = "vgui/gui/gmc/modules/shieldamp",
        Active = true,
        MAXLEVEL = 10,
        STAT = {
            {MOD_SHAMP, "Time", 0, TYPE_NORMAL}
        }
    },
    -- Movement Modules
    ["jetpack"] = {
        PrintName = "Jetpack",
		Order = 0,
        Description = MOD_JETPACK_DESC,
        Category = "Movement",
        Icon = "vgui/gui/gmc/modules/jetpack",
        Active = false,
        MAXLEVEL = 5,
        STAT = {
            {MOD_JETPACK_UP, "Cost", MOD_JETPACK, TYPE_INVERTED}
        }
    },
	["cloak"] = {
        PrintName = "Cloak",
		Order = 0,
        Description = MOD_CLOAK_DESC,
        Category = "Movement",
        Icon = "vgui/gui/gmc/modules/cloak",
        Active = true,
        MAXLEVEL = 10,
        STAT = {
            {MOD_CLOAK, "Move Cost", MOD_CLOAK_MOVEDRAIN, TYPE_INVERTED},
			{MOD_CLOAK_COOLUP, "Cooldown", MOD_CLOAK_COOLDOWN, TYPE_INVERTED}
        }
    },
	["glide"] = {
        PrintName = "Glide",
		Order = 0,
        Description = MOD_GLIDE_DESC,
        Category = "Movement",
        Icon = "vgui/gui/gmc/modules/glide",
        Active = false,
        MAXLEVEL = 5,
        STAT = {
            {MOD_GLIDE_UP, "Fall Speed", 112 - MOD_GLIDE, TYPE_INVERTED}
        }
    },
	["teleport"] = {
		PrintName = "Teleport",
		Order = 0,
		Description = MOD_TELEPORT_DESC,
		Category = "Movement",
		Icon = "vgui/gui/gmc/modules/teleport",
		Active = true,
		MAXLEVEL = 5,
		STAT = {
			{MOD_TELEPORT, "Distance", MOD_TELEPORT_BASE, TYPE_WHOLE}
		}
	},
    -- Projectile Modules
    ["energyball"] = {
        PrintName = "Energy Ball",
		Order = 0,
        Description = MOD_ENERGYBALL_DESC,
        Category = "Projectile",
        Icon = "vgui/gui/gmc/modules/energyball",
        Active = true,
        MAXLEVEL = 10,
        COOLDOWN = MOD_ENERGYBALL_COOLDOWN,
        STAT = {
            {MOD_ENERGYBALL_DAMAGEUP, "Damage", MOD_ENERGYBALL_DAMAGE, TYPE_WHOLE},
            {MOD_ENERGYBALL_LIFEUP, "Lifetime", MOD_ENERGYBALL_LIFE, TYPE_WHOLE}
        },
        PROJ = {
            "gmc_energy_ball", -- projectileType
            1000, -- speed
            SoundDuration("weapons/cguard/charging.wav"), -- delay (optional)
            "weapons/irifle/irifle_fire2.wav", -- sound (optional)
            "weapons/cguard/charging.wav", -- delaysound (optional)
            MOD_ENERGYBALL_COST -- cost
        }
    },
    ["firegrenade"] = {
        PrintName = "Flame Grenade",
		Order = 0,
        Description = MOD_FIREBOMB_DESC,
        Category = "Projectile",
        Icon = "vgui/gui/gmc/modules/firegrenade",
        Active = true,
        MAXLEVEL = 10,
        COOLDOWN = MOD_FIREBOMB_COOLDOWN,
        STAT = {
            {MOD_FIREBOMB_DURATIONUP, "Duration", MOD_FIREBOMB_DURATION, TYPE_WHOLE},
            {MOD_FIREBOMB_RANGEUP, "Range", MOD_FIREBOMB_RANGE, TYPE_WHOLE}
        },
        PROJ = {
            "gmc_fire_grenade", -- projectileType
            1500, -- speed
            0, -- delay (optional)
            "weapons/grenade_launcher1.wav", -- sound (optional)
            "", -- delaysound (optional)
            MOD_FIREBOMB_COST -- cost
        }
    },
    ["poisondart"] = {
        PrintName = "Neruotoxin Dart",
		Order = 0,
        Description = MOD_POISONDART_DESC,
        Category = "Projectile",
        Icon = "vgui/gui/gmc/modules/poisondart",
        Active = true,
        MAXLEVEL = 10,
        COOLDOWN = MOD_POISONDART_COOLDOWN,
        STAT = {
            {MOD_POISONDART_UP, "Percent", MOD_POISONDART, TYPE_PERCENTAGE},
            {MOD_POISONDART_DURATIONUP, "Heal Ticks", MOD_POISONDART_DURATION, TYPE_FLOOR}
        },
        PROJ = {
            "gmc_poisondart", -- projectileType
            2000, -- speed
            0, -- delay (optional)
            "", -- sound (optional)
            "", -- delaysound (optional)
            MOD_POISONDART_COST -- cost
        }
    },
	["icebomb"] = {
        PrintName = "Ice Bomb",
		Order = 0,
        Description = MOD_ICEBOMB_DESC,
        Category = "Projectile",
        Icon = "vgui/gui/gmc/modules/icebomb",
        Active = true,
        MAXLEVEL = 10,
        COOLDOWN = MOD_ICEBOMB_COOLDOWN,
        STAT = {
            {MOD_ICEBOMB_UP, "Slowdown", 0, TYPE_NORMAL},
        },
        PROJ = {
            "gmc_ice_grenade", -- projectileType
            1500, -- speed
            0, -- delay (optional)
            "weapons/grenade_launcher1.wav", -- sound (optional)
            "", -- delaysound (optional)
            MOD_ICEBOMB_COST -- cost
        }
    }
}

-- Passive modules
timer.Create("Armor Regen", 1, 0, function()
	for _, ply in pairs(player.GetAll()) do
		local armreg = ply:GetMod("shieldregen")
		local plyAUX = ply:GetAUX()
		local plyMaxAUX = ply:GetMaxAUX()
		if SERVER and (armreg > 0 and ply:Armor() < ply:GetMaxArmor()) && !ply.RegenSuppress then
			local armorincrease = ply:Armor() + (MOD_ARMR * armreg)
			if plyAUX > (plyMaxAUX * (MOD_ARMR_MINAUX / 100)) then
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

-- Modules to apply on spawn (Speed, Health, Armor, etc.)
hook.Add("PlayerSpawn", "SetStats", function(ply)
	ply:SetMaxHealth(ply:GetMaxHealth() + (ply:GetMod("vitality") * MOD_VIT))
	ply:SetHealth(ply:Health() + (ply:GetMod("vitality") * MOD_VIT))
	ply:SetMaxArmor(ply:GetMaxArmor() + (ply:GetMod("shieldamount") * MOD_ARM))
	ply:SetWalkSpeed(baseWalkSpeed + math.Round(baseWalkSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
	ply:SetRunSpeed(baseRunSpeed + math.Round(baseRunSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
	ply.Bluntforce = 0
	ply.CritsActive = false
	UnCloakPly(ply)
	ply.effectcolor = ply:GetNWVector("EffectColor", Vector(1, 1, 1)):ToColor()
end)

if SERVER then
	util.AddNetworkString("HealParticles")
	util.AddNetworkString("GMCast")
	util.AddNetworkString("SendLevelToProjectile")

	net.Receive("GMCast", function(len, ply)
		local modid = net.ReadString()

		ReceiveSecurity(ply, 10)
		GMCCast(ply, modid)
	end)
		
	local function MaterialTest(ply)
		if ply.CritsActive then return true
		elseif ply.Cloaked then return true
		else return false end
	end

	-- Quick timer to simulate a think function but not as resource heavy.
	timer.Create("SERVERSlowThink", 0.1, 0, function()
		for _, ply in pairs(player.GetAll()) do
			local weapon = ply:GetActiveWeapon()

			local plyAUX = ply:GetAUX()

			if ply.CritsActive and plyAUX >= 0 and weapon:IsValid() then
				ply:SetAUX(plyAUX - (MOD_CRIT_COST / 10))
				weapon:SetMaterial(MOD_CRIT_MAT)
				weapon:SetColor(ply.effectcolor)
			elseif ply.CritsActive and plyAUX <= 0 then
				ply.CritsActive = false
				ply:SetWalkSpeed(baseWalkSpeed + math.Round(baseWalkSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
				ply:SetRunSpeed(baseRunSpeed + math.Round(baseRunSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
				RemoveTF2CritGlow(ply)
				RemoveTF2CritGlow(weapon)
			end
			if !MaterialTest(ply) and weapon:IsValid() and weapon:GetMaterial() != "" then
				weapon:SetMaterial("")
				weapon:SetColor(Color(255, 255, 255, 255))
			end
		end
	end)
end

-- Damage modifier implementation
hook.Add("EntityTakeDamage", "DamageModules", function(target, dmg)
	if IsValid(target) and IsValid(dmg:GetAttacker()) and dmg:GetAttacker():IsPlayer() then
		local player = dmg:GetAttacker()
		local enemy = target
		local damage = dmg:GetDamage()

		if player:GetMod("weapondmg") > 0 then
			dmg:SetDamage(math.Round(damage + (damage * (MOD_DMG * player:GetMod("weapondmg")))))
			damage = dmg:GetDamage()
		end

		-- List of extra weapons that aren't registered by the find function.
		-- We can also use false on this list to set non-melee weapons that are being registered as melee.
		local meleeweaponlist = {
			weapon_crowbar = true,
		}

		-- Apply melee damage
		if player:GetMod("meleedamage") > 0 and IsValid(player) then
			if meleeweaponlist[player:GetActiveWeapon():GetClass()] then
				dmg:SetDamage(math.Round(damage + (damage * (MOD_BLUNT * player:GetMod("meleedamage")))))
				damage = dmg:GetDamage()
				player.LastAttackWasMelee = true
			elseif not dmg:IsBulletDamage() and not dmg:IsExplosionDamage() and (dmg:GetInflictor() == player:GetActiveWeapon()) and (player:GetPos():Distance(target:GetPos()) < 100) and (meleeweaponlist[player:GetActiveWeapon():GetClass()] ~= false) then
				dmg:SetDamage(math.Round(damage + (damage * (MOD_BLUNT * player:GetMod("meleedamage")))))
				damage = dmg:GetDamage()
				player.LastAttackWasMelee = true
			else
				player.LastAttackWasMelee = false
			end
		end

		-- Apply Bluntforce damage
		if player.Bluntforce > 0 then
			dmg:SetDamage(damage + math.Round((damage * (MOD_BLUNT_BUFF * player.Bluntforce))))
			damage = dmg:GetDamage()
		end

		-- Apply Crit damage
		if player.CritsActive then
			dmg:SetDamage(damage + math.Round(damage * MOD_CRIT))
			damage = dmg:GetDamage()
		end
	end
		
	if IsValid(target) then
		local damage = dmg:GetDamage()
		-- Apply Resistances
		if target:IsPlayer() then
			local damageType = dmg:GetDamageType() -- Get the type of damage dealt
			local resistanceKey = DamageTypeResistances[damageType] -- Find the resistance type for the damage
			if resistanceKey then
				local mod = target:GetMod(resistanceKey) * _G["MOD_" .. resistanceKey:upper()] -- Calculate the resistance modifier
				if mod > 0 then
					dmg:SetDamage(damage - math.Round(damage * mod))
					damage = dmg:GetDamage()
				end
			end
		end
	end
end)

-- Bluntforce Function
local function HandleBluntforce(attacker)
	local meleelevel = attacker:GetMod("meleedamage")
	if IsValid(attacker) and meleelevel > 0 and attacker.LastAttackWasMelee == true then
		if timer.Exists("Bluntforce_" .. attacker:EntIndex()) then
			timer.Start("Bluntforce_" .. attacker:EntIndex())
		else
			timer.Create("Bluntforce_" .. attacker:EntIndex(), MOD_BLUNT_TIME, 1, function()
				attacker.Bluntforce = 0
			end)
		end

		-- Ensure Bluntforce doesn't exceed meleedamage
		attacker.Bluntforce = attacker.Bluntforce or 0
		if attacker.Bluntforce < meleelevel then
			attacker.Bluntforce = attacker.Bluntforce + 1
		end
	end
end
		
-- On Kill effects
hook.Add("OnNPCKilled", "NPCKillEffect", function(victim, attacker, inflictor)
	if IsValid(attacker) and IsValid(victim) and attacker:IsPlayer() then
		HandleBluntforce(attacker)
	end
end)

hook.Add("PlayerDeath", "PlayerKillEffect", function(victim, attacker, inflictor)
	if IsValid(attacker) and IsValid(victim) and attacker:IsPlayer() then
		victim.CritsActive = false
		victim.Cloaked = false
		if attacker:IsPlayer() then
			HandleBluntforce(attacker)
		end
	end
end)

-- Active Modules casting
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
		return ent1:Team() == ent2.GMCTeam
	end
end

local function ReduceAuxPower(ply, amount)
	local plyAUX = ply:GetAUX()
	if plyAUX >= amount then
		ply:SetAUX(plyAUX - amount)
		return true
	else
		ply:EmitSound(FAILSOUND, 75, 100, 1, CHAN_AUTO, 0, 0, ply)
		return false
	end
end

-- Firing projectiles uses this function.
function FireProjectile(ply, mod, projectileType, speed, delay, sound, delaysound)
	if not IsValid(ply) then return end

	delay = delay or 0
	sound = sound or nil

	local function DoFire()
		if ply:Alive() then
			local startPos = ply:GetShootPos()
			local aimDir = ply:GetAimVector()

			local projectile = ents.Create(projectileType)
			if not IsValid(projectile) then return end

			projectile:SetPos(startPos)
			projectile.Owner = ply
			projectile.Level = ply:GetMod(mod)
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
	end

	if delay > 0 then
		if delaysound != nil then
			ply:EmitSound(delaysound)
		end
		timer.Simple(delay, DoFire)
	else
		DoFire()
	end
end

local function HandleProjectile(ply, mod)
	local data = modules[mod]
	if not (ply:GetMod(mod) > 0) then return end
	
	if timer.Exists(mod .. "Cooldown" .. ply:EntIndex()) then return end
	
	timer.Create(mod .. "Cooldown" .. ply:EntIndex(), data.COOLDOWN, 1, function() end)
	
	-- Check if the module has a PROJ table
	if data and data.PROJ then
		local projectileType = data.PROJ[1]  -- projectile entity class
		local speed = data.PROJ[2]           -- projectile speed
		local delay = data.PROJ[3] or 0      -- optional delay (default to 0)
		local sound = data.PROJ[4] or nil    -- optional fire sound
		local delaysound = data.PROJ[5] or nil  -- optional delay sound
		local cost = data.PROJ[6] or 0 -- projectile cost
		
		local success = ReduceAuxPower(ply, cost)
		-- Call FireProjectile function
		if success then
			FireProjectile(ply, mod, projectileType, speed, delay, sound, delaysound)
		end
	end
end

-- Specific Module Functions
local function StartHealTimer(healer, healing, plyAUX)
	if not timer.Exists("Heal_" .. healing:EntIndex()) then
		timer.Create("Heal_" .. healing:EntIndex(), 1, MOD_HEAL_TIME, function()
			local healamount = MOD_HEAL
			if plyAUX > (MOD_HEAL / 2) then
				ReduceAuxPower(healer, MOD_HEAL / 2)
				if healing.RegenSuppress then
					healamount = healamount/2
				end
				if (healing:Health() + healamount) < healing:GetMaxHealth() then 
					healing:SetHealth(math.Clamp(healing:Health() + math.Round((healamount / MOD_HEAL_TIME) * healer:GetMod("restorehp")), 0, healing:GetMaxHealth()))
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
end

local function StartShieldTimer(ply, ent, plyAUX)
	if plyAUX > (MOD_SHAMP_COST) and not timer.Exists("ShampCooldown_" .. ent:EntIndex()) and not timer.Exists("Shamp_" .. ent:EntIndex()) then
		ent:SetAUX(plyAUX - (MOD_SHAMP_COST))
		ent:EmitSound("npc/scanner/scanner_electric2.wav", 75, 100, 1, CHAN_AUTO)
		timer.Create("Shamp_" .. ent:EntIndex(), 0.2, ply:GetMod("shieldamp") * 5, function()
			ent:SetArmor(200)
			if timer.RepsLeft("Shamp_" .. ent:EntIndex()) <= 0 then
				ent:SetArmor(0)
				ent:EmitSound("ambient/levels/labs/electric_explosion5.wav", 75, 100, 1, CHAN_AUTO)
				timer.Create("ShampCooldown_" .. ent:EntIndex(), MOD_SHAMP_COOLDOWN, 1, function() end)
			end
		end)
	end
end

-- Module handlers for casting active modules
local CastMod = {}

CastMod["restorehp"] = function(ply)
	local plyAUX = ply:GetAUX()
	local InRange, ent = CheckModuleRange(ply, 200)
	
	if (InRange and SameTeam(ply, ent)) then
		local enthp = ent:Health()
		local entmaxhp = ent:GetMaxHealth()
					
		if enthp < entmaxhp and plyAUX > (MOD_HEAL / 2) then
			StartHealTimer(ply, ent, plyAUX)
		end
	elseif ply:Health() < ply:GetMaxHealth() then
		StartHealTimer(ply, ply, plyAUX)
	end
end

CastMod["shieldamp"] = function(ply)
	local plyAUX = ply:GetAUX()
	local InRange, ent = CheckModuleRange(ply, 200)
	if (InRange and ent:IsPlayer() and SameTeam(ply, ent)) then
		StartShieldTimer(ply, ent, plyAUX)
	else
		StartShieldTimer(ply, ply, plyAUX)
	end
end

CastMod["crits"] = function(ply)
	local plyAUX = ply:GetAUX()
	local weapon = ply:GetActiveWeapon()
	if plyAUX > MOD_CRIT_COST and not ply.CritsActive then
		ply:SetAUX(plyAUX - MOD_CRIT_COST)
		ply.CritsActive = true
		ply:SetWalkSpeed(math.Round(ply:GetWalkSpeed() * (MOD_CRIT_SLOWDOWN + MOD_CRIT_UPGRADE)))
		ply:SetRunSpeed(math.Round(ply:GetRunSpeed() * (MOD_CRIT_SLOWDOWN + MOD_CRIT_UPGRADE)))
		ply:EmitSound( "gmc/crits_on.wav", 75, 100, 1, CHAN_WEAPON )
		critcolor = ply:GetNWVector("EffectColor", Vector(1,1,1)):ToColor()
		if SERVER then
			GiveMatproxyTF2CritGlow(ply, crits, critcolor.r, critcolor.g, critcolor.b)
			GiveMatproxyTF2CritGlow(weapon, crits, critcolor.r, critcolor.g, critcolor.b)
		end
	elseif ply.CritsActive then
		ply.CritsActive = false
		ply:SetWalkSpeed(baseWalkSpeed + math.Round(baseWalkSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
		ply:SetRunSpeed(baseRunSpeed + math.Round(baseRunSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
		ply:EmitSound( "gmc/crits_off.wav", 75, 100, 1, CHAN_WEAPON )
		if SERVER then
			RemoveTF2CritGlow(ply)
			RemoveTF2CritGlow(weapon)
		end
	end
end

function CloakPly(target)
	timer.Start("Cloak_" .. target:EntIndex())
	target:EmitSound( "gmc/cloak.wav", 50, 100, 1, CHAN_AUTO )
	target:DrawShadow(false)
	target:SetMaterial(MOD_CLOAK_MAT)
	if SERVER then
		target:SetNoTarget(true)
	end
	target.Cloaked = true
end
		
function UnCloakPly(target)
	if target.Cloaked then
		timer.Pause("Cloak_" .. target:EntIndex())
		target:EmitSound( "gmc/uncloak.wav", 50, 100, 1, CHAN_AUTO )
		target:SetMaterial("")
		target:DrawShadow(true)
		if SERVER then
			target:SetNoTarget(false)
		end
		target.Cloaked = false
		target.CloakCooldown = CurTime() + (MOD_CLOAK_COOLDOWN - (MOD_CLOAK_COOLUP * target:GetMod("cloak")))
	end
end

CastMod["cloak"] = function(ply)
	local plyAUX = ply:GetAUX()
	local baseDrain = MOD_CLOAK_BASE
	local maxDrain = MOD_CLOAK_BASE + MOD_CLOAK_MOVEDRAIN
	local minSpeed = ply:GetWalkSpeed() * ply:GetCrouchedWalkSpeed() -- Crouch walk speed
	local maxSpeed = ply:GetRunSpeed() -- Run speed

	if not timer.Exists("Cloak_" .. ply:EntIndex()) then
		timer.Create("Cloak_" .. ply:EntIndex(), 0.1, 0, function()
			ply:RemoveAllDecals()
			local plySpeed = ply:GetVelocity():Length2D()
				
			local wep = ply:GetActiveWeapon()
			if wep:GetMaterial() != MOD_CLOAK_MAT then
				wep:SetMaterial(MOD_CLOAK_MAT)
			end

			local drain = baseDrain + (maxDrain - baseDrain) * math.Clamp((plySpeed - minSpeed) / (maxSpeed - minSpeed), 0, 1)
			if plyAUX > drain then
				plyAUX = ply:GetAUX()
				ply:SetAUX(plyAUX - (drain * 0.2))
			else
				timer.Pause("Cloak_" .. ply:EntIndex())
				UnCloakPly(ply)
			end
		end)
		timer.Pause("Cloak_" .. ply:EntIndex())
		ply.CloakCooldown = 0
		ply.Cloaked = false
	end
	
	if not ply.Cloaked and ply.CloakCooldown <= CurTime() then
		CloakPly(ply)
	else
		UnCloakPly(ply)
	end
end

CastMod["teleport"] = function(ply)
	if ply.TeleCooldown == nil then
		ply.TeleCooldown = 0
	end
	if ply.TeleCooldown <= CurTime() then
		ply.Teleporting = true
		
		if not IsValid(ply.TeleportMarker) then
			ply.TeleportMarker = ents.Create("gmc_teleportmarker")
			ply.TeleportMarker:SetModel(MOD_TELEPORT_MODEL)
			ply.TeleportMarker:SetMaterial("effects/hologram")
			ply.TeleportMarker:SetColor(ply:GetPlayerColor():ToColor())
			ply.TeleportMarker:SetOwner(ply)
			ply.TeleportMarker:Spawn()

			local TELEPORT_MAX_DISTANCE = MOD_TELEPORT_BASE + (MOD_TELEPORT * ply:GetMod("teleport"))

			hook.Add("Think", "UpdateTeleportMarker_" .. ply:EntIndex(), function()
				if not ply.Teleporting or not IsValid(ply) or not ply:Alive() or not IsValid(ply.TeleportMarker) then
					if IsValid(ply) then
						ply.Teleporting = false
					end
					if IsValid(ply.TeleportMarker) then
						ply.TeleportMarker:Remove()
					end
					hook.Remove("Think", "UpdateTeleportMarker_" .. ply:EntIndex())
					return
				end

				local trace = {}
				trace.start = ply:EyePos()
				trace.endpos = ply:EyePos() + ply:GetAimVector() * TELEPORT_MAX_DISTANCE
				trace.filter = function(ent) return !(ent:GetClass() == "prop_physics" or ent == ply) end

				local tr = util.TraceLine(trace)

				-- Restrict marker range
				local distance = ply:GetPos():Distance(tr.HitPos)
				if distance > TELEPORT_MAX_DISTANCE then
					local direction = (tr.HitPos - ply:GetPos()):GetNormalized()
					tr.HitPos = ply:GetPos() + direction * TELEPORT_MAX_DISTANCE
				end

				-- Place and rotate the marker
				if IsValid(ply.TeleportMarker) then
					ply.TeleportMarker:SetPos(tr.HitPos)
					ply.TeleportMarker:SetAngles(Angle(0, ply:EyeAngles().y, 0))
				end
			end)
		end

		hook.Add("StartCommand", "TeleportControl_" .. ply:EntIndex(), function(plyCmd, cmd)
			if not ply.Teleporting then
				hook.Remove("StartCommand", "TeleportControl_" .. plyCmd:EntIndex())
				return
			end

			local weapon = ply:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetNextPrimaryFire(CurTime() + 0.2)
				weapon:SetNextSecondaryFire(CurTime() + 0.2)
			end

			if cmd:KeyDown(IN_ATTACK) then
				local markerPos = ply.TeleportMarker:GetPos()
				local markerAngles = ply.TeleportMarker:GetAngles()
				local forwardVector = markerAngles:Forward()
				
				local enoughAUX = ReduceAuxPower(ply, MOD_TELEPORT_COST)
				if not enoughAUX then
					cmd:RemoveKey(IN_ATTACK)
					ply.Teleporting = false
					return
				end
				
				ParticleEffect("teleported_flash2", ply:GetPos(), Angle(0, 0, 0))

				-- Wall trace using marker's position and forward vector
				local wallTrace = util.TraceLine({
					start = markerPos,
					endpos = markerPos + forwardVector * 80, -- Check within 80 hammer units
					filter = ply,
				})

				if wallTrace.Hit and wallTrace.HitWorld then
					local normal = wallTrace.HitNormal
					-- Adjust the teleport position to move 20 units away from the wall
					markerPos = markerPos + normal * 20
				end

				-- Ceiling trace directly upward
				local ceilingTrace = util.TraceLine({
					start = markerPos,
					endpos = markerPos + Vector(0, 0, 100), -- Check upward 100 units
					filter = ply,
				})

				if ceilingTrace.Hit and ceilingTrace.HitWorld then
					-- Adjust the teleport position downward by 100 units
					markerPos = markerPos - Vector(0, 0, 100)
				end

				-- Set final teleport position
				ply:SetPos(markerPos + Vector(0, 0, 5)) -- Offset to prevent clipping
				ply:EmitSound(MOD_TELE_SOUND, 125, 90, 1, CHAN_STATIC)
				ParticleEffect("teleported_flash", ply:GetPos(), Angle(0, 0, 0))

				-- Telefrag logic
				local teleScan = ents.FindInSphere(markerPos, 20)
				local telefragTargets = {}

				for k, v in pairs(teleScan) do
					if v:GetClass() == "prop_physics" or v:GetClass() == "prop_static" or v:GetClass() == "prop_dynamic" or v:GetClass() == "prop_door_rotating" or v:GetClass() == "prop_door" then
						if v:Health() > 1 then
							v:TakeDamage(v:GetMaxHealth())
						end
					end
					if v:IsNPC() or v:IsNextBot() or (v:IsPlayer() and v:Alive() and v != ply) then
						table.insert(telefragTargets, v)
					end
				end

				local target = nil
				if #telefragTargets > 1 then
					-- Overwhelmed by multiple entities
					ply:TakeDamage(ply:GetMaxHealth())
					ply:EmitSound(MOD_TELE_OVERWHELM_SOUND)
				else
					target = telefragTargets[1]
				end

				if IsValid(target) and (target:IsPlayer() or target:IsNPC()) then
					local playerMaxHealth = ply:GetMaxHealth()
					local targetMaxHealth = target:GetMaxHealth() or 0
					local playerCurrentHealth = ply:Health()
					local targetCurrentHealth = target:Health()

					if targetCurrentHealth > playerMaxHealth then
						-- Player killed
						ply:TakeDamage(playerCurrentHealth)
						ply:EmitSound(MOD_TELE_OVERWHELM_SOUND)
					elseif playerMaxHealth >= targetCurrentHealth then
						-- Both take damage equal to the lowest current health
						local damage = math.min(playerCurrentHealth, targetCurrentHealth)
						ply:TakeDamage(damage)
						target:TakeDamage(damage, ply, ply)
						ply:EmitSound(MOD_TELE_KILLSOUND)
					end
				end

				cmd:RemoveKey(IN_ATTACK)
				ply.Teleporting = false
				ply.TeleCooldown = CurTime() + (MOD_TELEPORT_COOLDOWN)
			elseif cmd:KeyDown(IN_ATTACK2) then
				-- Cancel teleport
				cmd:RemoveKey(IN_ATTACK2)
				ply.Teleporting = false
			end
		end)
	end
end

CastMod["weaken"] = function(ply)
	local plyAUX = ply:GetAUX()
	local InRange, ent = CheckModuleRange(ply, 1000)
	
	if (InRange and SameTeam(ply, ent)) then
		local enthp = ent:Health()
		local entmaxhp = ent:GetMaxHealth()
					
		if enthp < entmaxhp and plyAUX > (MOD_HEAL / 2) then
			StartHealTimer(ply, ent, plyAUX)
		end
	elseif ply:Health() < ply:GetMaxHealth() then
		StartHealTimer(ply, ply, plyAUX)
	end
end

hook.Add("StartCommand", "KeyModifiers", function(ply, cmd)
	-- Prevent Fire While Cloaking
    if ply.Cloaked and cmd:KeyDown(IN_ATTACK) then
        cmd:RemoveKey(IN_ATTACK)
	elseif ply.Cloaked and cmd:KeyDown(IN_ATTACK2) then
		cmd:RemoveKey(IN_ATTACK2)
    end
end)

function GMCCast(ply, modid)
	if modid then
		if modules[modid] and modules[modid].Category == "Projectile" and modules[modid].PROJ then
			HandleProjectile(ply, modid)
		elseif ply:GetMod(modid) > 0 and CastMod[modid] then
			CastMod[modid](ply)
		else
			print("Invalid module id: " .. modid)
		end
	end
end
-- end of module logic

-- Update passive modules when they are upgraded.
net.Receive("UpdateModules", function(len, ply)
	ReceiveSecurity(ply, 11)
	local mod = net.ReadString()
	local lvl = net.ReadInt(8)
	local curlvl = ply:GetMod(mod)
	
	for com, data in pairs(modules) do
        if com == moduleID then
            local maxlvl = module.MAXLEVEL
        end
    end
	
	if lvl != (curlvl + 1) and ply:GetSP() < 0 and lvl <= maxlvl then
		PrintMessage(HUD_PRINTTALK, "Attempted cheating detected, " .. ply:Nick() .. "(SteamID: " .. ply:SteamID() .. ") attempted to set their modules in an impossible manner.")
	else
		ply.ModulesData[mod] = lvl
		ply:SetSP(ply:GetSP() - 1)
		if mod == vitality then
			ply:SetMaxHealth(baseMaxHealth + (ply:GetMod("vitality") * MOD_VIT))
			ply:SetHealth(ply:Health() + MOD_VIT)
		end
		if mod == "shieldamount" then
			ply:SetMaxArmor(ply:GetMaxArmor() + (ply:GetMod("shieldamount") * MOD_ARM))
		end
		if mod == "movespeed" then
			ply:SetWalkSpeed(baseWalkSpeed + (baseWalkSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
			ply:SetRunSpeed(baseRunSpeed + (baseRunSpeed * (ply:GetMod("movespeed") * MOD_SPD)))
		end
		if mod == "auxamount" then
			ply:SetMaxAUX(baseAUX + (ply:GetMod("auxamount") * MOD_AUX))
		end
	end
end)

if CLIENT then
	-- Quick timer to simulate a think function but not as resource heavy.
	timer.Create("CLIENTModuleThink", 0.1, 0, function()
		
	end)

	-- Particle Receives
	net.Receive("HealParticles", function()
		local ent = net.ReadEntity()

		if IsValid(ent) then
			local healparticle = CreateParticleSystem(ent, "healing_effect", PATTACH_ABSORIGIN_FOLLOW, 0, ent:OBBCenter())

			healparticle:SetControlPointEntity(1, ent)
			timer.Simple(MOD_HEAL_TIME, function()
				if healparticle != nil then
					healparticle:StopEmission(false, false, false)
				end
			end)
		end
	end)
end