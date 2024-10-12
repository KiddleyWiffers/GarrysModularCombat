AddCSLuaFile()

SWEP.PrintName = "GMC Projectile Launcher"
SWEP.Author = "Kiddley"
SWEP.Purpose = "Launch various projectiles"
SWEP.Instructions = "Left click to fire, reload to cycle through projectiles."
SWEP.Category = "Garry's Modular Combat"

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Base = "weapon_base"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1 -- 1 second fire rate

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- Set up the view model and world model
SWEP.ViewModel = "models/weapons/v_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"

SWEP.SENTs = {
    "gmc_acid_grenade",
    "gmc_fire_grenade",
    "gmc_ice_grenade",
    "gmc_energy_ball",
    "gmc_poisondart"
}

SWEP.CurrentSENTIndex = 1

-- Initialize the weapon
function SWEP:Initialize()
    self:SetHoldType("rpg") -- Set hold type to grenade
end

-- Function to fire the selected SENT
function SWEP:PrimaryAttack()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local forward = owner:GetAimVector()
    local pos = owner:GetShootPos() + forward * 32 -- Spawn slightly in front of the player

    local entClass = self.SENTs[self.CurrentSENTIndex]
    local sent = ents.Create(entClass)
    
    if IsValid(sent) then
        sent:SetPos(pos)
		sent:SetAngles(owner:EyeAngles())
        sent:SetOwner(owner)
        sent:Spawn()

        local phys = sent:GetPhysicsObject()
        if IsValid(phys) then
            phys:ApplyForceCenter(forward * 1000) -- Apply a forward force to the SENT
        end
    end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay) -- Set the fire rate
end

-- Function to cycle through the SENTs on reload
function SWEP:Reload()
    if self:GetNextPrimaryFire() > CurTime() then return end -- Prevent reloading if recently fired

    self.CurrentSENTIndex = self.CurrentSENTIndex + 1
    if self.CurrentSENTIndex > #self.SENTs then
        self.CurrentSENTIndex = 1
    end

    self:EmitSound("weapons/smg1/switch_single.wav")

    self:SetNextPrimaryFire(CurTime() + 0.2)
end

function SWEP:GetCurrentSENTName()
    local entClass = self.SENTs[self.CurrentSENTIndex]
    local sent = scripted_ents.GetStored(entClass)

    if sent and sent.t and sent.t.PrintName then
        return sent.t.PrintName
    else
        return entClass -- Fallback to class name if PrintName is not found
    end
end


if CLIENT then
    function SWEP:DrawHUD()
        local w, h = ScrW(), ScrH()
        local boxWidth, boxHeight = 300, 50

        local x = w - boxWidth - 20
        local y = h - boxHeight - 20

        -- Draw a semi-transparent box
        surface.SetDrawColor(10, 10, 10, 200)
        surface.DrawRect(x, y, boxWidth, boxHeight)

        -- Draw an outline
        surface.SetDrawColor(255, 220, 0, 255)
        surface.DrawOutlinedRect(x, y, boxWidth, boxHeight)

        -- Draw the current SENT name
		local sentName = self:GetCurrentSENTName()
        draw.SimpleText(
            "Selected: " .. sentName,
            "Trebuchet24",
            x + 10,
            y + 10,
            Color(255, 220, 0, 255),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP
        )
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    return true
end