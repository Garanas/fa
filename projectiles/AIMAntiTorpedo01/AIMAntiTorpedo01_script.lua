--
-- Ship-based Anti-Torpedo Script
--
local QuasarAntiTorpedoChargeSubProjectile = import('/lua/aeonprojectiles.lua').ATorpedoSubProjectile

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetLifetime = ProjectileMethods.SetLifetime

AIMAntiTorpedo01 = Class(QuasarAntiTorpedoChargeSubProjectile) {
    OnLostTarget = function(self)
        ProjectileSetAcceleration(self, -3.6)
        ProjectileSetLifetime(self, 0.5)
    end,
}

TypeClass = AIMAntiTorpedo01