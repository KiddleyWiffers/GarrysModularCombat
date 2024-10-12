DEFINE_BASECLASS("player_default")

-- Define the new player class
local PLAYER = {}

PLAYER.DisplayName = "GMCClass"
PLAYER.WalkSpeed = 200
PLAYER.RunSpeed = 400
PLAYER.CrouchedWalkSpeed = 0.4
PLAYER.DuckSpeed = 0.3
PLAYER.UnDuckSpeed = 0.4
PLAYER.CanUseFlashlight = true
PLAYER.AmmoMultiplier = 1.0

function PLAYER:SetupDataTables()
    self.Player:NetworkVar("Int", 0, "Level")
	self.Player:NetworkVar("Int", 1, "EXP")
	self.Player:NetworkVar("Int", 2, "EXPtoLevel")
	self.Player:NetworkVar("Int", 3, "SP")
	self.Player:NetworkVar("Float", 0, "AUX")
	self.Player:NetworkVar("Float", 1, "MaxAUX")
	self.Player:NetworkVar("Bool", 0, "Jetpacking")
	self.Player:NetworkVar("String", 0, "ActiveSuit")
	self.Player:NetworkVar("String", 1, "ActiveSuitName")
end

player_manager.RegisterClass("player_gmc", PLAYER, "player_default")