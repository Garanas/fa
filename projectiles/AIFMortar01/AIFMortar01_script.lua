--
-- Aeon T1 Artillery Mortar : ual0103
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local ALightMortarHit01 = import('/lua/EffectTemplates.lua').ALightMortarHit01
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

AIFMortar01 = Class(AArtilleryProjectile) {
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
            
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end
        
        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    FxImpactLand = ALightMortarHit01,
    FxImpactProp = ALightMortarHit01,
    FxImpactUnit = ALightMortarHit01,
}

TypeClass = AIFMortar01