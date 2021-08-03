------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CloudFlareEffects01 = import('/lua/EffectTemplates.lua').CloudFlareEffects01

-- globals as upvalues for performance 
local ForkThread = ForkThread
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

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera
local ProjectileSetScaleVelocity = ProjectileMethods.SetScaleVelocity

-- attach for CTRL + SHIFT F replacement

local ShakeAndBurnMe = function(self, army)
    ProjectileShakeCamera(self, 75, 3, 0, 10)
    WaitSeconds(0.5)
    local position = EntityGetPosition(self)
    local orientation = RandomFloat(0,2*3.141592)
    CreateDecal(position, orientation, 'Crater01_albedo', '', 'Albedo', 50, 50, 1200, 0, army)
    CreateDecal(position, orientation, 'Crater01_normals', '', 'Normals', 50, 50, 1200, 0, army)
    ProjectileShakeCamera(self, 105, 10, 0, 2)
    WaitSeconds(2)
    ProjectileShakeCamera(self, 75, 1, 0, 15)
end

local InnerCloudFlares = function(self, army)
    local numFlares = 50
    local angle = (2*3.141592) / numFlares
    local angleInitial = 0.0
    local angleVariation = (2*3.141592)

    local emit, x, y, z = nil
    local DirectionMul = 0.02
    local OffsetMul = 4

    for i = 0, (numFlares - 1) do
        x = MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
        y = 0.5
        z = MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))

        for k, v in self.CloudFlareEffects do
            emit = CreateEmitterAtEntity(self, army, v)
            emit:OffsetEmitter(x * OffsetMul, y * OffsetMul, z * OffsetMul)
            emit:SetEmitterCurveParam('XDIR_CURVE', x * DirectionMul, 0.01)
            emit:SetEmitterCurveParam('YDIR_CURVE', y * DirectionMul, 0.01)
            emit:SetEmitterCurveParam('ZDIR_CURVE', z * DirectionMul, 0.01)
        end

        if math.mod(i,11) == 0 then
            CreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
        end

        WaitSeconds(RandomFloat(0.05, 0.15))
    end

    CreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
    CreateEmitterAtEntity(self, army, '/effects/emitters/quantum_warhead_ring_01_emit.bp')
end

local DistortionField = function(self)
    local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
    local scale = proj.Blueprint.Display.UniformScale

    ProjectileSetScaleVelocity(proj, 0.123 * scale, 0.123 * scale, 0.123 * scale)
    WaitSeconds(17.0)
    ProjectileSetScaleVelocity(proj, 0.01 * scale, 0.01 * scale, 0.01 * scale)
end

AIFQuantumWarhead02 = Class(NullShell) {
    NormalEffects = {'/effects/emitters/quantum_warhead_01_emit.bp',},
    CloudFlareEffects = CloudFlareEffects01,

    EffectThread = function(self)
        local army = self.Army 
        CreateLightParticle(self, -1, army, 200, 200, 'beam_white_01', 'ramp_quantum_warhead_flash_01')

        ForkThread(ShakeAndBurnMe, self, army)
        ForkThread(InnerCloudFlares, self, army)
        ForkThread(DistortionField, self)

        for _, v in self.NormalEffects do
            CreateEmitterAtEntity(self, army, v)
        end
    end,
}

TypeClass = AIFQuantumWarhead02
