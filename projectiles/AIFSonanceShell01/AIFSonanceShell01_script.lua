--
-- Aeon T3 Mobile Artillery Projectile : ual0304
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local ASonanceWeaponHit02 = import('/lua/EffectTemplates.lua').ASonanceWeaponHit02
local ASonanceWeaponFXTrail01 = import('/lua/EffectTemplates.lua').ASonanceWeaponFXTrail01

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

-- attach for CTRL + SHIFT F replacement

AIFSonanceShell01 = Class(AArtilleryProjectile) {

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
            
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius+2, radius+2, 200, 150, army)
        end
        
        ProjectileShakeCamera(self,  20, 1, 0, 1 )

        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    PolyTrail = '/effects/emitters/aeon_sonicgun_trail_emit.bp',
    
    FxTrails = ASonanceWeaponFXTrail01,
    
    FxImpactUnit =  ASonanceWeaponHit02,
    FxImpactProp =  ASonanceWeaponHit02,
    FxImpactLand =  ASonanceWeaponHit02,
}

TypeClass = AIFSonanceShell01