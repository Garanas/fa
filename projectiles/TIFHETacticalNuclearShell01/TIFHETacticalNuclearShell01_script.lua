--
-- UEF Anti-Matter Shells
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile

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

TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile) {
    FxSplatScale = 9,
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
            local scale = self.FxSplatScale
            
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'nuke_scorch_001_normals', '', 'Alpha Normals', scale, scale, 350, 200, army)
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'nuke_scorch_002_albedo', '', 'Albedo', scale * 2, scale * 2, 350, 200, army)
        end
        
        ProjectileShakeCamera(self, 20, 3, 0, 1)
        
        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells01