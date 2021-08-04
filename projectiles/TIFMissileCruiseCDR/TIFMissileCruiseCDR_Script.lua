--
-- Terran Land-Based Cruise Missile
--
local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile02
local Explosion = import('/lua/defaultexplosions.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local DamageArea = DamageArea
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local CreateDecal = CreateDecal

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
    -- Get the nuke as close to 90 deg as possible
    if dist > 50 * 50 then        
        -- Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 20)
    elseif dist > 30 * 30 and dist <= 150 * 150 then
        -- Increase check intervals
        ProjectileSetTurnRate(self, 30)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 30)
    elseif dist > 10 * 10 and dist <= 30 * 30 then
        -- Further increase check intervals
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 10 * 10 then
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

TIFMissileCruiseCDR = Class(TMissileCruiseProjectile) {

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

    FxTrails = EffectTemplate.TMissileExhaust01,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2)
        TrashAdd(self.Trash, ForkThread(MovementThread, self))
    end,

    OnEnterWater = function(self)
        TMissileCruiseProjectile.OnEnterWater(self)
        ProjectileSetDestroyOnWater(self, true)
    end,
}
TypeClass = TIFMissileCruiseCDR

