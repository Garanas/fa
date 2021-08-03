-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/SBOOtheTacticalBomb01/SBOOtheTacticalBomb01_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Othe Tactical Bomb script, XSA0103
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local SOtheTacticalBomb = import('/lua/seraphimprojectiles.lua').SOtheTacticalBomb
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

SBOOtheTacticalBomb01 = Class(SOtheTacticalBomb) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        data.DamageAmount = data.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            local rotation = RandomFloat(0,2*3.141592)
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius+1, radius+1, 150, 30, army)
        end
        
		SOtheTacticalBomb.OnImpact(self, targetType, targetEntity) 
    end,
}
TypeClass = SBOOtheTacticalBomb01