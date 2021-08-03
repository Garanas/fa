--
-- Ship-based Anti-Torpedo Script
--
local ATorpedoSubProjectile = import('/lua/aeonprojectiles.lua').QuasarAntiTorpedoChargeSubProjectile

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetLifetime = ProjectileMethods.SetLifetime
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

AIMAntiTorpedo02 = Class(ATorpedoSubProjectile) 
{
    OnLostTarget = function(self)
       ------Slow this thing down and make it start moving downward.
        ProjectileSetBallisticAcceleration(self, -0.25)
        ProjectileSetBallisticAcceleration(self, 0,-9.5,0)
    end,
}

TypeClass = AIMAntiTorpedo02