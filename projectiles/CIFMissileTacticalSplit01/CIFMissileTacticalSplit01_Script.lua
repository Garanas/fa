--
-- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
-- enemy anti-missile systems
--
local CLOATacticalChildMissileProjectile = import('/lua/cybranprojectiles.lua').CLOATacticalChildMissileProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetLifetime = ProjectileMethods.SetLifetime
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration
local ProjectileChangeMaxZigZag = ProjectileMethods.ChangeMaxZigZag
local ProjectileChangeZigZagFrequency = ProjectileMethods.ChangeZigZagFrequency
local ProjectileSetCollideSurface = ProjectileMethods.SetCollideSurface
local ProjectileSetCollision = ProjectileMethods.SetCollision

-- attach for CTRL + SHIFT F replacement

-- Give the projectile enough time to get out of the explosion
local DelayForDestruction = function(self)
    self.CanTakeDamage = false
    WaitSeconds(0.3)
    self.invincible = false
    self.CanTakeDamage = true
    ProjectileSetDestroyOnWater(self, true)
    ProjectileTrackTarget(self, true)
    ProjectileSetTurnRate(self, 80)
    ProjectileSetMaxSpeed(self, 15)--25
    ProjectileSetAcceleration(self, 6)--25
end

CIFMissileTacticalSplit01 = Class(CLOATacticalChildMissileProjectile) {

    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.5)
        self:SetDamage(25)
        self.invincible = true
        TrashAdd(self.Trash, ForkThread(DelayForDestruction, self))
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.invincible then
            CLOATacticalChildMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
        end
    end,
}
TypeClass = CIFMissileTacticalSplit01