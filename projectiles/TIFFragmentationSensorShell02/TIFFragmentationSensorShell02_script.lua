--
-- Terran T1 Artillery Fragmentation/Sensor Shells : uel0103
--

local TArtilleryProjectile = import('/lua/terranprojectiles.lua').TArtilleryProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

TIFFragmentationSensorShell02 = Class(TArtilleryProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        data.DamageAmount = data.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then

            local rotation = RandomFloat(0,2*3.141592)
            local army = self.Army
        
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end

        
        TArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
}

TypeClass = TIFFragmentationSensorShell02