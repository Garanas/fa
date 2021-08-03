--
-- Aeon Serpentine Missile
--
local AMissileSerpentineProjectile = import('/lua/aeonprojectiles.lua').AMissileSerpentineProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetLifetime = ProjectileMethods.SetLifetime

-- attach for CTRL + SHIFT F replacement

AIFMissileSerpentine01 = Class(AMissileSerpentineProjectile) {
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2)
        self.MoveThread = ForkThread(self.MovementThread, self)
    end,

    MovementThread = function(self)        
        self.WaitTime = 0.1
        self.Distance = self:GetDistanceToTarget()
        ProjectileSetTurnRate(self, 8)
        WaitSeconds(0.3)        
        while not EntityBeenDestroyed(self) do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > self.Distance then
        	ProjectileSetTurnRate(self, 75)
        	WaitSeconds(3)
        	ProjectileSetTurnRate(self, 8)
        	self.Distance = self:GetDistanceToTarget()
        end
        if dist > 50 then        
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            ProjectileSetTurnRate(self, 10)
        elseif dist > 30 and dist <= 50 then
						ProjectileSetTurnRate(self, 12)
						WaitSeconds(1.5)
            ProjectileSetTurnRate(self, 12)
        elseif dist > 10 and dist <= 25 then
            WaitSeconds(0.3)
            ProjectileSetTurnRate(self, 50)
		elseif dist > 0 and dist <= 10 then         
            ProjectileSetTurnRate(self, 100)   
            KillThread(self.MoveThread)         
        end
    end,        

    GetDistanceToTarget = function(self)
        local tpos = ProjectileGetCurrentTargetPosition(self)
        local mpos = EntityGetPosition(self)
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}

TypeClass = AIFMissileSerpentine01