--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFLaanseTacticalMissile03/SIFLaanseTacticalMissile03_script.lua
--**  Author(s):  Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Laanse Tactical Missile Projectile script, XSS0303
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SLaanseTacticalMissile = import('/lua/seraphimprojectiles.lua').SLaanseTacticalMissile

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
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
    --Get the nuke as close to 90 deg as possible
    if dist > 50 * 50 then        
        --Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 20)
    elseif dist > 64 * 64 and dist <= 107 * 107 then
        -- Increase check intervals
        ProjectileSetTurnRate(self, 30)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 30)
    elseif dist > 21 * 21 and dist <= 53 * 53 then
        -- Further increase check intervals
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 21 * 21 then
        -- Further increase check intervals            
        ProjectileSetTurnRate(self, 100)   
        KillThread(self.MoveThread)         
    end
end

local MovementThread = function(self)        
    local waitTime = 0.1
    ProjectileSetTurnRate(self, 8)
    WaitSeconds(0.3)        
    while not EntityBeenDestroyed(self) do
        SetTurnRateByDist(self)
        WaitSeconds(waitTime)
    end
end

SIFLaanseTacticalMissile03 = Class(SLaanseTacticalMissile) {
    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        TrashAdd(self.Trash, ForkThread( MovementThread , self))
    end,       
}
TypeClass = SIFLaanseTacticalMissile03

