AddCSLuaFile()
include("modules.lua")
function SetAUX(ply)
    ply:SetAUX(GetConVar("gmc_aux_base"):GetInt() + (MOD_AUX * ply:GetMod("auxamount")))
    ply:SetMaxAUX(GetConVar("gmc_aux_base"):GetInt() + (MOD_AUX * ply:GetMod("auxamount")))
end

timer.Create("AUXLogic", 0.1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local plyAUX = ply:GetAUX()
        local plyMaxAUX = ply:GetMaxAUX()
        if ply:IsSprinting() and ply:GetVelocity():LengthSqr() > 0 and not ply:GetJetpacking() and not ply.Cloaked then -- Drain AUX while sprinting
            plyAUX = math.max(0, plyAUX - 0.4) -- Ensure AUX doesn't go below 0
        end

        if plyAUX < plyMaxAUX and not (ply:IsSprinting() and ply:GetVelocity():LengthSqr() > 0) and not ply:GetJetpacking() and not ply.Cloaked then -- Regen AUX power over time
            plyAUX = math.min(plyMaxAUX, plyAUX + 0.2 + (MOD_AUXR * ply:GetMod("auxregen")))
        end

        if ply:GetJetpacking() then -- Drain AUX while using Jetpack
            local jetpackdrain = MOD_JETPACK - ply:GetMod("jetpack")
            plyAUX = math.max(0, plyAUX - (jetpackdrain - MOD_JETPACK_UP) * 0.1)
        end

        ply:SetAUX(plyAUX)
    end
end)

hook.Add("SetupMove", "SprintLimit", function(ply, mv, usrcmd)
    local plyWalkSpeed = ply:GetWalkSpeed()
    local plyRunSpeed = ply:GetRunSpeed()
    local plyAUX = ply:GetAUX() -- Get the current AUX power
    if plyAUX <= 0 then -- Disable Sprinting if AUX power goes below or equal to 0
        mv:SetMaxClientSpeed(plyWalkSpeed)
        usrcmd:RemoveKey(IN_SPEED)
        if ply:GetJetpacking() then
            ply:StopSound("gmc/jetpack.wav")
            ply:EmitSound("weapons/flame_thrower_bb_end.wav", 100, 100, 0.2)
            ply:SetJetpacking(false)
        end
    elseif plyAUX > 0 then
        mv:SetMaxClientSpeed(plyRunSpeed) -- Re-enable sprinting if the AUX goes over 1
        if ply:GetMod("jetpack") > 0 then -- Jetpack Functionality
            if ply:KeyPressed(IN_JUMP) and not ply:OnGround() and not ply:GetJetpacking() then 
				ply:SetJetpacking(true)
				print("Jetpack Active")
			end
            if usrcmd:KeyDown(IN_JUMP) and not ply:OnGround() and ply:GetJetpacking() then
                ply.flamesound = ply:StartLoopingSound("gmc/jetpack.wav")
                local jetpackdrain = MOD_JETPACK - ply:GetMod("jetpack")
                local newVelocity = mv:GetVelocity() + Vector(0, 0, 15) -- Apply the jetpack force over time
                local maxUpwardVelocity = 250 -- Cap the upward velocity to a maximum value
                if newVelocity.z > maxUpwardVelocity then newVelocity.z = maxUpwardVelocity end
                if plyAUX > jetpackdrain then mv:SetVelocity(newVelocity) end
            elseif (not usrcmd:KeyDown(IN_JUMP) and ply:GetJetpacking()) or (ply:OnGround() and ply:GetJetpacking()) then
                if ply.flamesound then 
					ply:StopLoopingSound(ply.flamesound)
				end
                ply:EmitSound("weapons/flame_thrower_bb_end.wav") 
                ply:SetJetpacking(false)
            end
        end
		if ply:GetMod("glide") > 0 and not ply:GetJetpacking() then
			if ply:KeyPressed(IN_DUCK) and not ply:OnGround() and not ply:GetGliding() then 
				ply:SetJetpacking(false)
			end
			if usrcmd:KeyDown(IN_DUCK) and not ply:OnGround() then
				local velocity = mv:GetVelocity()
				
				-- Target velocities
				local forwardDir = ply:GetForward()
				local targetForwardSpeed = ply:GetRunSpeed()
				local targetVerticalSpeed = MOD_GLIDE + (ply:GetMod("glide") * MOD_GLIDE_UP)

				-- Blend velocity towards target forward direction
				local currentForwardSpeed = velocity:Dot(forwardDir)
				local forwardVelocity = forwardDir * Lerp(0.05, currentForwardSpeed, targetForwardSpeed)

				-- Blend vertical speed toward downward cap
				local verticalVelocity = Vector(0, 0, Lerp(0.05, velocity.z, targetVerticalSpeed))

				-- Combine both
				local newVelocity = forwardVelocity + verticalVelocity

				mv:SetVelocity(newVelocity)
			end
		end
    end
end)