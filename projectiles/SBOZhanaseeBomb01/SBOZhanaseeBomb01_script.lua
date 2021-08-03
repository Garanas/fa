-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/SBOZhanaseeBomb/SBOZhanaseeBomb01_script.lua
--  Author(s):  Greg Kohne, Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Zhanasee Bomb script, used on XSA0304
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local SZhanaseeBombProjectile = import('/lua/seraphimprojectiles.lua').SZhanaseeBombProjectile
local DefaultExplosion = import('/lua/defaultexplosions.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local CreateLightParticle = CreateLightParticle

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityCreateProjectile = EntityMethods.CreateProjectile

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetCollision = ProjectileMethods.SetCollision
local ProjectileSetVelocity = ProjectileMethods.SetVelocity

-- attach for CTRL + SHIFT F replacement

SBOZhanaseeBombProjectile01 = Class(SZhanaseeBombProjectile){
    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        data.DamageAmount = data.DamageAmount - 2
        
        CreateLightParticle(self, -1, army, 26, 5, 'sparkle_white_add_08', 'ramp_white_24' )
        
        -- One initial projectile following same directional path as the original
        local proj = EntityCreateProjectile(self, '/effects/entities/SBOZhanaseeBombEffect01/SBOZhanaseeBombEffect01_proj.bp', 0, 0, 0, 0, 10.0, 0)
        ProjectileSetCollision(proj, false)
        ProjectileSetVelocity(proj, 0,10.0, 0)

        local proj = EntityCreateProjectile(self, '/effects/entities/SBOZhanaseeBombEffect02/SBOZhanaseeBombEffect02_proj.bp', 0, 0, 0, 0, 0.05, 0)
        ProjectileSetCollision(proj, false)
        ProjectileSetVelocity(proj, 0,0.05, 0)
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            CreateDecal( pos, RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', 40, 40, 300, 200, army)
        end
        
		SZhanaseeBombProjectile.OnImpact(self, targetType, targetEntity) 
        
    end,
}
TypeClass = SBOZhanaseeBombProjectile01
