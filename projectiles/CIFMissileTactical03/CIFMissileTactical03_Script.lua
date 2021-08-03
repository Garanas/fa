-- 
-- URB2108 : cybran TML
-- Cybran "Loa" Tactical Missile, structure unit launched variant of this projectile,
-- with a higher arc and distance based adjusting trajectory. Splits into child projectile 
-- if it takes enough damage.
-- 

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CLOATacticalMissileProjectile = import('/lua/cybranprojectiles.lua').CLOATacticalMissileProjectile

-- globals as upvalues for performance 
local VDist2Sq = VDist2Sq
local DamageArea = DamageArea
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateDecal = CreateDecal
local CreateLightParticle = CreateLightParticle

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetHealth = EntityMethods.GetHealth
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape

local GetSquaredDistanceToTarget = function(self)
    local tpos = ProjectileGetCurrentTargetPosition(self)
    local mpos = EntityGetPosition(self)
    return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
end

local SetTurnRateByDist = function(self)
    if dist > 2500 then
        -- Freeze the turn rate as to prevent steep angles at long distance targets
        WaitSeconds(2)
        ProjectileSetTurnRate(self, 20)
    elseif dist > 16384 and dist <= 45369 then
        ProjectileSetTurnRate(self, 30)
        WaitSeconds(1.5)
        ProjectileSetTurnRate(self, 30)
    elseif dist > 1849 and dist <= 16384 then
        WaitSeconds(0.3)
        ProjectileSetTurnRate(self, 50)
    elseif dist > 0 and dist <= 1849 then
        ProjectileSetTurnRate(self, 100)
    end
end

local MovementThread = function(self)
    local WaitTime = 0.1
    ProjectileSetTurnRate(self, 8)
    WaitSeconds(0.3)
    while not EntityBeenDestroyed(self) do
        SetTurnRateByDist(self)
        WaitSeconds(WaitTime)
    end
end

CIFMissileTactical03 = Class(CLOATacticalMissileProjectile) {

    NumChildMissiles = 3,

    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        self.Split = false
        self.MovementTurnLevel = 1
        ForkThread( MovementThread , self)
    end,
    
    PassDamageData = function(self, damageData)
        CLOATacticalMissileProjectile.PassDamageData(self,damageData)
        local launcherbp = self:GetLauncher().Blueprint
        self.ChildDamageData = table.copy(self.DamageData)
        self.ChildDamageData.DamageAmount = launcherbp.SplitDamage.DamageAmount or 0
        self.ChildDamageData.DamageRadius = launcherbp.SplitDamage.DamageRadius or 1
    end,    
    
    OnImpact = function(self, targetType, targetEntity)
        local radius = self.DamageData.DamageRadius
        local pos = EntityGetPosition(self)
        local FriendlyFire = self.DamageData.DamageFriendly
        
        CreateLightParticle( self, -1, army, 3, 7, 'glow_03', 'ramp_fire_11' )
        
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        
        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            local rotation = RandomFloat(0,2*3.141592)
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius+3, radius+3, 300, 90, army)
        end
        
        -- if I collide with terrain dont split
        if targetType != 'Projectile' then
            self.Split = true
        end
        CLOATacticalMissileProjectile.OnImpact(self, targetType, targetEntity)
    end,   
    
    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.Split and (amount >= EntityGetHealth(self)) then
            self.Split = true
            local vx, vy, vz = ProjectileGetVelocity(self)
            local velocity = 7
            local ChildProjectileBP = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp'
            local angle = (2*3.141592) / self.NumChildMissiles
            local spreadMul = 0.5  -- Adjusts the width of the dispersal

            -- Launch projectiles at semi-random angles away from split location
            for i = 0, (self.NumChildMissiles - 1) do
                local xVec = vx + MathSin(i*angle) * spreadMul
                local yVec = vy + MathCos(i*angle) * spreadMul
                local zVec = vz + MathCos(i*angle) * spreadMul
                local proj = ProjectileCreateChildProjectile(self, ChildProjectileBP)
                ProjectileSetVelocity(proj, xVec,yVec,zVec)
                ProjectileSetVelocity(proj, velocity)
                proj.PassDamageData(proj, self.ChildDamageData)
            end
        end
        CLOATacticalMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
    end,

}
TypeClass = CIFMissileTactical03

