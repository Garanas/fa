--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile03 = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile03

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
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

local UpdateThread = function(self)
    WaitSeconds(0.35)
    ProjectileSetMaxSpeed(self, 2)
    ProjectileSetBallisticAcceleration(self, -0.5)

    local army = self.Army
    local FxTrails = self.FxTrails
    for i in FxTrails do
        CreateEmitterOnEntity(self, army, FxTrails[i])
    end

    WaitSeconds(0.5)
    EntitySetMesh(self, '/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
    ProjectileSetMaxSpeed(self, 60)
    ProjectileSetAcceleration(self, 16 + Random() * 5)

    WaitSeconds(0.3)
    ProjectileSetTurnRate(self, 360)
end

CAANanoDart01 = Class(CAANanoDartProjectile03) {
   OnCreate = function(self)
        CAANanoDartProjectile03.OnCreate(self)
        self.Trash:Add(ForkThread(UpdateThread, self))
   end,
}

TypeClass = CAANanoDart01
