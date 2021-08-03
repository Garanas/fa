--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFFragmentationSensorShell01/AIFFragmentationSensorShell01_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script,XAB2307
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local CreateEmitterAtBone = CreateEmitterAtBone

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile

-- attach for CTRL + SHIFT F replacement

AIFFragmentationSensorShell01 = Class(AArtilleryFragmentationSensorShellProjectile) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        local FxFragEffect = EffectTemplate.Aeon_QuanticClusterFrag01
        local bp = self.Blueprint.Physics
        
        -- Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtBone( self, -1, self.Army, v )
        end
        
        local vx, vy, vz = ProjectileGetVelocity(self)
        local velocity = 16

		-- One initial projectile following same directional path as the original
        local proj = ProjectileCreateChildProjectile(self, bp.FragmentId)
        ProjectileSetVelocity(proj, vx,0.8*vy, vz)
        ProjectileSetVelocity(velocity)
        proj.PassDamageData(proj, self.DamageData)
   		
		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bp.Fragments - 1
        local angle = (2 * 3.141592) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        
        -- Randomization of the spread
        local angleVariation = angle * 8 -- Adjusts angle variance spread
        local spreadMul = 0.8 -- Adjusts the width of the dispersal        
       
        local xVec = 0 
        local yVec = vy*0.8
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do
            xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul 
            local proj = ProjectileCreateChildProjectile(self, bp.FragmentId)
            ProjectileSetVelocity(proj, xVec,yVec,zVec)
            ProjectileSetVelocity(proj, velocity)
            proj.PassDamageData(proj, self.DamageData)                        
        end
        local pos = EntityGetPosition(self)
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = self.Data.Radius,
            LifeTime = self.Data.Lifetime,
            Army = self.Data.Army,
            Omni = false,
            WaterVision = false,
        }
        EntityDestroy(self)
    end,
}
TypeClass = AIFFragmentationSensorShell01