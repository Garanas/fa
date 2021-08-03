--
-- Spy Plane Launched Sonar Buoy Creator
--   This will create a temporary sonar buoy unit when it hits the water, nothing more.
--   This projectile is not intended to do damage.
--
local TTorpedoShipProjectile = import('/lua/terranprojectiles.lua').TTorpedoShipProjectile

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateUnit = CreateUnit

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPositionXYZ = EntityMethods.GetPosition
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape

-- attach for CTRL + SHIFT F replacement

TIMSonarBuoyCreator01 = Class(TTorpedoShipProjectile) {
    FxSplashScale = 0.2,
    FxTrailScale = 3,
    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

	OnCreate = function(self)
		TTorpedoshipProjectile.OnCreate(self)
		-- creates collision shape on creation since that's how it used to work
		-- before collision shapes got moved to creation OnEnterWater for torpedos
		-- to prevent them from being shot out of the sky
		ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 1.0)
	end,
	
    OnEnterWater = function(self)
        local army = self.Army
        local fxSplashScale = self.FxSplashScale
        local fxExitWaterEmitter = self.FxExitWaterEmitter
        for i in fxExitWaterEmitter do --splash
            local emit = CreateEmitterAtEntity(self,army,fxExitWaterEmitter[i])
            emit:ScaleEmitter(fxSplashScale)
        end

        local x,y,z = EntityGetPositionXYZ(self)
        CreateUnit('ueb5208', army, x, y, z, 0, 0, 0, 0)
        EntityDestroy(self)
    end,
}

TypeClass = TIMSonarBuoyCreator01
