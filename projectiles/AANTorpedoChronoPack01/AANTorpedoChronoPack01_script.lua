--
-- Aeon Chrono Torpedo Pack
-- This will split up into 4 Chrono Torpedoes after it gets close to an enemy
--
local ATorpedoShipProjectile = import('/lua/aeonprojectiles.lua').ATorpedoShipProjectile

-- globals as upvalues for performance 
local WaitSeconds = WaitSeconds

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter

-- attach for CTRL + SHIFT F replacement

AANTorpedoChronoPack01 = Class(ATorpedoShipProjectile) {
    FxSplashScale = 1,
    NumberOfChildProjectiles = 4,
    KillWaitingThread = true,
    KillSplitUpThread = false,
    DistanceBeforeSplitRatio = 0.35,
    VelocityOnEnterWater = 3,

    SplitUpThread = function(self)
        local TrackingTarget = ProjectileGetTrackingTarget(self)
        local SplitWaitTime = 1.0

        if( TrackingTarget != nil ) then
            SplitWaitTime = (VDist3( EntityGetPosition(self), EntityGetPosition(TrackingTarget) ) * self.DistanceBeforeSplitRatio) / self.VelocityOnEnterWater
        end

        WaitSeconds(SplitWaitTime)
        local Velx, Vely, Velz = ProjectileGetVelocity(self)
        local angleRange = 3.141592
        local angleInitial = -angleRange / 2
        local angleIncrement = angleRange / (self.NumberOfChildProjectiles - 1 )
        local angle, ca, sa, x, z, proj
        for i = 0, (self.NumberOfChildProjectiles - 1) do
            angle = angleInitial + (i*angleIncrement)
            ca = MathCos(angle)
            sa = MathSin(angle)
            x = Velx * ca - Velz * sa
            z = Velx * sa + Velz * ca
            proj = self:CreateChildProjectile('/projectiles/AANTorpedo01/AANTorpedo01_proj.bp')
            ProjectileSetVelocity(proj,  x * 2, Vely, z * 2 )
        end
        EntityDestroy(self)
    end,
}

TypeClass = AANTorpedoChronoPack01
