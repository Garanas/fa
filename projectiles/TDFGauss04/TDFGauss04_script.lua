--
-- Terran Gauss Cannon Projectile
--

local TDFGaussCannonProjectile = import('/lua/terranprojectiles.lua').TDFLandGaussCannonProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater

local DestroyOnWaterThread = function(self)
    WaitSeconds(0.2)
    ProjectileSetDestroyOnWater(self, true)
end

TDFGauss04 = Class(TDFGaussCannonProjectile) {
    
    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            ProjectileSetDestroyOnWater(self, true)
        else
            ForkThread(DestroyOnWaterThread, self)
        end
    end,

}
TypeClass = TDFGauss04

