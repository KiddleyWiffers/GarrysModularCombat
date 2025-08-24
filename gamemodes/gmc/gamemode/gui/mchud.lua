AddCSLuaFile()
include("gmc/gamemode/shared.lua")
include("gmc/gamemode/modules.lua")
include("mcmenu.lua")

activeCooldowns = {}
local function FindIcon(mod)
    for com, tab in pairs(modules) do
        if com == mod then return tab.Icon end
    end
end

function ClientSideCast(mod)
    if moduleCooldowns[mod] and activeCooldowns[mod] == nil and ModulesData[mod] > 0 and ModulesData[mod] != ModulesData["cloak"] then
        activeCooldowns[mod] = {
            startTime = CurTime(),
            duration = moduleCooldowns[mod],
            icon = FindIcon(mod)
        }
    end
	
	if ModulesData["cloak"] > 0 and mod == "cloak" and activeCooldowns["cloak"] == nil then
		if LocalPlayer().Cloaked then
			LocalPlayer().Cloaked = false
			activeCooldowns["cloak"] = {
				startTime = CurTime(),
				duration = moduleCooldowns["cloak"],
				icon = FindIcon("cloak")
			}
		elseif not LocalPlayer().Cloaked then
			LocalPlayer().Cloaked = true
		end
	end
	
	if ModulesData["crits"] > 0 and mod == "crits" then
		if LocalPlayer().CritsActive then
			LocalPlayer().CritsActive = false
		else
			LocalPlayer().CritsActive = true
		end
	end
	
	if ModulesData["teleport"] > 0 and mod == "teleport" and activeCooldowns["teleport"] == nil then
		LocalPlayer().Teleporting = true
	end
end

hook.Add("StartCommand", "CLIENTInputCooldowns", function(ply, cmd)
	if not IsValid(ply) then return end
	if cmd:KeyDown(IN_ATTACK) and ply.Teleporting and ply:GetAUX() >= MOD_TELEPORT_COST then
		ply.Teleporting = false
		activeCooldowns["teleport"] = {
			startTime = CurTime(),
			duration = MOD_TELEPORT_COOLDOWN,
			icon = FindIcon("teleport")
		}
	elseif cmd:KeyDown(IN_ATTACK2) and ply.Teleporting then
		ply.Teleporting = false
	end
end)

gameevent.Listen("player_hurt")
hook.Add("player_hurt", "RegenSupressDisplay", function(data)
	local target = data.userid
	if target == LocalPlayer():UserID() and GetConVar("gmc_regen_suppression"):GetInt() > 0 then
		activeCooldowns["RegenSuppress"] = {
			startTime = CurTime(),
			duration = GetConVar("gmc_regen_suppression"):GetInt(),
			icon = "vgui/gui/gmc/regensuppress"
		}
	end
end)

local function DrawCooldownHUD() -- Cooldown HUD Drawing Logic
    local xOffset = ScrW() - 80
    local yOffset = 20
    local boxWidth = 70
    local boxHeight = 70
    local spacing = 10
    for mod, data in pairs(activeCooldowns) do
        if activeCooldowns[mod] then
            local timeLeft = data.duration - (CurTime() - data.startTime)
            local modIcon = data.icon
            if timeLeft <= 0 then
                activeCooldowns[mod] = nil
            else
                draw.RoundedBox(5, xOffset, yOffset, boxWidth, boxHeight, Color(0, 0, 0, 80))
                draw.RoundedBox(5, xOffset, yOffset - (boxHeight / (data.duration / timeLeft)) + boxHeight, boxWidth, boxHeight / (data.duration / timeLeft), Color(255, 0, 0, 100))
                if modIcon then
                    surface.SetMaterial(Material(modIcon))
                    surface.SetDrawColor(230, 207, 40, 255)
                    surface.DrawTexturedRect(xOffset, yOffset, boxWidth, boxHeight)
                end

                xOffset = xOffset - (boxWidth + spacing)
            end
        end
    end
end
hook.Add("HUDPaint", "DrawCooldownHUD", DrawCooldownHUD)

function HUD()
    local client = LocalPlayer()
    if not client:Alive() then return end
    local pteam = client:Team()
    draw.RoundedBox(5, ScrW() / 192, ScrH() / 108, ScrW() / 6.4, ScrH() / 27, Color(0, 0, 0, 80))
    draw.RoundedBox(5, ScrW() / 192, ScrH() / 108, ScrW() / 6.4 / (client:GetEXPtoLevel() / client:GetEXP()), ScrH() / 27, Color(230, 207, 40, 255))
    draw.SimpleTextOutlined("Level: " .. client:GetLevel(), "HudSelectionText", ScrW() / 132, ScrH() / 51.4, Color(230, 207, 40, 255), nil, nil, 1, Color(0, 0, 0, 200))
    draw.SimpleTextOutlined("Exp: " .. client:GetEXP() .. "/" .. client:GetEXPtoLevel(), "HudSelectionText", ScrW() / 19.2, ScrH() / 51.4, Color(230, 207, 40, 200), nil, nil, 1, Color(0, 0, 0, 255))
    draw.RoundedBox(4, ScrW() / 56, ScrH() / 1.025, ScrW() / 8.3, 20, Color(0, 0, 0, 80))
    if client:GetAUX() >= client:GetMaxAUX() * 0.4 then draw.RoundedBox(4, ScrW() / 56, ScrH() / 1.025, (ScrW() / 8.3) / (client:GetMaxAUX() / client:GetAUX()), 20, Color(230, 207, 40, 200)) end
    if client:GetAUX() < client:GetMaxAUX() * 0.4 then draw.RoundedBox(4, ScrW() / 56, ScrH() / 1.025, (ScrW() / 8.3) / (client:GetMaxAUX() / client:GetAUX()), 20, Color(230, 0, 0, 150)) end
    draw.SimpleTextOutlined("AUX: " .. math.Round(client:GetAUX()), "HudSelectionText", ScrW() / 17.2, ScrH() / 1.023, Color(230, 207, 40, 255), nil, nil, 1, Color(0, 0, 0, 200))
    if team ~= TEAM_FFA and team ~= TEAM_COOP then
        surface.SetDrawColor(client:GetPlayerColor():ToColor())
        draw.NoTexture()
        local TC = team.GetColor(pteam)
        local textx = ScrW() / 35
        local texty = ScrH() / 1.08
        if pteam == TEAM_RED then
            draw.SimpleText("RED", "HudSelectionText", textx, texty, TC, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        elseif pteam == TEAM_BLUE then
            draw.SimpleText("BLUE", "HudSelectionText", textx, texty, TC, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        elseif pteam == TEAM_GREEN then
            draw.SimpleText("GREEN", "HudSelectionText", textx, texty, TC, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        elseif pteam == TEAM_PURPLE then
            draw.SimpleText("PURPLE", "HudSelectionText", textx, texty, TC, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
end
hook.Add("HUDPaint", "MCHUD", HUD)

hook.Add("PreDrawViewModel", "ViewmodelEffects", function(vm, ply, weapon)
	local hands = ply:GetHands()
	local function SetVMMat(mat)
		vm:SetMaterial(mat)
		hands:SetMaterial(mat)
	end
	if IsValid(vm) and IsValid(hands) then
		
		if ply:GetNWBool("FreezeActive", false) then
			SetVMMat("status/frozen")
		elseif ply.CritsActive then
			
		elseif ply.Cloaked then
			SetVMMat(MOD_CLOAK_MAT)
		else
			SetVMMat("")
		end
	end
end)