--
-- UEF Subcommander Heavy Plasma bolt
--

local THeavyPlasmaCannonProjectile = import('/lua/terranprojectiles.lua').THeavyPlasmaCannonProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local EntityCategoryContains = EntityCategoryContains

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

TDFPlasmaHeavy03 = Class(THeavyPlasmaCannonProjectile) {

    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
		local launcher = self:GetLauncher()
		if launcher and launcher:HasEnhancement( 'HighExplosiveOrdnance' ) then
			CreateLightParticle( self, -1, army, 2.0, 9, 'ring_08', 'ramp_white_03' ) 
			CreateEmitterAtEntity(self,army,'/effects/emitters/terran_subcommander_aoe_01_emit.bp')
		end
		THeavyPlasmaCannonProjectile.CreateImpactEffects( self, army, EffectTable, EffectScale )
	end,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, 1, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, 1, 1, 'Force', FriendlyFire )

        data.DamageAmount = data.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' and targetType ~= 'Unit' then
            local rotation = RandomFloat(0,2*3.141592)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 1, 1, 70, 20, army)
        end
        
        THeavyPlasmaCannonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TDFPlasmaHeavy03

