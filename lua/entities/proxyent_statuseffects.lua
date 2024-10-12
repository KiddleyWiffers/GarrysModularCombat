AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.PrintName			= "Proxy Ent - TF2 Crit Glow"
ENT.Author			= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup			= RENDERGROUP_NONE

function ENT:SetupDataTables()

	self:NetworkVar("Entity", 0, "TargetEnt")
	self:NetworkVar("Vector", 1, "PaintVector")

	self:NetworkVar("Bool", 0, "SparksColorable")
	self:NetworkVar("Bool", 1, "SparksJarateColorable")
	self:NetworkVar("Bool", 2, "SparksFlame")

end

function ENT:Initialize()
	local targetent = self:GetTargetEnt()

	if !IsValid(targetent) then MsgN("Crit glow entity has no target!") self:Remove() return end
	if !self:GetPaintVector() then MsgN("Crit glow entity has no color set!") self:Remove() return end

	targetent.ProxyentCritGlow = self

	self:SetPos(targetent:GetPos())
	self:SetParent(targetent)
	self:SetNoDraw(true)
	self:SetModel("models/props_junk/watermelon01.mdl") //dummy model to prevent addons that look for the error model from affecting this entity
	self:DrawShadow(false) //make sure the ent's shadow doesn't render, just in case RENDERGROUP_NONE/SetNoDraw don't work and we have to rely on the blank draw function

	PrecacheParticleSystem("critgun_weaponmodel_colorable")
	PrecacheParticleSystem("peejar_drips_colorable")

	if CLIENT then
		self.SparkParticleEffects = {}
		if self:GetSparksColorable() then
			self.SparkParticleEffects.SparksColorable = targetent:CreateParticleEffect("critgun_weaponmodel_colorable", {
				{entity = targetent, attachtype = PATTACH_ABSORIGIN_FOLLOW},  //we overbrighten the color value (second controlpoint) by a large amount because
				{position = (Vector(65,65,65) + (self:GetPaintVector() * 3))} //crit color values actually tend to be pretty low to avoid overpowering the texture
			})
		end
		if self:GetSparksJarateColorable() then
			self.SparkParticleEffects.SparksJarateColorable = targetent:CreateParticleEffect("peejar_drips_colorable", {
				{entity = targetent, attachtype = PATTACH_ABSORIGIN_FOLLOW},  //we overbrighten the color value for jarate drips even more,
				{position = self:GetPaintVector() * 40}			      //because jarate color values are so low they're in the single digits
			})
		end
		if self:GetSparksFlame() then
			self.SparkParticleEffects.Flame = targetent:CreateParticleEffect("onfire", {
				{entity = targetent, attachtype = PATTACH_ABSORIGIN_FOLLOW}} 
			)
		end
	end
end




function ENT:OnRemove()
	local targetent = self:GetTargetEnt()
	if IsValid(targetent) then
		if CLIENT then
			for _, particle in pairs(self.SparkParticleEffects) do
				particle:StopEmission()
			end
		end

		if SERVER then
			if IsValid(self.KritzPartCritGlow) then
				self.KritzPartCritGlow:Remove()
			end
		end

		if targetent.ProxyentCritGlow == self then 
			targetent.ProxyentCritGlow = nil
		end
	end
end




//Entity still renders for some users despite having RENDERGROUP_NONE and self:SetNoDraw(true) (why?), so try to get around this by having a blank draw function
function ENT:Draw()
end