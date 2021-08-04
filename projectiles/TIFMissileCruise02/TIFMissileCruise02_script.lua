--
-- Terran Sub-Launched Cruise Missile
--
local TMissileCruiseSubProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseSubProjectile

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater

-- attach for CTRL + SHIFT F replacement

local GetSquaredDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

local SetTurnRateByDist = function(self)
    local dist = GetSquaredDistanceToTarget(self)
    --Get the nuke as close to 90 deg as possible
    if dist > 50 * 50 then        
        --Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 20)
    elseif dist > 64 * 64 and dist <= 107 * 107 then
        -- Increase check intervals
        ProjectileSetTurnRate(self, 30)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 30)
    elseif dist > 21 * 21 and dist <= 53 * 53 then
        -- Further increase check intervals
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 21 * 21 then
        -- Further increase check intervals            
        ProjectileSetTurnRate(self, 100)         
    end
end   

local MovementThread = function(self)        
    local waitTime = 0.1
    ProjectileSetTurnRate(self, 8)
    WaitSeconds(0.3)        
    while not EntityBeenDestroyed(self) do
        SetTurnRateByDist(self)
        WaitSeconds(waitTime)
    end
end

TIFMissileCruise02 = Class(TMissileCruiseSubProjectile) {

	FxAirUnitHitScale = 1.65,
    FxLandHitScale = 1.65,
    FxNoneHitScale = 1.65,
    FxPropHitScale = 1.65,
    FxProjectileHitScale = 1.65,
    FxProjectileUnderWaterHitScale = 1.65,
    FxShieldHitScale = 1.65,
    FxUnderWaterHitScale = 1.65,
    FxUnitHitScale = 1.65,
    FxWaterHitScale = 1.65,
    FxOnKilledScale = 1.65,

    OnCreate = function(self)
        TMissileCruiseSubProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        TrashAdd(self.Trash, ForkThread( MovementThread , self))
    end,  
    
    OnExitWater = function(self)
        TMissileCruiseSubProjectile.OnExitWater(self)
        ProjectileSetDestroyOnWater(self, true)
    end,
}

TypeClass = TIFMissileCruise02

