-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  Aeon Guided Split Missile, DAA0206
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local AGuidedMissileProjectile = import('/lua/aeonprojectiles.lua').AGuidedMissileProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local DefaultExplosion = import('/lua/defaultexplosions.lua')

-- globals as upvalues for performance 
local DamageArea = DamageArea
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileTrackTarget = ProjectileMethods.TrackTarget

-- attach for CTRL + SHIFT F replacement

AIFGuidedMissile02 = Class(AGuidedMissileProjectile) {
	-- FxTrailScale = 0.5,

    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
		ForkThread(self.MovementThread , self)
    end,
    
	MovementThread = function(self)
		WaitSeconds(0.6)
		ProjectileTrackTarget(self, true)
	end,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*3.141592)
            local army = self.Army

            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius*3, radius*3, 200, 70, army)
        end
        
        AGuidedMissileProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = AIFGuidedMissile02

