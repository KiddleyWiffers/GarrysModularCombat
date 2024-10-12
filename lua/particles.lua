AddCSLuaFile()

game.AddParticles("particles/gmc_particles.pcf")

PrecacheParticleSystem( "acidpool" )
PrecacheParticleSystem( "ice_bomb" )
PrecacheParticleSystem( "healing_effect" )
PrecacheParticleSystem( "healing_drips" )
PrecacheParticleSystem( "onfire" )
PrecacheParticleSystem( "teleportedin_blue" )
PrecacheParticleSystem( "teleportedin_elecblue" )
PrecacheParticleSystem( "teleportedin_green" )
PrecacheParticleSystem( "teleportedin_neutral" )
PrecacheParticleSystem( "teleportedin_orange" )
PrecacheParticleSystem( "teleportedin_pink" )
PrecacheParticleSystem( "teleportedin_purple" )
PrecacheParticleSystem( "teleportedin_red" )
PrecacheParticleSystem( "teleportedin_white" )
PrecacheParticleSystem( "teleportedin_yellow" )
PrecacheParticleSystem( "teleported_flash" )
PrecacheParticleSystem("critgun_weaponmodel_colorable")
PrecacheParticleSystem("peejar_drips_colorable")

if SERVER then
	function GiveMatproxyTF2CritGlow(ent, particle, r, g, b)

		if !IsValid(ent) then return end

		ent.ProxyentCritGlow = ents.Create("proxyent_statuseffects")

		ent.ProxyentCritGlow:SetTargetEnt(ent)
		ent.ProxyentCritGlow:SetPaintVector(Vector(r, g, b))
		if particle == crits then
			ent.ProxyentCritGlow:SetSparksColorable(true)
		elseif particle == drip then
			ent.ProxyentCritGlow:SetSparksJarateColorable(true)
		elseif particle == flame then
			ent.ProxyentCritGlow:SetSparksFlame(true)
		end

		ent.ProxyentCritGlow:Spawn()
		ent.ProxyentCritGlow:Activate()
	end
	
	function RemoveTF2CritGlow(ent)

		if IsValid(ent.ProxyentCritGlow) then
			ent.ProxyentCritGlow:Remove()
			ent.ProxyentCritGlow = nil
		end
	end
end