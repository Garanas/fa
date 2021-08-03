--
-- URA0203 : cybran T2 gunship & URA0401 : Soul Ripper
--

local CIridiumRocketProjectile = import('/lua/cybranprojectiles.lua').CIridiumRocketProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageRing = DamageRing
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

CDFRocketIridium01 = Class(CIridiumRocketProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local damageData = self.DamageData
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        
        damageData.DamageAmount = damageData.DamageAmount - 2
        
        if radius > 0 then
            DamageArea( self, pos, radius - 1, 1, 'Force', FriendlyFire )
            DamageArea( self, pos, radius - 1, 1, 'Force', FriendlyFire )
        else
            DamageArea( self, pos, 1, 1, 'Force', FriendlyFire)
            DamageArea( self, pos, 1, 1, 'Force', FriendlyFire)
        end
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then

            local rotation = RandomFloat(0,2*3.141592)
            local army = self.Army
            
            if radius > 0 then
                DamageRing( self, pos, radius, 5/4 * radius, 1, 'Fire', true )
                
                CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius-0.5, radius-0.5, 100, 50, army)
            else
                DamageRing( self, pos, 1, 5/4, 1, 'Fire', true )
                
                CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 1, 1, 100, 50, army)
            end
        end
        
        CIridiumRocketProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = CDFRocketIridium01
