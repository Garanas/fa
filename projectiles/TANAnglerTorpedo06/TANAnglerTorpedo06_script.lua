--
-- Terran Torpedo Bomb
--
local TTorpedoShipProjectile = import('/lua/terranprojectiles.lua').TTorpedoShipProjectile

-- globals as upvalues for performance 
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape

TANAnglerTorpedo06 = Class(TTorpedoShipProjectile) 
{

    OnEnterWater = function(self)
        --TTorpedoShipProjectile.OnEnterWater(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 1.0)

        local army = self.Army
        local FxEnterWater = self.FxEnterWater
        for k, v in FxEnterWater do --splash
            CreateEmitterAtEntity(self,army,v)
        end

        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        ProjectileSetTurnRate(self, 240)
        ProjectileSetMaxSpeed(self, 18)
        --self:SetVelocity(0)
        --TrashAdd(self.Trash, ForkThread(self.MovementThread, self))
    end,

}

TypeClass = TANAnglerTorpedo06
