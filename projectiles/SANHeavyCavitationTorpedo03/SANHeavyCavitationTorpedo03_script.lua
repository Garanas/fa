--****************************************************************************
--**
--**  File     :  /data/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SHeavyCavitationTorpedo = import('/lua/seraphimprojectiles.lua').SHeavyCavitationTorpedo
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local SHeavyCavitationTorpedoFxTrails = import('/lua/EffectTemplates.lua').SHeavyCavitationTorpedoFxTrails

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition

local GetSquaredDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

local PauseUntilTrack = function(self)
    local turnrate = 360
    if GetSquaredDistanceToTarget(self) < 36 then
        turnrate = 720
    end
    
    WaitSeconds(0.1)
    ProjectileSetMaxSpeed(self, 20)
    ProjectileTrackTarget(self, true)
    ProjectileSetTurnRate(self, turnrate)
end

SANHeavyCavitationTorpedo03 = Class(SHeavyCavitationTorpedo) {
    OnCreate = function(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 0.1)
        SHeavyCavitationTorpedo.OnCreate(self)
        TrashAdd(self.Trash, ForkThread(PauseUntilTrack, self))
        CreateEmitterOnEntity(self, self.Army, SHeavyCavitationTorpedoFxTrails)
    end,


}
TypeClass = SANHeavyCavitationTorpedo03
