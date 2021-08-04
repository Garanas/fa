--
-- Ship-based Anti-Torpedo Script
--

local CDepthChargeProjectile = import('/lua/cybranprojectiles.lua').CDepthChargeProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

CIMAntiTorpedo02 = Class(CDepthChargeProjectile) {
	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        ProjectileSetBallisticAcceleration(self, 2)
    end,
}

TypeClass = CIMAntiTorpedo02