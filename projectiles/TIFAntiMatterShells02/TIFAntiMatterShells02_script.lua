--
-- UEF T3 Mobile Artillery Anti-Matter Shells : uel0304
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterSmallProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterSmallProjectile

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

TIFAntiMatterShells02 = Class(TArtilleryAntiMatterSmallProjectile) {
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
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'nuke_scorch_001_normals', '', 'Alpha Normals', radius + 1, radius + 1, 200, 150, army)
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'nuke_scorch_002_albedo', '', 'Albedo', radius + 6, radius + 6, 200, 150, army)
        end
        
        ProjectileShakeCamera(self,  20, 1, 0, 1 )

        TArtilleryAntiMatterSmallProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells02