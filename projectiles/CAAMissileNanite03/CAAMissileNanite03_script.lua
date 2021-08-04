--
-- AA Missile for Cybrans
--
local CAAMissileNaniteProjectile = import('/lua/cybranprojectiles.lua').CAAMissileNaniteProjectile03

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local Random = Random

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileChangeMaxZigZag = ProjectileMethods.ChangeMaxZigZag
local ProjectileChangeZigZagFrequency = ProjectileMethods.ChangeZigZagFrequency

-- attach for CTRL + SHIFT F replacement

local UpdateThread = function(self)
    WaitSeconds(1.5)
    ProjectileSetMaxSpeed(self, 80)
    ProjectileSetAcceleration(self, 10 + Random() * 8)
    ProjectileChangeMaxZigZag(self, 0.5)
    ProjectileChangeZigZagFrequency(self, 2)
end

CAAMissileNanite03 = Class(CAAMissileNaniteProjectile) {
    OnCreate = function(self)
        CAAMissileNaniteProjectile.OnCreate(self)
        TrashAdd(self.Trash, ForkThread(UpdateThread, self))
    end,
}

TypeClass = CAAMissileNanite03

