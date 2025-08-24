AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Teleport Marker"
ENT.Author = "Kiddley"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	self:SetModel("models/editor/playerstart.mdl") 
	self:SetSolid(SOLID_NONE)
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(false)
end

if CLIENT then
	function ENT:Draw()
		local owner = self:GetOwner()

		if IsValid(owner) and owner == LocalPlayer() then
			self:DrawModel()
		end
	end
end