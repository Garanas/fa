--
-- Seraphim Energy Being Laser
--
local SEnergyLaser = import('/lua/seraphimprojectiles.lua').SEnergyLaser

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration

local MovementThread = function(self)
	WaitSeconds(.2)
	ProjectileSetAcceleration(self, 9999)
end

SDFEnergyLaser01 = Class(SEnergyLaser) {
    OnCreate = function(self)
    	SEnergyLaser.OnCreate(self)
        TrashAdd(self.Trash, ForkThread( MovementThread , self))
    end,
}

TypeClass = SDFEnergyLaser01

