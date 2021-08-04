local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance 
local DamageArea = DamageArea
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateDecal = CreateDecal
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateLightParticle = CreateLightParticle

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

-- attach for CTRL + SHIFT F replacement

local ShakeAndBurnMe = function(self, army)
    ProjectileShakeCamera(self, 75, 3, 0, 10)
    WaitSeconds(0.5)
    -- CreateDecal(position, heading, textureName, type, sizeX, sizeZ, lodParam, duration, army)");
    local orientation = RandomFloat(0,2*3.141592)
    local pos = EntityGetPosition(self)
    
    DamageArea(self, pos, 25, 1, 'Force', true)
    DamageArea(self, pos, 25, 1, 'Force', true)
    
    CreateDecal(pos, orientation, 'Scorch_012_albedo', '', 'Albedo', 70, 70, 800, 0, army)
    CreateDecal(pos, orientation, 'Crater01_normals', '', 'Normals', 70, 70, 800, 0, army)
    ProjectileShakeCamera(self, 105, 10, 0, 2)
    WaitSeconds(2)
    ProjectileShakeCamera(self, 75, 1, 0, 15)
end

local DistortionField = function(self)
    local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
    local scale = proj.Blueprint.Display.UniformScale

    ProjectileSetScaleVelocity(proj, 0.3 * scale,0.3 * scale,0.3 * scale)
    WaitSeconds(17.0)
    ProjectileSetScaleVelocity(proj, 0.01 * scale,0.01 * scale,0.01 * scale)
end

SIFExperimentalStrategicDeath01 = Class(NullShell) {
    NormalEffects = {'/effects/emitters/quantum_warhead_01_emit.bp',},
    CloudFlareEffects = EffectTemplate.CloudFlareEffects01,

    EffectThread = function(self)
        local army = self.Army
        -- CreateLightParticle(self, -1, army, 50, 50, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
        -- Create full-screen glow flash
        CreateLightParticle(self, -1, army, 80, 10, 'glow_02', 'ramp_blue_22')
        WaitSeconds(0.3)
        CreateLightParticle(self, -1, army, 40, 30, 'glow_02', 'ramp_blue_16')
        WaitSeconds(3.0)
        CreateLightParticle(self, -1, army, 60, 15, 'glow_02', 'ramp_blue_16')
        WaitSeconds(0.1)
        CreateLightParticle(self, -1, army, 30, 30, 'glow', 'ramp_blue_22')
        
        TrashAdd(self.Trash, ForkThread(ShakeAndBurnMe, self, army))
        TrashAdd(self.Trash, ForkThread(DistortionField, self))

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity(self, army, v)
        end
    end,
}

TypeClass = SIFExperimentalStrategicDeath01
