--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile

-- globals as upvalues for performance 
local Random = Random
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntitySetMesh = EntityMethods.SetMesh

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

local UpdateThread = function(self)
    WaitSeconds(0.3)
    ProjectileSetMaxSpeed(self, 6)
    ProjectileSetBallisticAcceleration(self, -0.5)

    local army = self.Army
    local FxTrails = self.FxTrails
    for i in FxTrails do
        CreateEmitterOnEntity(self, army, FxTrails[i])
    end

    WaitSeconds(0.5)
    EntitySetMesh(self, '/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
    ProjectileSetMaxSpeed(self, 60)
    ProjectileSetAcceleration(self, 25 + Random() * 3)

    WaitSeconds(0.3)
    ProjectileSetTurnRate(self, 360)

end

CAANanoDart01 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        ForkThread(UpdateThread, self)
   end,
}

TypeClass = CAANanoDart01
