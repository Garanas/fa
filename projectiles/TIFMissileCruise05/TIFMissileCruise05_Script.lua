--
-- Terran Land-Based Cruise Missile : XEL0306 (UEF T3 MML)
--

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local DamageArea = DamageArea
local ForkThread = ForkThread
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

-- attach for CTRL + SHIFT F replacement

local GetSquaredDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

local SetTurnRateByDist = function(self)
    local dist = GetSquaredDistanceToTarget(self)
    if dist > self.Distance then
        ProjectileSetTurnRate(self, 50)
        WaitSeconds(3)
        ProjectileSetTurnRate(self, 8)
        self.Distance = GetSquaredDistanceToTarget(self)
    end
    if dist > 50 * 50 then        
        -- Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 10)
    elseif dist > 30 * 30 and dist <= 50 * 50 then
        ProjectileSetTurnRate(self, 12)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 12)
    elseif dist > 10 * 10 and dist <= 25 * 25 then
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 10 * 10 then         
        ProjectileSetTurnRate(self, 100)   
        KillThread(self.MoveThread)         
    end
end  

local MovementThread = function(self)        
    local waitTime = 0.1
    self.Distance = GetSquaredDistanceToTarget(self)
    ProjectileSetTurnRate(self, 8)
    WaitSeconds(0.3)        
    while not EntityBeenDestroyed(self) do
        self:SetTurnRateByDist()
        WaitSeconds(waitTime)
    end
end

TIFMissileCruise05 = Class(TMissileCruiseProjectile) {

    FxTrails = EffectTemplate.TMissileExhaust01,
    FxTrailOffset = -0.85,
    
    FxAirUnitHitScale = 0.65,
    FxLandHitScale = 0.65,
    FxNoneHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxProjectileHitScale = 0.65,
    FxProjectileUnderWaterHitScale = 0.65,
    FxShieldHitScale = 0.65,
    FxUnderWaterHitScale = 0.65,
    FxUnitHitScale = 0.65,
    FxWaterHitScale = 0.65,
    FxOnKilledScale = 0.65,
    
    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2)
        self.MoveThread = ForkThread(MovementThread, self)
    end,    
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        data.DamageAmount = data.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*3.141592)
            local army = self.Army

            CreateDecal(pos, rotation, 'nuke_scorch_003_albedo', '', 'Albedo', radius * 2, radius * 2, 200, 40, army)
        end
        
        TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TIFMissileCruise05

