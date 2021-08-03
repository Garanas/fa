--
-- Aeon Very Fast Anti-Missile Missile
--
local AIMFlareProjectile = import('/lua/aeonprojectiles.lua').AIMFlareProjectile

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape

AIMAntiMissile01 = Class(AIMFlareProjectile) {
    OnCreate = function(self)
        AIMFlareProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 1.0)
    end,
}

TypeClass = AIMAntiMissile01

