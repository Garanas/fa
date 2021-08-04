------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateDecal = CreateDecal
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateLightParticle = CreateLightParticle

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityCreateProjectile = EntityMethods.CreateProjectile

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileSetScaleVelocity = ProjectileMethods.SetScaleVelocity
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration
local ProjectileSetScale = ProjectileMethods.SetScale

-- attach for CTRL + SHIFT F replacement

CIFEMPFluxWarhead02 = Class(NullShell) {

    -- Effects attached to moving nuke projectile plume
    PlumeEffects = {'/effects/emitters/empfluxwarhead_concussion_ring_02_emit.bp',
                    '/effects/emitters/empfluxwarhead_01_emit.bp',
                    '/effects/emitters/empfluxwarhead_02_emit.bp',
                    '/effects/emitters/empfluxwarhead_03_emit.bp'},

    -- Effects not attached but created at the position of CIFEMPFluxWarhead02
    NormalEffects = {'/effects/emitters/empfluxwarhead_concussion_ring_01_emit.bp',
                     '/effects/emitters/empfluxwarhead_fallout_01_emit.bp'},

    PlumeVelocityScale = 0.1,

    EffectThread = function(self)
        -- Light and Camera Shake
        CreateLightParticle(self, -1, self.Army, 200, 200, 'beam_white_01', 'ramp_red_09')
        ProjectileShakeCamera(self, 75, 3, 0, 20)

        -- Mesh effects
        self.Plumeproj = EntityCreateProjectile(self, '/effects/EMPFluxWarhead/EMPFluxWarheadEffect01_proj.bp')
        TrashAdd(self.Trash, ForkThread(self.PlumeThread, self, self.Plumeproj, self.Plumeproj.Blueprint.Display.UniformScale))
        TrashAdd(self.Trash, ForkThread(self.PlumeVelocityThread, self, self.Plumeproj))

        self.Plumeproj2 = EntityCreateProjectile(self, '/effects/EMPFluxWarhead/EMPFluxWarheadEffect02_proj.bp')
        TrashAdd(self.Trash, ForkThread(self.PlumeThread, self, self.Plumeproj2, self.Plumeproj2.Blueprint.Display.UniformScale))
        TrashAdd(self.Trash, ForkThread(self.PlumeVelocityThread, self, self.Plumeproj2))

        self.Plumeproj3 = EntityCreateProjectile(self, '/effects/EMPFluxWarhead/EMPFluxWarheadEffect03_proj.bp')
        TrashAdd(self.Trash, ForkThread(self.PlumeThread, self, self.Plumeproj3, self.Plumeproj3.Blueprint.Display.UniformScale))
        TrashAdd(self.Trash, ForkThread(self.PlumeVelocityThread, self, self.Plumeproj3))

        CreateDecal(EntityGetPosition(self), RandomFloat(0,2*3.141592), 'nuke_scorch_001_albedo', '', 'Albedo', 28, 28, 500, 0, self.Army)

        -- Emitter Effects
        TrashAdd(self.Trash, ForkThread(self.EmitterEffectsThread, self, self.Plumeproj))
    end,

    EmitterEffectsThread = function(self, plume)
        local army = self.Army
        for k, v in self.PlumeEffects do
            CreateAttachedEmitter(plume, -1, army, v)
        end

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity(self, army, v)
        end

        self:StarCloudDispersal()
    end,

    StarCloudDispersal = function(self)
        local numProjectiles = 5
        local angle = (2*3.141592) / numProjectiles
        local angleInitial = RandomFloat(0, angle)
        local angleVariation = angle * 0.5
        local projectiles = {}

        local xVec = 0
        local yVec = 0.3
        local zVec = 0
        local velocity = 0

        -- yVec -0.2, requires 2 initial velocity to start
        -- yVec 0.3, requires 3 initial velocity to start
        -- yVec 1.8, requires 8.5 initial velocity to start

        -- Launch projectiles at semi-random angles away from the sphere, with enough
        -- initial velocity to escape sphere core
        for i = 0, (numProjectiles -1) do
            xVec = MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            yVec = 0.3 + RandomFloat(-0.8, 1.0)
            zVec = MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            velocity = 2.4 + (yVec * 3)
            local proj = EntityCreateProjectile(self, '/projectiles/CIFEMPFluxWarhead03/CIFEMPFluxWarhead03_proj.bp', 0, 0, 0, xVec, yVec, zVec)
            ProjectileSetVelocity(proj, velocity)
            ProjectileSetBallisticAcceleration(proj, 1.0)
            projectiles[i + 1] = proj
        end

        WaitSeconds(3)

        -- Slow projectiles down to normal speed
        for k = 1, numProjectiles do
            local proj = projectiles[k]
            ProjectileSetVelocity(proj, 2):
            ProjectileSetBallisticAcceleration(proj, -0.15)
        end
    end,

    PlumeVelocityThread = function(self, plume)
        local plumeVelocityScale = self.PlumeVelocityScale
        ProjectileSetVelocity(plume, 0,5.35 * plumeVelocityScale,0)
        WaitSeconds(0.5)
        ProjectileSetVelocity(plume, 0,23 * plumeVelocityScale,0)
        WaitSeconds(0.5)
        ProjectileSetVelocity(plume, 0,45 * plumeVelocityScale,0)
        WaitSeconds(1.3)
        ProjectileSetVelocity(plume, 0,27 * plumeVelocityScale,0)
    end,

    PlumeThread = function(self, plume, scale)

        -- Anim Time : 1.0 sec
        ProjectileSetScale(plume, 0.229 * scale,0.229 * scale,0.229 * scale)
        ProjectileSetScaleVelocity(plume, 0.223 * scale,0.223 * scale,0.223 * scale)
        WaitSeconds(2.3)

        -- Anim Time : 6.333 sec
        ProjectileSetScaleVelocity(plume, 0.086 * scale,0.086 * scale,0.086 * scale)
        WaitSeconds(0.7)

        -- Anim Time : 7.0 sec
        ProjectileSetScaleVelocity(plume, 0.119 * scale,0.119 * scale,0.119 * scale)
        WaitSeconds(1)

        -- Anim Time : 8.0 sec
        ProjectileSetScaleVelocity(plume, 0.106 * scale,0.106 * scale,0.106 * scale)
        WaitSeconds(1)

        -- Anim Time : 9.0 sec
        ProjectileSetScaleVelocity(plume, 0.092 * scale,0.092 * scale,0.092 * scale)
        WaitSeconds(1)

        -- Anim Time : 10.0 sec
        ProjectileSetScaleVelocity(plume, 0.077 * scale,0.077 * scale,0.077 * scale)
        WaitSeconds(1)

        -- Anim Time : 11.0 sec
        ProjectileSetScaleVelocity(plume, 0.06 * scale,0.06 * scale,0.06 * scale)
        WaitSeconds(1)

        -- Anim Time : 12.0 sec
        ProjectileSetScaleVelocity(plume, 0.016 * scale,0.016 * scale,0.016 * scale)
        WaitSeconds(0.3)

        -- Anim Time : 12.333 sec
        ProjectileSetScaleVelocity(plume, 0.03 * scale,0.03 * scale,0.03 * scale)
        WaitSeconds(0.7)

        -- Anim Time : 13.0 sec
        ProjectileSetScaleVelocity(plume, 0.043 * scale,0.043 * scale,0.043 * scale)
        WaitSeconds(1)

        -- Anim Time : 14.0 sec
        ProjectileSetScaleVelocity(plume, 0.041 * scale,0.041 * scale,0.041 * scale)
        WaitSeconds(1)

        -- Anim Time : 15.0 sec
        ProjectileSetScaleVelocity(plume, 0.038 * scale,0.038 * scale,0.038 * scale)
        WaitSeconds(1)

        -- Anim Time : 16.0 sec
        ProjectileSetScaleVelocity(plume, 0.036 * scale,0.036 * scale,0.036 * scale)
        WaitSeconds(1)

        -- Anim Time : 17.0 sec
        ProjectileSetScaleVelocity(plume, 0.033 * scale,0.033 * scale,0.033 * scale)
        WaitSeconds(1)

        -- Anim Time : 18.0 sec
        ProjectileSetScaleVelocity(plume, 0.03 * scale,0.03 * scale,0.03 * scale)
        WaitSeconds(1)

        -- Anim Time : 19.0 sec
        ProjectileSetScaleVelocity(plume, 0.027 * scale,0.027 * scale,0.027 * scale)
        WaitSeconds(1)

        -- Anim Time : 20.0 sec
        ProjectileSetScaleVelocity(plume, 0.024 * scale,0.024 * scale,0.024 * scale)
        WaitSeconds(1)

        -- Anim Time : 21.0 sec
        ProjectileSetScaleVelocity(plume, 0.02 * scale,0.02 * scale,0.02 * scale)
        WaitSeconds(1)

        -- Anim Time : 22.0 sec
        ProjectileSetScaleVelocity(plume, 0.017 * scale,0.017 * scale,0.017 * scale)
        WaitSeconds(1)

        -- Anim Time : 23.0 sec
        ProjectileSetScaleVelocity(plume, 0.013 * scale,0.013 * scale,0.013 * scale)
        WaitSeconds(1)

        -- Anim Time : 24.0 sec
        ProjectileSetScaleVelocity(plume, 0.009 * scale,0.009 * scale,0.009 * scale)
        WaitSeconds(1)

        -- Anim Time : 25.0 sec
        ProjectileSetScaleVelocity(plume, 0.005 * scale,0.005 * scale,0.005 * scale)
        WaitSeconds(1)

        -- Anim Time : 26.0 sec
        ProjectileSetScaleVelocity(plume, 0.001 * scale,0.001 * scale,0.001 * scale)
    end,
}

TypeClass = CIFEMPFluxWarhead02
