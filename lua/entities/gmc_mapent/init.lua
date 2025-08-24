AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

weaponChoices = {}

-- Add this function definition
util.AddNetworkString("SendUserInputToPropSpawner")
util.AddNetworkString("PrecacheModelServerside")

net.Receive( "SendUserInputToPropSpawner", function() 
	local PropOrEnt = net.ReadString()
	local entry = net.ReadString()
	local enti = net.ReadEntity()
	
	enti:SetNWString("PropOrEnt", PropOrEnt)
	enti:SetNWString("Entry", entry)
	
	ChangeModel(enti, PropOrEnt, entry)
end)

function ChangeModel(ent, PropOrEnt, entry)
	if PropOrEnt == "Prop" then
		util.PrecacheModel(entry)
		ent:SetModel(entry)
		ent:PhysicsInit(SOLID_VPHYSICS)
	elseif PropOrEnt == "Ent" then
		local proxy
		proxy = ents.Create(entry)
		if IsValid(proxy) then
			proxy:Spawn()
			ent:SetModel(proxy:GetModel())
			proxy:Remove()
		end
		ent:PhysicsInit(SOLID_VPHYSICS)
	elseif PropOrEnt == "Vehicle" then
		vechs = list.Get("Vehicles")
		if vechs[entry] then
			ent:SetModel(vechs[entry].Model)
			ent:PhysicsInit(SOLID_VPHYSICS)
		end
	end
end

net.Receive("PrecacheModelServerside", function()
	local model = net.ReadString()
	util.PrecacheModel(model)
end)

-- Initialize the entity
function ENT:Initialize()
	self:SetModel("models/props_junk/wood_crate001a.mdl")
	self:SetUseType(SIMPLE_USE)
	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	
	self:SetNWString("PropOrEnt", "Prop")
	self:SetNWString("Entry", "models/props_junk/wood_crate001a.mdl")
end

-- Add this function definition
util.AddNetworkString("OpenSpawnGUIMenu")

-- Handle interaction
function ENT:Use(activator, caller)
	local entity = self:EntIndex()
	if IsValid(activator) and activator:IsPlayer() then
		net.Start("OpenSpawnGUIMenu")
			net.WriteEntity(Entity(entity))
		net.Send(activator)
	end
end