------------------------------------------------------------------
--
--  File     :  /effects/projectiles/TDFPlasmsaHeavy02/TDFPlasmsaHeavy02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  UEF Heavy Plasma Cannon projectile, UEA0305 : T3 uef gunship & XEA0306 : T3 transport
--
--  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local THeavyPlasmaCannonProjectile = import('/lua/terranprojectiles.lua').THeavyPlasmaCannonProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local EntityCategoryContains = EntityCategoryContains

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

TDFPlasmaHeavy02 = Class(THeavyPlasmaCannonProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition02,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, 0.5, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, 0.5, 1, 'Force', FriendlyFire )

        data.DamageAmount = data.DamageAmount - 2
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' and targetType ~= 'Unit' then
            local rotation = RandomFloat(0,2*3.141592)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 0.5, 0.5, 50, 15, army)
        end
        
        THeavyPlasmaCannonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TDFPlasmaHeavy02

