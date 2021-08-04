--
-- Cybran T2 Artillery Projectile : urb2303
--

local CIFMolecularResonanceShell = import('/lua/cybranprojectiles.lua').CIFMolecularResonanceShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

CIFMolecularResonanceShell01 = Class(CIFMolecularResonanceShell) {
	OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local pos = EntityGetPosition(self)

        local damageData = self.DamageData
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        damageData.DamageAmount = damageData.DamageAmount - 2
        
        CreateLightParticle( self, -1, army, 24, 5, 'glow_03', 'ramp_red_10' )
        CreateLightParticle( self, -1, army, 8, 16, 'glow_03', 'ramp_antimatter_02' )
		
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*3.141592)
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2, radius * 2, 200, 100, army)
        end
        
		CIFMolecularResonanceShell.OnImpact(self, targetType, targetEntity)  
	end,
	
    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
        if EffectTable then 
            EffectScale = EffectScale or 1
            for k, v in EffectTable do
                local emit = CreateEmitterAtEntity(self,army,v)
                EmitterScaleEmitter(emit, EffectScale)
            end
        end
    end,
}

TypeClass = CIFMolecularResonanceShell01