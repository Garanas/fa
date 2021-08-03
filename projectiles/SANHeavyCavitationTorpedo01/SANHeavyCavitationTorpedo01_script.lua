--****************************************************************************
--**
--**  File     :  /data/projectiles/SANHeavyCavitationTorpedo01/SANHeavyCavitationTorpedo01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Heavy Cavitation Torpedo Projectile script, XSA0204
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SHeavyCavitationTorpedo = import('/lua/seraphimprojectiles.lua').SHeavyCavitationTorpedo
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

local EffectTemplates = import('/lua/EffectTemplates.lua')
local SHeavyCavitationTorpedoSplit = EffectTemplates.SHeavyCavitationTorpedoSplit
local SHeavyCavitationTorpedoFxTrails = EffectTemplates.SHeavyCavitationTorpedoFxTrails
local SHeavyCavitationTorpedoFxTrails02 = EffectTemplates.SHeavyCavitationTorpedoFxTrails02

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetCollideSurface = ProjectileMethods.SetCollideSurface
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile

-- attach for CTRL + SHIFT F replacement

local ProjectileSplit = function(self)
    WaitSeconds(0.1)
    local ChildProjectileBP = '/projectiles/SANHeavyCavitationTorpedo04/SANHeavyCavitationTorpedo04_proj.bp'
    local vx, vy, vz = ProjectileGetVelocity(self)
    local velocity = 10

    -- Create projectiles in a dispersal pattern
    local numProjectiles = 3
    local angle = (2*3.141592) / numProjectiles
    local angleInitial = RandomFloat(0, angle)

    -- Randomization of the spread
    local angleVariation = angle * 0.3 -- Adjusts angle variance spread
    local spreadMul = .4 -- Adjusts the width of the dispersal
    local xVec = 0
    local yVec = vy
    local zVec = 0

    -- Divide the damage between each projectile.  The damage in the BP is used as the initial projectile's
    -- damage, in case the torpedo hits something before it splits.
    local DividedDamageData = self.DamageData
    DividedDamageData.DamageAmount = DividedDamageData.DamageAmount / numProjectiles

    
    -- Split effects
    local FxFragEffect =  SHeavyCavitationTorpedoSplit
    for k, v in FxFragEffect do
        CreateEmitterAtEntity(self, self.Army, v)
    end

    -- Launch projectiles at semi-random angles away from split location
    for i = 0, (numProjectiles -1) do
        xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
        zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
        local proj = ProjectileCreateChildProjectile(self, ChildProjectileBP)
        proj.PassDamageData(proj, DividedDamageData)
        proj:PassData(ProjectileGetTrackingTarget(self))
        ProjectileSetVelocity(proj, xVec,yVec,zVec)
        ProjectileSetVelocity(proj, velocity)
    end
    EntityDestroy(self)
end

SANHeavyCavitationTorpedo01 = Class(SHeavyCavitationTorpedo) {
    FxSplashScale = .4,
    FxEnterWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
    },

    OnEnterWater = function(self)
        SHeavyCavitationTorpedo.OnEnterWater(self)

        local army = self.Army
        local fxSplashScale = self.FxSplashScale
        local fxEnterWaterEmitter = self.FxEnterWaterEmitter
        for i in fxEnterWaterEmitter do --splash
            local emit = CreateEmitterAtEntity(self, army, fxEnterWaterEmitter[i])
            emit:ScaleEmitter(fxSplashScale)
        end
        self.AirTrails:Destroy()
        CreateEmitterOnEntity(self,army, SHeavyCavitationTorpedoFxTrails)

        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        ProjectileSetCollideSurface(self, false)
        ProjectileSetTurnRate(self, 360)
        ForkThread(ProjectileSplit, self)
    end,

    OnCreate = function(self,inWater)
        SHeavyCavitationTorpedo.OnCreate(self,inWater)
        -- if we are starting in the water then immediately switch to tracking in water
        ProjectileTrackTarget(self, false)
        self.AirTrails = CreateEmitterOnEntity(self,self.Army, SHeavyCavitationTorpedoFxTrails02)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 0.1)
    end,
}
TypeClass = SANHeavyCavitationTorpedo01
