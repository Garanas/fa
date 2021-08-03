--
-- Serpentine Missile 03
--
local AMissileSerpentine02Projectile = import('/lua/aeonprojectiles.lua').AMissileSerpentine02Projectile

AIFMissileTactical02 = Class(AMissileSerpentine02Projectile) {

    OnCreate = function(self)
        AMissileSerpentine02Projectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        ForkThread( self.MovementThread , self)
    end,

    MovementThread = function(self)        
        self.WaitTime = 0.1
        ProjectileSetTurnRate(self, 3)
        WaitSeconds(2)        
        while not EntityBeenDestroyed(self) do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        --Get the nuke as close to 90 deg as possible
        if dist > 100 then        
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            ProjectileSetTurnRate(self, 20)
        elseif dist > 64 and dist <= 107 then
						-- Increase check intervals
						ProjectileSetTurnRate(self, 30)
						WaitSeconds(1.5)
            ProjectileSetTurnRate(self, 30)
        elseif dist > 21 and dist <= 53 then
						-- Further increase check intervals
            WaitSeconds(0.3)
            ProjectileSetTurnRate(self, 50)
				elseif dist > 0 and dist <= 21 then
						-- Further increase check intervals            
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
TypeClass = AIFMissileTactical02