--
-- script for projectile TankShell
--
local Projectile = import('/lua/sim/Projectile.lua').Projectile

-- globals as upvalues for performance 
local Random = Random
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local CreateSplat = CreateSplat
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter

-- attach for CTRL + SHIFT F replacement

local Thread = function(self)
    WaitTicks(5)
    while true do
        WaitTicks(Random(3,4))

        local pos = EntityGetPosition(self)
        MetaImpact(self, pos, 2, 2)

        local army = self.Army
        local fxMeta = self.FxMeta
        for k, v in fxMeta do
            local emit = CreateEmitterAtEntity(self, army, v):
            EmitterScaleEmitter(emit, 0.4)
        end

        ProjectileShakeCamera(self, 5, 1, 0, 0.1)
        CreateSplat(pos ,0,'scorch_001_albedo', 1, 1, 200, 500, army)
    end
end

ShellTankTerran01 = Class(Projectile) {
    FxUnitHitScale = 1,
    FxImpactUnit = {},
    FxLandHitScale = 1,
    FxImpactLand = {},
    FxWaterHitScale = 1,
    FxImpactWater = {},
    FxUnderWaterHitScale = 0.25,
    FxImpactUnderWater = {},
    FxAirUnitHitScale = 1,
    FxImpactAirUnit = {},
    FxNoneHitScale = 1,
    FxImpactNone = {},
    FxImpactLandScorch = false,
    FxImpactLandScorchScale = 1.0,

    FxMeta = {'/effects/emitters/quark_bomb_explosion_03_emit.bp',
                    '/effects/emitters/quark_bomb_explosion_04_emit.bp',
                    '/effects/emitters/quark_bomb_explosion_05_emit.bp',
                    '/effects/emitters/dust_cloud_02_emit.bp',
                    '/effects/emitters/dust_cloud_04_emit.bp',
                    '/effects/emitters/destruction_explosion_debris_04_emit.bp',
                    '/effects/emitters/destruction_explosion_debris_05_emit.bp',},

    OnCreate = function(self)
        Projectile.OnCreate(self)
        ForkThread(Thread, self)
    end,
}

TypeClass = ShellTankTerran01

