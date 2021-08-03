--
-- Cybran T1 Artillery EMP Grenade : url0103
--
local CArtilleryProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CEMPGrenadeHit01 = import('/lua/EffectTemplates.lua').CEMPGrenadeHit01

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

CIFGrenade01 = Class(CArtilleryProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local damageData = self.DamageData
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        damageData.DamageAmount = damageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            local rotation = RandomFloat(0,2*3.141592)
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end

        CArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    FxImpactUnit = CEMPGrenadeHit01,
    FxImpactProp = CEMPGrenadeHit01,
    FxImpactLand = CEMPGrenadeHit01,
}

TypeClass = CIFGrenade01