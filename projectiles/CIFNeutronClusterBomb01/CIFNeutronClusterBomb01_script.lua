-------------------------------------------------------------------------------
--
--  File     :  /projectiles/CIFNeutronClusterBomb01/CIFNeutronClusterBomb01.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  Cybran Neutron Cluster bomb
--
--  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local CNeutronClusterBombProjectile = import('/lua/cybranprojectiles.lua').CNeutronClusterBombProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

CIFNeutronClusterBomb01 = Class(CNeutronClusterBombProjectile) {
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
            local size = radius-1.5 + RandomFloat(0,1.0)
            local army = self.Army

            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 30, army)
        end
        
        CNeutronClusterBombProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = CIFNeutronClusterBomb01
