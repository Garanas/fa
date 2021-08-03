------------------------------------------------------------
--
--  File     :  /Projectiles/AIFMiasmaShell02/AIFMiasmaShell02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  : Damage shell that is spawned when it's parent shell 
--				detonates above ground. This projectile causes damage, 
--				and destroy trees. 
--              Aeon T2 Artillery : uab2303
--
--  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local AMiasmaProjectile02 = import('/lua/aeonprojectiles.lua').AMiasmaProjectile02
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local Damage = Damage
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

AIFMiasmaShell02 = Class(AMiasmaProjectile02) {
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
            local army = self.Army
            
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius+1, radius+1, 200, 100, army)
        end

        
        AMiasmaProjectile02.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = AIFMiasmaShell02