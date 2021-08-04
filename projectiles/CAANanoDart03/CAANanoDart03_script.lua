--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile

-- globals as upvalues for performance 
local Random = Random
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
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
    WaitSeconds(0.25)
    ProjectileSetMaxSpeed(self, 10)
    ProjectileSetBallisticAcceleration(self, -0.2)

    local army = self.Army
    local fxTrails = self.FxTrails
    for i in fxTrails do
        CreateEmitterOnEntity(self, army, fxTrails[i])
    end

    WaitSeconds(0.25)
    EntitySetMesh(self, '/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
    ProjectileSetMaxSpeed(self, 60)
    ProjectileSetAcceleration(self, 20 + Random() * 5)

    WaitSeconds(0.3)
    ProjectileSetTurnRate(self, 360)
end

CAANanoDart01 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        TrashAdd(self.Trash, ForkThread(UpdateThread, self))
   end,



}

TypeClass = CAANanoDart01
