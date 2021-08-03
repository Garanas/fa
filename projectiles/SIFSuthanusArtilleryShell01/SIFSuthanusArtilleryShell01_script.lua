------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFSuthanusArtilleryShell01/SIFSuthanusArtilleryShell01_script.lua
--  Author(s):  Gordon Duclos, Greg Kohne, Dru Staltman, Aaron Lundquist
--
--  Summary  :  Suthanus Artillery Shell Projectile script
--              Seraphim T3 Mobile Artillery : XSL0304
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local SSuthanusMobileArtilleryShell = import('/lua/seraphimprojectiles.lua').SSuthanusMobileArtilleryShell

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

-- attach for CTRL + SHIFT F replacement

SIFSuthanusArtilleryShell01 = Class(SSuthanusMobileArtilleryShell) {
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
            
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2.5, radius * 2.5, 200, 150, army)
        end
        
        ProjectileShakeCamera(self,  20, 1, 0, 1 )

        SSuthanusMobileArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = SIFSuthanusArtilleryShell01