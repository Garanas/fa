--
-- UEF T2 Artillery projectile : ueb2303
--

local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryProjectilePolytrail = import('/lua/terranprojectiles.lua').TArtilleryProjectilePolytrail

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local EntityCategoryContains = EntityCategoryContains

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

-- attach for CTRL + SHIFT F replacement

TIFArtillery01 = Class(TArtilleryProjectilePolytrail) {
	FxImpactTrajectoryAligned = false,
    PolyTrail = '/effects/emitters/default_polytrail_04_emit.bp',
    FxImpactUnit = EffectTemplate.TAPDSHitUnit01,
    FxImpactLand = EffectTemplate.TAPDSHit01,
    
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
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius*2, radius*2, 200, 100, army)
        end
    
        TArtilleryProjectilePolytrail.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFArtillery01

