--****************************************************************************
--**
--**  File     :  /data/projectiles/CANTorpedoNanite02/CANTorpedoNanite02_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Anti-Navy Nanite Torpedo Script
--                Nanite Torpedo releases tiny nanites that do DoT
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CTorpedoShipProjectile = import('/lua/cybranprojectiles.lua').CTorpedoShipProjectile

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileChangeMaxZigZag = ProjectileMethods.ChangeMaxZigZag
local ProjectileChangeZigZagFrequency = ProjectileMethods.ChangeZigZagFrequency
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition

-- attach for CTRL + SHIFT F replacement

local GetSquaredDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

local MovementThread = function(self)
    while not EntityBeenDestroyed(self) and (GetSquaredDistanceToTarget(self) > 64) do
        WaitSeconds(0.25)
    end  
    if not EntityBeenDestroyed(self) then
        ProjectileChangeMaxZigZag(self, 0)
        ProjectileChangeZigZagFrequency(self, 0)	      
    end
end

CANTorpedoNanite03 = Class(CTorpedoShipProjectile) {

    TrailDelay = 0,
    OnCreate = function(self, inWater)
        CTorpedoShipProjectile.OnCreate(self, inWater)
        ForkThread( MovementThread , self)
    end,    

    OnEnterWater = function(self)
        --CTorpedoShipProjectile.OnEnterWater(self)
        self.CreateImpactEffects( self, self.Army, self.FxEnterWater, self.FxSplashScale )
        ProjectileStayUnderwater(self, true)
        ProjectileTrackTarget(self, true)
        ProjectileSetTurnRate(self, 240)
    end,

}

TypeClass = CANTorpedoNanite03