--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntitySetMesh = EntityMethods.SetMesh

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

local UpdateThread = function(self)
    WaitSeconds(0.1)
    ProjectileSetBallisticAcceleration(self, -0.5)

    local army = self.Army
    local fxTrails = self.FxTrails
    for i in fxTrails do
        CreateEmitterOnEntity(self, army, fxTrails[i])
    end

    WaitSeconds(0.2)
    EntitySetMesh(self, '/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
end

CAANanoDart01 = Class(CAANanoDartProjectile) {
   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        TrashAdd(self.Trash, ForkThread(UpdateThread, self))
   end,
}

TypeClass = CAANanoDart01
