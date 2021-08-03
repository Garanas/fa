--
-- Depth Charge Script
--
local ADepthChargeProjectile = import('/lua/aeonprojectiles.lua').ADepthChargeProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetStayUpRight = ProjectileMethods.SetStayUpRight
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetVelocityAlign = ProjectileMethods.SetVelocityAlign

-- attach for CTRL + SHIFT F replacement

AANDepthCharge03 = Class(ADepthChargeProjectile) {

    CountdownLength = 10,
    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},


    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        ForkThread(self.CountdownExplosion, self)
    end,

    CountdownExplosion = function(self)
        WaitSeconds(self.CountdownLength)

        if not self.HasImpacted then
            self.OnImpact(self, 'Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        --ADepthChargeProjectile.OnEnterWater(self)

        for i in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self, self.Army, self.FxEnterWater[i])
        end

        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        ProjectileSetTurnRate(self, 360)
        ProjectileSetVelocityAlign(self, true)
        ProjectileSetStayUpRight(self, false)
    end,

    EnterWaterMovementThread = function(self)
        WaitTicks(1)
        ProjectileSetVelocity(self, 0.5)
    end,

    OnLostTarget = function(self)
        ProjectileSetMaxSpeed(self, 2)
        ProjectileSetAcceleration(self, -0.6)
        ForkThread(self.CountdownMovement, self)
    end,

    CountdownMovement = function(self)
        WaitSeconds(3)
        ProjectileSetMaxSpeed(self, 0)
        ProjectileSetAcceleration(self, 0)
        ProjectileSetVelocity(self, 0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        --LOG('Projectile impacted with: ' .. TargetType)
        self.HasImpacted = true
        local pos = EntityGetPosition(self)
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = 30,
            LifeTime = 10,
            Omni = false,
            Vision = false,
            Army = self.Army,
        }
        local vizEntity = VizMarker(spec)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}

TypeClass = AANDepthCharge03