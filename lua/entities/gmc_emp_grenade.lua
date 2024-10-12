AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")  -- Define a base class for the entity

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "EMP Grenade"
ENT.Author = "Kiddley"
ENT.Information = "A custom EMP grenade."
ENT.Category = "Garry's Modular Combat"

ENT.Spawnable = false
ENT.AdminOnly = false

-- Define customizable values
ENT.Damage = 15