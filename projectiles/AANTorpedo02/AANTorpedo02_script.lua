--
-- Aeon Torpedo Bomb
--
local ATorpedoShipProjectile = import('/lua/aeonprojectiles.lua').ATorpedoShipProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter

-- attach for CTRL + SHIFT F replacement

AANTorpedo02 = Class(ATorpedoShipProjectile) {
    
    FxSplashScale = 1,
    FxTrailScale = 0.75,
    FxEnterWater= { 
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },

    OnEnterWater = function(self)
        ATorpedoShipProjectile.OnEnterWater(self)
        local army = self.Army
        for k, v in self.FxEnterWater do --splash
            EmitterScaleEmitter(CreateEmitterAtEntity(self, army, v), self.FxSplashScale)
        end
    end,

    OnCreate = function(self, inWater)
        ATorpedoShipProjectile.OnCreate(self, inWater)
        ProjectileSetMaxSpeed(self, 8)
        ForkThread( self.MotionThread , self) 
    end,

    MotionThread = function(self)
        WaitSeconds( 0.3 )
        ProjectileSetTurnRate(self, 80)
        ProjectileSetMaxSpeed(self, 3)
        ProjectileSetVelocity(self, 3)
    end,
}

TypeClass = AANTorpedo02
