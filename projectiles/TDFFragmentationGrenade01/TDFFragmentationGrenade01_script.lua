------------------------------------------------------------
--
--  File     :  /data/projectiles/TDFFragmentationGrenade01/TDFFragmentationGrenade01_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  UEF Fragmentation Shells, DEL0204 : mongoose
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TFragmentationGrenade = import('/lua/terranprojectiles.lua').TFragmentationGrenade
local EmitterProjectile = import('/lua/sim/defaultprojectiles.lua').EmitterProjectile

-- globals as upvalues for performance 
local DamageArea = DamageArea
local DamageRing = DamageRing
local CreateDecal = CreateDecal
local EntityCategoryContains = EntityCategoryContains

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

TDFFragmentationGrenade01 = Class(TFragmentationGrenade) {
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
            local army = self.Army

            DamageRing( self, pos, radius, 5/4 * radius, 1, 'Fire', FriendlyFire )
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius+1, radius+1, 85, 30, army)
        end
        
        EmitterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TDFFragmentationGrenade01