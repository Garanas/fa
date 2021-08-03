--
-- Cybran laser 'bolt' : URB2301 : T2 cyb pd
--

local CHeavyLaserProjectile2 = import('/lua/cybranprojectiles.lua').CHeavyLaserProjectile2
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

CDFLaserHeavy02 = Class(CHeavyLaserProjectile2) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local damageData = self.DamageData
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        
        DamageArea( self, pos, 0.5, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, 0.5, 1, 'Force', FriendlyFire )

        damageData.DamageAmount = damageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' and targetType ~= 'Unit' then
            local army = self.Army
            local rotation = RandomFloat(0,2*3.141592)
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 0.5, 0.5, 70, 20, army)
        end

        CHeavyLaserProjectile2.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = CDFLaserHeavy02

