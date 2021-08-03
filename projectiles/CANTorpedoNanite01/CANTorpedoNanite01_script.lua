--
-- Sub-Based Torpedo Script
--
local CTorpedoSubProjectile = import('/lua/cybranprojectiles.lua').CTorpedoSubProjectile

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

CANTorpedoNanite01 = Class(CTorpedoSubProjectile) {

	OnCreate = function(self, inWater)
        CTorpedoSubProjectile.OnCreate(self, inWater)
        if inWater then
            ProjectileSetBallisticAcceleration(self, 0)
        else
            ProjectileSetBallisticAcceleration(self, -20)
            ProjectileTrackTarget(self, false)
            ProjectileSetTurnRate(self, 0)
        end
    end,
    
    OnEnterWater = function(self)
        CTorpedoSubProjectile.OnEnterWater(self)
        ProjectileSetBallisticAcceleration(self, 0)
        ProjectileSetTurnRate(self, 120)
        ProjectileTrackTarget(self, true)
    end,
}

TypeClass = CANTorpedoNanite01