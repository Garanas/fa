
--****************************************************************************
--**
--**  File     :  /data/projectiles/CAANanoDart04/CAANanoDart04_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Cybran Anti Air Projectile, on unit DRA0202
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

CAANanoDartProjectile = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile02

-- globals as upvalues for performance 
local Random = Random
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntitySetMesh = EntityMethods.SetMesh

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

local UpdateThread = function(self)

    ProjectileSetMaxSpeed(self, 50)
    WaitSeconds(0.25)
    
    -- Accelerate the projectile forward (negative is forward for this one).
    ProjectileSetBallisticAcceleration(self, -0.5) 

    local army = self.Army
    local FxTrails = self.FxTrails
    for i in FxTrails do
        CreateEmitterOnEntity(self, army, FxTrails[i])
    end
       
    --Set the mesh for the unfolded-fins missile now.
    EntitySetMesh(self, '/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
    ProjectileSetAcceleration(self, 8 + Random() * 5)

    WaitSeconds(0.3)
    ProjectileSetTurnRate(self, 360)
end

CAANanoDart04 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        
        -- Set the orientation of this thing to facing the target from the beginning.
        local ourPos = EntityGetPosition(self)
        local targetPos = ProjectileGetCurrentTargetPosition(self)

        -- TODO: normalize the direction?
        local orientation = {targetPos[1]-ourPos[1],targetPos[2]-ourPos[2],targetPos[3]-ourPos[3]}         --Aim for the target.
        local velocity = {(orientation[1]*1.5),(orientation[2]*1.5)-40,(orientation[3]*1.5)}
        ProjectileSetVelocity(self, orientation[1],orientation[2]-40,orientation[3])
        
        ForkThread(UpdateThread, self)
   end,
}

TypeClass = CAANanoDart04
