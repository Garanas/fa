--
-- TestProjectile
--
local Projectile = import('/lua/sim/Projectile.lua').Projectile

-- globals as upvalues for performance 
local CreateTrail = CreateTrail
local CreateEmitterOnEntity = CreateEmitterOnEntity
local AttachBeamToEntity = AttachBeamToEntity
local CreateBeamEmitter = CreateBeamEmitter

local TrashAdd = TrashBag.Add

-- attach for CTRL + SHIFT F replacement

TestProjectile01 = Class(Projectile)
{
    BeamName = '/effects/emitters/test_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/test_polytrail_01_emit.bp',
    FxTrails = {'/effects/emitters/test_emittrail_01_emit.bp',},

    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},

    OnCreate = function(self)
        local army = self.Army
        local fxTrails = self.FxTrails
        local polytrail = self.PolyTrail

        Projectile.OnCreate(self)

        --Polytrail
        CreateTrail(self, -1, army, polytrail )

        --Emitter trail
        for i in fxTrails do
            CreateEmitterOnEntity(self,army, fxTrails[i])
        end

        --Beam Trail
        local beam = CreateBeamEmitter(self.BeamName,army)
        AttachBeamToEntity(beam, self, -1, army)

    end,
}

TypeClass = TestProjectile01