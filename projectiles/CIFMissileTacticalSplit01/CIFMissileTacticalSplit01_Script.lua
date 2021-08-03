--
-- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
-- enemy anti-missile systems
--
local CLOATacticalChildMissileProjectile = import('/lua/cybranprojectiles.lua').CLOATacticalChildMissileProjectile

CIFMissileTacticalSplit01 = Class(CLOATacticalChildMissileProjectile) {

    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.5)
        self:SetDamage(25)
        self.invincible = true
        ForkThread(self.DelayForDestruction, self)
    end,

    -- Give the projectile enough time to get out of the explosion
    DelayForDestruction = function(self)
        self.CanTakeDamage = false
        WaitSeconds(0.3)
        self.invincible = false
        self.CanTakeDamage = true
        ProjectileSetDestroyOnWater(self, true)
        ProjectileTrackTarget(self, true)
        ProjectileSetTurnRate(self, 80)
        ProjectileSetMaxSpeed(self, 15)--25
        ProjectileSetAcceleration(self, 6)--25
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.invincible then
            CLOATacticalChildMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
        end
    end,
}
TypeClass = CIFMissileTacticalSplit01