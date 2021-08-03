--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFLaanseTacticalMissile01/SIFLaanseTacticalMissile01_script.lua
--**  Author(s):  Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Laanse Tactical Missile Projectile script, XSL0111
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SLaanseTacticalMissile = import('/lua/seraphimprojectiles.lua').SLaanseTacticalMissile

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition

-- attach for CTRL + SHIFT F replacement

local GetSquaredDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

local SetTurnRateByDist = function(self)
    local dist = GetSquaredDistanceToTarget(self)
    if dist > self.Distance then
        ProjectileSetTurnRate(self, 75)
        WaitSeconds(3)
        ProjectileSetTurnRate(self, 8)
        self.Distance = GetSquaredDistanceToTarget(self)
    end

    if dist > 50 * 50 then        
        --Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 10)
    elseif dist > 30 * 30 and dist <= 50 * 50 then
        ProjectileSetTurnRate(self, 12)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 12)
    elseif dist > 10 * 10 and dist <= 25 * 25 then
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 10 * 10 then           
        ProjectileSetTurnRate(self, 100)   
        KillThread(self.MoveThread)         
    end
end

local MovementThread = function(self)   
    
    local waitTime = 0.1
    local previousDistance = GetSquaredDistanceToTarget(self)
    ProjectileSetTurnRate(self, 8)
    WaitSeconds(0.3)        
    while not EntityBeenDestroyed(self) do
        SetTurnRateByDist(self)
        WaitSeconds(waitTime)
    end
end

SIFLaanseTacticalMissile01 = Class(SLaanseTacticalMissile) {
    
    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2)
        self.MoveThread = ForkThread(MovementThread, self)
    end,

}
TypeClass = SIFLaanseTacticalMissile01

