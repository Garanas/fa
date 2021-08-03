-- Aeon Mortar

local ALaserBotProjectile = import('/lua/aeonprojectiles.lua').ALaserBotProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

TDFOverCharge01 = Class(ALaserBotProjectile, OverchargeProjectile) {

    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,

    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then

            local army = self.Army
            local radius = radius * 2
            CreateDecal(pos, RandomFloat(0,2 * 3.141592), 'crater_radial01_albedo', '', 'Albedo', radius, radius, 150, 40, army)
            CreateDecal(pos, RandomFloat(0,2 * 3.141592), 'crater_radial01_albedo', '', 'Albedo', radius, radius, 150, 40, army)
        end
        
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        ALaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    OnCreate = function(self)
        OverchargeProjectile.OnCreate(self)
        ALaserBotProjectile.OnCreate(self)
    end,
}

TypeClass = TDFOverCharge01
