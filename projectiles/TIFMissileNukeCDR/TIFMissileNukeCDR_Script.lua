--
-- Terran CDR Nuke
--

local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke

-- globals as upvalues for performance 
local Damage = Damage
local DamageArea = DamageArea
local WaitSeconds = WaitSeconds
local EntityCategoryContains = EntityCategoryContains

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget

-- attach for CTRL + SHIFT F replacement

local OnImpactAeonTMD = categories.AEON * categories.PROJECTILE * categories.ANTIMISSILE * categories.TECH_TWO

TIFMissileNukeCDR = Class(TIFMissileNuke) {

    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},

    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        self.effectEntityPath = '/effects/Entities/UEFNukeEffectController02/UEFNukeEffectController02_proj.bp'
        self:LauncherCallbacks()
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        if EntityCategoryContains(OnImpactAeonTMD, TargetEntity) then
            EntityDestroy(self)
        else
            TIFMissileNuke.OnImpact(self, TargetType, TargetEntity)
        end
    end,

    -- Tactical nuke has different flight path
    MovementThread = function(self)
        local launcher = self.Launcher
        local army = self.Army
        local target = ProjectileGetTrackingTarget(self)

        self.CreateEffects(self, self.InitialEffects, army, 1)
        local waitTime
        ProjectileSetTurnRate(self, 8)
        WaitSeconds(0.3)
        self.CreateEffects(self, self.LaunchEffects, army, 1)
        self.CreateEffects(self, self.ThrustEffects, army, 1)
        while not EntityBeenDestroyed(self) do
            self:SetTurnRateByDist()
            WaitSeconds(waitTime)
        end
    end,

    DoDamage = function(self, instigator, DamageData, targetEntity)
        local nukeDamage = function(self, instigator, pos, brain, army, damageType)
            if self.TotalTime == 0 then
                DamageArea(instigator, pos, self.Radius, self.Damage, (damageType or 'Nuke'), true, true)
            end
        end

        -- TODO: ?, nukeDamage returns nil
        self.InnerRing.DoNukeDamage = nukeDamage
        self.OuterRing.DoNukeDamage = nukeDamage
        TIFMissileNuke.DoDamage(self, instigator, DamageData, targetEntity)
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > 50 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            ProjectileSetTurnRate(self, 20)
        elseif dist > 128 and dist <= 213 then
            -- Increase check intervals
            ProjectileSetTurnRate(self, 30)
            WaitSeconds(1.5)
            ProjectileSetTurnRate(self, 30)
        elseif dist > 43 and dist <= 107 then
            -- Further increase check intervals
            WaitSeconds(0.3)
            ProjectileSetTurnRate(self, 75)
        elseif dist > 0 and dist <= 43 then
            -- Further increase check intervals
            ProjectileSetTurnRate(self, 200)
            KillThread(self.MoveThread)
        end
    end,

    OnEnterWater = function(self)
        TIFMissileNuke.OnEnterWater(self)
        ProjectileSetDestroyOnWater(self, true)
    end,
}
TypeClass = TIFMissileNukeCDR
