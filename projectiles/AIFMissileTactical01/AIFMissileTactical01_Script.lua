--
-- Aeon Land-Based Tactical Missile
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

-- attach for CTRL + SHIFT F replacement

-- computes squared distance between missile and target
local GetDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

-- changes turn rate based on distance
local SetTurnRateByDist = function(self)
    local dist = GetDistanceToTarget(self)
    --Get the nuke as close to 90 deg as possible
    if dist > 2500 then        
        --Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 20)
    elseif dist > 16.384 and dist <= 45.369 then
        -- Increase check intervals
        ProjectileSetTurnRate(self, 30)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 30)
    elseif dist > 1.849 and dist <= 11.449 then
        -- Further increase check intervals
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 1.849 then
        -- Further increase check intervals            
        ProjectileSetTurnRate(self, 100)   
        KillThread(CurrentThread())         
    end
end

-- thread that changes turn rate based on distance
local MovementThread = function(self)        
    ProjectileSetTurnRate(self, 8)
    WaitSeconds(0.3)        
    while not EntityBeenDestroyed(self) do
        SetTurnRateByDist(self)
        WaitSeconds(0.1)
    end
end

AIFMissileTactical01 = Class(AMissileSerpentineProjectile) {
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        ForkThread( MovementThread , self)
    end,
}
TypeClass = AIFMissileTactical01