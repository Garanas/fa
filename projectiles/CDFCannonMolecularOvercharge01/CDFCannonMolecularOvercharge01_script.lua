-- Cybran Molecular Cannon

local CMolecularCannonProjectile = import('/lua/cybranprojectiles.lua').CMolecularCannonProjectile
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile
local CCommanderOverchargeFxTrail01 = import('/lua/EffectTemplates.lua').CCommanderOverchargeFxTrail01
local CCommanderOverchargeHit01 = import('/lua/EffectTemplates.lua').CCommanderOverchargeHit01
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

CDFCannonMolecular01 = Class(CMolecularCannonProjectile, OverchargeProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = CCommanderOverchargeFxTrail01,

    -- Hit Effects
    FxImpactUnit = CCommanderOverchargeHit01,
    FxImpactProp = CCommanderOverchargeHit01,
    FxImpactLand = CCommanderOverchargeHit01,

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
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'crater_radial01_albedo', '', 'Albedo', radius * 2, radius * 2, 150, 40, army)
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'crater_radial01_albedo', '', 'Albedo', radius * 2, radius * 2, 150, 40, army)
        end
        
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        CMolecularCannonProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    OnCreate = function(self)
        OverchargeProjectile.OnCreate(self)
        CMolecularCannonProjectile.OnCreate(self)
    end,
}

TypeClass = CDFCannonMolecular01
