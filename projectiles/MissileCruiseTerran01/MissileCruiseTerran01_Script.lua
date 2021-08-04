--
-- script for projectile Missile
--
local Projectile = import('/lua/sim/Projectile.lua').Projectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape

-- attach for CTRL + SHIFT F replacement

local CruiseMissileThread = function(self)

    local army = self.Army

    ProjectileTrackTarget(self, false)
    WaitSeconds(4) -- Straight Up
    ProjectileTrackTarget(self, true)
    WaitSeconds(1) -- Start Tracking
    ProjectileTrackTarget(self, false)
    ProjectileSetMaxSpeed(self, 2)

    local trails = self.trails
    for i in trails do
        trails[i]:Destroy()
    end

    self.MissileExhaust:Destroy()
    WaitSeconds(0.5) -- Falling

    self.MissileExhaust = CreateBeamEmitter('/effects/emitters/missile_cruise_munition_exhaust_beam_02_emit.bp', army)
    AttachBeamToEntity(self.MissileExhaust, self, -1, army)

    local trails = { }
    local fxTrails = self.FxTrails
    for i in fxTrails do
        local emit = CreateEmitterOnEntity(self, army, fxTrails[i])
        emit:ScaleEmitter(self.FxTrailScale)
        emit:OffsetEmitter(0, 0, self.FxTrailOffset)
        trails[i] = emit
    end

    self.trails = trails

    ProjectileSetTurnRate(self, 20)
    ProjectileTrackTarget(self, true)
    
    WaitSeconds(0.5)
    ProjectileSetTurnRate(self, 400)
    ProjectileSetMaxSpeed(self, 25)
    ProjectileSetAcceleration(self, 25)
end

MissileCruiseTerran01 = Class(Projectile) {
    MissileExhaust = {},

-- LAUNCH BEAM
    FxLaunchBeamTexture = '/textures/particles/beam_missile_exhaust_01.dds',
    FxLaunchBeamSize = {-0.5, 0.015}, --Length, Width
    FxLaunchBeamColor = {1, 1, 0.75}, --R,G,B
    FxLaunchBeamGlow = 0.0,
-- LAUNCH TRAILS
    FxLaunchTrails = {'/effects/emitters/missile_cruise_munition_launch_trail_01_emit.bp',},
    FxLaunchTrailScale = 1,
    FxLaunchTrailOffset = -0.5,

-- BEAM
    FxBeamTexture = '/textures/particles/beam_missile_exhaust_02.dds',
    FxBeamSize = {-1, 0.5}, --Length, Width
    FxBeamColor = {1, 1, 0.75}, --R,G,B
    FxBeamGlow = 0.0,
-- TRAILS
    FxTrails = { '/effects/emitters/missile_cruise_munition_trail_01_emit.bp', },
    FxTrailScale = 1,
    FxTrailOffset = -0.5,

-- Hit Effects
    FxUnitHitScale = 1,
    FxImpactUnit = {
        '/effects/emitters/missile_hit_flash_01_emit.bp',
        '/effects/emitters/missile_hit_fire_01_emit.bp',
    },
    FxLandHitScale = 1,
    FxImpactLand = {
        '/effects/emitters/missile_hit_flash_01_emit.bp',
        '/effects/emitters/missile_hit_fire_01_emit.bp',
        '/effects/emitters/destruction_scorch_01_emit.bp',
    },
--    FxWaterHitScale = 2,
--    FxImpactWater = {'missile_hit_flash_01','missile_hit_fire_01',},
--    FxUnderWaterHitScale = 1,
    FxImpactUnderWater = {},
--    FxNoneHitScale = 1,
    FxImpactNone = {
        '/effects/emitters/missile_hit_flash_01_emit.bp',
        '/effects/emitters/missile_hit_fire_01_emit.bp',
    },

    OnCreate = function(self)
        Projectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 1.0)

        local army = self.Army

        local trails = { }
        local fxTrails = self.FxTrails
        for i in fxTrails do
            local emit = CreateEmitterOnEntity(self, army, fxTrails[i])
            emit:ScaleEmitter(self.FxTrailScale)
            emit:OffsetEmitter(0, 0, self.FxTrailOffset)
            trails[i] = emit
        end
    
        self.trails = trails

        self.MissileExhaust = CreateBeamEmitter('/effects/emitters/missile_cruise_munition_exhaust_beam_01_emit.bp', army)
        AttachBeamToEntity(self.MissileExhaust, self, -1, army)

        TrashAdd(self.Trash, ForkThread(CruiseMissileThread, self))
    end,

    OnImpact = function(self, TargetType, TargetEntity)

        local trails = self.trails
        for i in trails do
            trails[i]:Destroy()
            trails[i] = nil
        end

        Projectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = MissileCruiseTerran01

