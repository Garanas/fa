--
-- Cybran Scathis Projectile : url0401
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

-- attach for CTRL + SHIFT F replacement

CIFArtilleryProton03 = Class(CArtilleryProtonProjectile) {
    FxLandHitScale = 1.6,
    FxPropHitScale = 1.6,
    FxUnitHitScale = 1.6,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local damageData = self.Damagedata
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        damageData.DamageAmount = damageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            CreateDecal( pos, RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', radius * 2, radius * 2, 250, 200, army )
        end
        
        ProjectileShakeCamera(self,  20, 3, 0, 1 )
        
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = CIFArtilleryProton03