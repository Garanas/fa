--
-- Terran Land-based torpedo
--

-- globals as upvalues for performance 
local CreateEmitterAtEntity = CreateEmitterAtEntity

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate

-- moho functions as upvalue for performance
local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

-- attach for CTRL + SHIFT F replacement

local TTorpedoShipProjectile = import('/lua/terranprojectiles.lua').TTorpedoShipProjectile
TorpedoShipTerran02 = Class(TTorpedoShipProjectile) {
    FxSplashScale = 1,

    -- copied from terran projectiles, TMissileCruiseSubProjectile
    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

    --OnCreate = function(self)
    --    TMissileCruiseSubProjectile.OnCreate(self)
    --    ProjectileSetScale(self, 0.6)
    --end

    OnEnterWater = function(self)
        TTorpedoShipProjectile.OnEnterWater(self)

        local army = self.Army
        local fxSplashScale = self.FxSplashScale
        local fxExitWaterEmitter = self.FxExitWaterEmitter
        for i in fxExitWaterEmitter do --splash
            local emit = CreateEmitterAtEntity(self, army, fxExitWaterEmitter[i])
            EmitterScaleEmitter(emit, fxSplashScale)
        end

        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        ProjectileSetTurnRate(self, 60)
        ProjectileSetMaxSpeed(self, 3)
        ProjectileSetVelocity(self, 3)
    end,
}

TypeClass = TorpedoShipTerran02

