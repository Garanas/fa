--
-- UEF T3 Artillery Anti-Matter Shells : ueb2302
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterProjectile02 = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile02

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

TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile02) {
    FxSplatScale = 7,

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

            CreateDecal(pos, RandomFloat(0,2*3.141592), 'nuke_scorch_001_normals', '', 'Alpha Normals', scale, scale, 250, 150, army)
            CreateDecal(pos, RandomFloat(0,2*3.141592), 'nuke_scorch_002_albedo', '', 'Albedo', scale * 2, scale * 2, 250, 150, army)
        end
        
        ProjectileShakeCamera(self, 20, 2, 0, 1)

        TArtilleryAntiMatterProjectile02.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells01