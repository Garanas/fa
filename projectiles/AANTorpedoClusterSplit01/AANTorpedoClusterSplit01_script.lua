--****************************************************************************
--**
--**  File     :  /data/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local ATorpedoCluster = import('/lua/aeonprojectiles.lua').ATorpedoCluster
local ATorpedoPolyTrails = import('/lua/EffectTemplates.lua').ATorpedoPolyTrails01

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateTrail = CreateTrail
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetStayUpRight = ProjectileMethods.SetStayUpright
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget

-- attach for CTRL + SHIFT F replacement

AANTorpedoCluster01 = Class(ATorpedoCluster) {

    CountdownLength = 10,
    FxEnterWater = { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
        self.HasImpacted = false

        ForkThread(self.CountdownExplosion, self)
		CreateTrail(self, -1, self.Army, ATorpedoPolyTrails)
    end,

    CountdownExplosion = function(self)
        WaitSeconds(self.CountdownLength)

        if not self.HasImpacted then
            self.OnImpact(self, 'Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        ATorpedoCluster.OnEnterWater(self)
        local army = self.Army
        for i in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self,army,self.FxEnterWater[i])
        end
        ForkThread(self.EnterWaterMovementThread, self)
    end,
    
    EnterWaterMovementThread = function(self)
        ProjectileSetAcceleration(self, 2.5)
        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        ProjectileSetTurnRate(self, 180)
        ProjectileSetStayUpRight(self, false)
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
        ATorpedoCluster.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANTorpedoCluster01