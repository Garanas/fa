--
-- Cybran Non-guided Torpedo, Made to be fired from above the water
--
local CTorpedoShipProjectile = import('/lua/cybranprojectiles.lua').CTorpedoShipProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter

-- attach for CTRL + SHIFT F replacement

local SpinUpThread = function(self)
    WaitSeconds(2)
    ProjectileTrackTarget(self, false)
    ProjectileSetTurnRate(self, 0)
end

CANTorpedoMeson01 = Class(CTorpedoShipProjectile) {
    
    FxSplashScale = 1,
    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

    OnEnterWater = function(self)
        CTorpedoShipProjectile.OnEnterWater(self)
        
        local army = self.Army
        local fxExitWaterEmitter = self.FxExitWaterEmitter
        local fxSplashScale = self.FxSplashScale
        for i in fxExitWaterEmitter do -- splash
            local emit = CreateEmitterAtEntity(self, army, fxExitWaterEmitter[i])
            EmitterScaleEmitter(emit, fxSplashScale)
        end

        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        ProjectileSetBallisticAcceleration(self, 0)
        ProjectileSetTurnRate(self, 120)
        ProjectileSetMaxSpeed(self, 18)
        ProjectileSetVelocity(self, 3)
        TrashAdd(self.Trash, ForkThread(SpinUpThread, self))
    end,
}

TypeClass = CANTorpedoMeson01
