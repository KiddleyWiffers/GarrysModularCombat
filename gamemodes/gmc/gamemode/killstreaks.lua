AddCSLuaFile()

KS_EXP_MULT = 0.1
MKS_EXP_MULT = 0.2
KS_EXP_MAX = 0.8
KS_DOM_MULT = 0.1
KS_BOUNTY = 0.5
DOM_BOUNTY = 0.5

killstreakTiers = {
    [5] = {message = "on a Killstreak.", sound = "sound/gmc/killstreak/killstreak1.wav", client = true},
    [10] = {message = "Bloodthirsty!", sound = "sound/gmc/killstreak/killstreak2.wav", client = true},
    [15] = {message = "on a Rampage!", sound = "sound/gmc/killstreak/killstreak3.wav"},
    [20] = {message = "Merciless!", sound = "sound/gmc/killstreak/killstreak4.wav"},
    [25] = {message = "Unstoppable!", sound = "sound/gmc/killstreak/killstreak5.wav"},
    [30] = {message = "God-like!", sound = "sound/gmc/killstreak/killstreak6.wav"}
}

dominationTiers = {
    [5] = {message = "Dominating", sound = "sound/gmc/killstreak/domination1.wav", material = "vgui/gui/gmc/domination1"},
    [10] = {message = "Conquering", sound = "sound/gmc/killstreak/domination2.wav", material = "vgui/gui/gmc/domination2"},
    [15] = {message = "Slaughtering", sound = "sound/gmc/killstreak/domination3.wav", material = "vgui/gui/gmc/domination3"},
    [20] = {message = "Tormenting", sound = "sound/gmc/killstreak/domination4.wav", material = "vgui/gui/gmc/domination4"}
}

if SERVER then
    killstreaks = {}
    dominations = {}
    ksmultiplier = {}
    dommultiplier = {}
    ksbounty = {}
    dombounty = {}
    totalmult = {}
	
	function KillstreakLogic(victim, attacker)
		if victim:IsPlayer() and victim != attacker then
			killstreaks[victim] = 0
			ksmultiplier[victim] = 0
			if dominations[victim] and dominations[victim][attacker] then
				dominations[victim][attacker] = 0
				dommultiplier[victim] = 0
			end

			if attacker:IsPlayer() then
				-- Initialize Killstreaks and Dominations
				killstreaks[attacker] = (killstreaks[attacker] or 0) + 1
				dominations[attacker] = dominations[attacker] or {}
				dominations[attacker][victim] = (dominations[attacker][victim] or 0) + 1
				-- Initalize Multipliers
				ksmultiplier[attacker] = ksmultiplier[attacker] or 0
				dommultiplier[attacker] = dommultiplier[attacker] or 0
				-- Initialize Attacker Bounties
				ksbounty[attacker] = ksbounty[victim] or 0
				dombounty[attacker] = dombounty[attacker] or {}
				dombounty[attacker][victim] = dombounty[attacker][victim] or 0
				-- Initialize Victim Bounties
				ksbounty[victim] = ksbounty[victim] or 0
				dombounty[victim] = dombounty[victim] or {}
				dombounty[victim][attacker] = dombounty[victim][attacker] or 0
				-- Killstreak logic
				for tier, tierData in pairs(killstreakTiers) do
					if killstreaks[attacker] == tier then
						PrintMessage(HUD_PRINTCENTER, attacker:Nick() .. " is " .. tierData.message)
						ksmultiplier[attacker] = ksmultiplier[attacker] + KS_EXP_MULT
						ksbounty[attacker] = (ksbounty[attacker] or 0) + KS_BOUNTY
						if tierData.sound ~= "" and not tierData.client then EmitSound(tierData.sound, Vector(0, 0, 0), 0, CHAN_STATIC, 1, 10000) end
					end
				end

				if killstreaks[attacker] > 30 and killstreaks[attacker] % 10 == 0 then
					PrintMessage(HUD_PRINTCENTER, attacker:Nick() .. " is Beyond Godlike!(" .. killstreaks[attacker] .. " kills)")
					EmitSound("sound/gmc/killstreak/killstreak7.wav", Vector(0, 0, 0), 0, CHAN_STATIC, 1, 10000)
					if ksmultiplier[attacker] < KS_EXP_MAX then
						ksmultiplier[attacker] = ksmultiplier[attacker] + MKS_EXP_MULT
						ksbounty[attacker] = ksbounty[attacker] + (KS_BOUNTY * 2)
					end
				end
				-- Domination logic
				for tier, tierData in pairs(dominationTiers) do
					if dominations[attacker][victim] == tier then
						attacker:PrintMessage(HUD_PRINTCENTER, "You are " .. tierData.message .. " " .. victim:Nick() .. "!")
						victim:PrintMessage(HUD_PRINTCENTER, attacker:Nick() .. " is " .. tierData.message .. " you!")
						dombounty[victim][attacker] = dombounty[victim][attacker] + DOM_BOUNTY
						if tier == 5 then dommultiplier[attacker] = dommultiplier[attacker] + KS_DOM_MULT end
					end
				end

				totalmult[attacker] = (dommultiplier[attacker] + ksmultiplier[attacker]) + (ksbounty[victim] + dombounty[attacker][victim])
				dombounty[attacker][victim] = 0
				ksbounty[victim] = 0
			end
		end
	end
end

if CLIENT then
    killstreak = 0
    doms = {}
    highestTierData = {}
    local ksicon = Material("vgui/gui/gmc/killstreak")
    hook.Add("HUDPaint", "DrawKillstreakHUD", function()
        local ply = LocalPlayer()
        if killstreak >= 5 then
            local xOffset, yOffset = ScrW() - 140, ScrH() - 160
            local boxWidth, boxHeight = 100, 50
            draw.RoundedBox(5, xOffset, yOffset, boxWidth, boxHeight, Color(0, 0, 0, 80)) -- Background box
            surface.SetMaterial(ksicon)
            surface.DrawTexturedRect(xOffset, yOffset, boxWidth / 2, boxHeight)
            draw.SimpleText(killstreak, "GMCTitleFont", xOffset + boxWidth / 1.4, yOffset + boxHeight / 2, Color(230, 207, 40, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) -- Text to display kills
        end
    end)

    hook.Add("PostDrawTranslucentRenderables", "DrawDominationIcons", function()
        local ply = LocalPlayer() -- Render domination icons above dominating players
        for attacker, domLevel in pairs(doms) do
            if IsValid(attacker) and domLevel > 0 then
                for tier, tierData in pairs(dominationTiers) do
                    if domLevel == tier then highestTierData[attacker] = tierData end
                end

                if highestTierData[attacker] and highestTierData[attacker].material then
                    local material = Material(highestTierData[attacker].material)
                    local headPos = attacker:GetPos() + Vector(0, 0, 90) -- Position above the player's head
                    render.SetMaterial(material)
                    render.DrawSprite(headPos, 16, 16, color_white) -- Adjust sprite size as needed
                end
            end
        end
    end)
end

gameevent.Listen("entity_killed")
hook.Add("entity_killed", "KillstreakAndDominationCounter", function(data)
	if data.entindex_attacker then
		local attacker = Entity(data.entindex_attacker)
		local victim = Entity(data.entindex_killed)
	end
    if CLIENT then
        if attacker == LocalPlayer() and victim:IsPlayer() and attacker != victim then
            killstreak = math.Clamp(killstreak + 1, 0, 99)
            doms[victim] = 0
            highestTierData[victim] = nil
        elseif victim == LocalPlayer() and attacker != LocalPlayer() then
            doms[attacker] = (doms[attacker] or 0) + 1
            killstreak = 0
            for tier, tierData in pairs(dominationTiers) do
                if doms[attacker] == tier then
                    victim:PrintMessage(HUD_PRINTCENTER, attacker:Nick() .. " is " .. tierData.message .. " you!")
                    surface.PlaySound(tierData.sound)
                end
            end
        end
    end
end)