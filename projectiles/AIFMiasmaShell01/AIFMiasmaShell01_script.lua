--
-- Aeon T2 Artillery Projectile : uab2303
--

local AMiasmaProjectile = import('/lua/aeonprojectiles.lua').AMiasmaProjectile
local utilities = import('/lua/utilities.lua')

-- globals as upvalues for performance 
local DamageArea = DamageArea

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntityGetPosition = EntityMethods.GetPosition
local EntityPlaySound = EntityMethods.PlaySound

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity

-- attach for CTRL + SHIFT F replacement

AIFMiasmaShell01 = Class(AMiasmaProjectile) {
    OnImpact = function(self, targetType, targetEntity) 
        -- Sounds for all other impacts, ie: Impact<targetTypeName>
        local bp = self.Blueprint.Audio
        local snd = bp['Impact'.. targetType]
        local pos = EntityGetPosition(self)

        local damageData = self.DamageData
        local radius = damageData.DamageRadius
		local FriendlyFire = damageData.DamageFriendly
        
        if snd then
            EntityPlaySound(self, snd)
            -- Generic Impact Sound
        elseif bp.Impact then
            EntityPlaySound(self, bp.Impact)
        end
        
		self:CreateImpactEffects( self.Army, self.FxImpactNone, self.FxNoneHitScale )
		local x,y,z = ProjectileGetVelocity(self)
		local speed = utilities.GetVectorLength(Vector(x*10,y*10,z*10))
		
		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile('/projectiles/AIFMiasmaShell02/AIFMiasmaShell02_proj.bp' )
        :SetVelocity(x,y,z):SetVelocity(speed).PassDamageData(, damageData)
                
        EntityDestroy(self)
        
        -- already kill the trees, so better make them fall. Even if it would be better that it doesn't kill trees at all.
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        damageData.DamageAmount = damageData.DamageAmount - 2
        
    end,
    
}

TypeClass = AIFMiasmaShell01