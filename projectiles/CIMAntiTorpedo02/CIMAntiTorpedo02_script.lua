--
-- Ship-based Anti-Torpedo Script
--

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

local MotionThread = function(self)
    WaitSeconds( 2 )
    ProjectileSetBallisticAcceleration(self, -3)
end

local CDepthChargeProjectile = import('/lua/cybranprojectiles.lua').CDepthChargeProjectile
CIMAntiTorpedo02 = Class(CDepthChargeProjectile) {

	OnCreate = function(self, inWater)
        CDepthChargeProjectile.OnCreate(self, inWater)
        ProjectileSetBallisticAcceleration(self, 0)
        ForkThread( MotionThread , self) 
    end,



}

TypeClass = CIMAntiTorpedo02