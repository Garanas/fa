--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFQuanticCluster01/AIFQuanticCluster01_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Quantic Cluster Projectile script
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AQuantumCluster = import('/lua/aeonprojectiles.lua').AQuantumCluster
local TFragmentationSensorShellFrag = import('/lua/EffectTemplates.lua').TFragmentationSensorShellFrag
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile

-- attach for CTRL + SHIFT F replacement

local ChildProjectileBP = '/projectiles/AIFQuanticCluster02/AIFQuanticCluster03_proj.bp'

AIFQuanticCluster02 = Class(AQuantumCluster) {

    OnImpact = function(self, TargetType, TargetEntity)

        local army = self.Army
        local damageData = self.DamageData

        -- Split effects
        for k, v in TFragmentationSensorShellFrag do
            CreateEmitterAtEntity( self, army, v )
        end

        local vx, vy, vz = ProjectileGetVelocity(self)
        local velocity = 6

		-- One initial projectile following same directional path as the original
        local proj = ProjectileCreateChildProjectile(self, ChildProjectileBP)
        ProjectileSetVelocity(proj, vx, vy, vz)
        ProjectileSetVelocity(proj, velocity)
        proj.PassDamageData(proj, damageData)

		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = 8
        local angle = (2*3.141592) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )

        -- Randomization of the spread
        local angleVariation = angle * 0.35 -- Adjusts angle variance spread
        local spreadMul = 10 -- Adjusts the width of the dispersal

        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles -1) do
            xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            ProjectileSetVelocity(proj, xVec,yVec,zVec)
            ProjectileSetVelocity(proj, velocity)
            proj.PassDamageData(proj, damageData)
        end

        DestroyEntity(self)
    end,
}

TypeClass = AIFQuanticCluster01