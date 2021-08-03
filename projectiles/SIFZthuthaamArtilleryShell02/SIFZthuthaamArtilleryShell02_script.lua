------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFZthuthaamArtilleryShell02/SIFZthuthaamArtilleryShell02_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Zthuthaam Artillery Shell Projectile script
--              Seraphim T2 Artillery XSB2303
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local SZthuthaamArtilleryShell = import('/lua/seraphimprojectiles.lua').SZthuthaamArtilleryShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

SIFZthuthaamArtilleryShell02 = Class(SZthuthaamArtilleryShell) {
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
            
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2, radius * 2, 200, 100, army)
        end
        
        SZthuthaamArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SIFZthuthaamArtilleryShell02