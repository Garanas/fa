------------------------------------------------------------
--
--  File     :  /data/projectiles/AIFFragmentationSensorShell03/AIFFragmentationSensorShell03_script.lua
--  Author(s):  Drew Staltman, Gordon Duclos
--
--  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script
--				 Child Projectile after 2st split
--              Aeon Salvation : XAB2307
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile03
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

-- attach for CTRL + SHIFT F replacement

AIFFragmentationSensorShell03 = Class(AArtilleryFragmentationSensorShellProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)
        local damageData = self.DamageData
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        damageData.DamageAmount = damageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*3.141592)
            local size = RandomFloat(2.25,3.75)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'scorch_004_albedo', '', 'Albedo', size, size, 200, 50, army)
        end
        
        ProjectileShakeCamera(self, 20, 1, 0, 1)
        
        AArtilleryFragmentationSensorShellProjectile.OnImpact( self, targetType, targetEntity )
    end,	
}
TypeClass = AIFFragmentationSensorShell03