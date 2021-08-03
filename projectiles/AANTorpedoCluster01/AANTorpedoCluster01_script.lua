--****************************************************************************
--**
--**  File     :  /data/projectiles/AANTorpedoCluster01/AANTorpedoCluster01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Aeon Torpedo Cluster Projectile script, XAA0306
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ATorpedoCluster = import('/lua/aeonprojectiles.lua').ATorpedoCluster
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local ATorpedoPolyTrails = import('/lua/EffectTemplates.lua').ATorpedoPolyTrails01

-- globals as upvalues for performance 
local CreateTrail = CreateTrail

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater

-- attach for CTRL + SHIFT F replacement

local ChildProjectileBP = '/projectiles/AANTorpedoClusterSplit01/AANTorpedoClusterSplit01_proj.bp'  

AANTorpedoCluster01 = Class(ATorpedoCluster) {

    FxEnterWater= { 
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },

    OnCreate = function(self)
        ATorpedoCluster.OnCreate(self)
        self.HasImpacted = false

		CreateTrail(self, -1, self.Army, ATorpedoPolyTrails)
    end,

    OnEnterWater = function(self) 

        ProjectileStayUnderwater(self, true)

        proj = self:CreateChildProjectile(ChildProjectileBP)
        proj.PassDamageData(proj, self.DamageData)
        
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
        ATorpedoCluster.OnEnterWater(self)
        EntityDestroy(self)
    end,
    
    OnImpact = function(self, TargetType, TargetEntity)
        if (TargetEntity == nil) and (TargetType == "Air") then
            return
        end
        ATorpedoCluster.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = AANTorpedoCluster01