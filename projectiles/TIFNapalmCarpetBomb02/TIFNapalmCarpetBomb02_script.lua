-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/TIFNapalmCarpetBomb02/TIFNapalmCarpetBomb02_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  Heavy Napalm Bomb, DEA0202
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local TNapalmHvyCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmHvyCarpetBombProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local DamageRing = DamageRing
local CreateDecal = CreateDecal
local EntityCategoryContains = EntityCategoryContains

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

TIFNapalmCarpetBomb02 = Class(TNapalmHvyCarpetBombProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        data.DamageAmount = data.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*3.141592)
            local size = radius + RandomFloat(0.75,2.0)
            local army = self.Army

            DamageRing(self, pos, 0.1, 5/4 * radius, 10, 'Fire', FriendlyFire, false)
            data.DamageAmount = data.DamageAmount - 10
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 50, army)
        end
        
        TNapalmHvyCarpetBombProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFNapalmCarpetBomb02
