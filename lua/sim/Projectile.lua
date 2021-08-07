------------------------------------------------------------------
--  File     :  /lua/sim/Projectile.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  :  Base Projectile Definition
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local Explosion = import('/lua/defaultexplosions.lua')
local DefaultDamage = import('/lua/sim/defaultdamage.lua')
local Flare = import('/lua/defaultantiprojectile.lua').Flare

-- upvalued globals for performance
local DamageArea = _G.DamageArea
local Damage = _G.Damage

local TrashBag = _G.TrashBag
local TrashBagAdd = _G.TrashBag.Add 
local TrashBagDestroy = _G.TrashBag.Destroy

local ForkThread = _G.ForkThread
local GetTerrainType = _G.GetTerrainType
local GetSurfaceHeight = _G.GetSurfaceHeight

local EntityCategoryContains = EntityCategoryContains
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- upvalued moho functions for performance

local EntityMethods = _G.moho.entity_methods
local EntityGetBlueprint = EntityMethods.GetBlueprint
local EntityGetArmy = EntityMethods.GetArmy
local EntityDestroy = EntityMethods.Destroy
local EntityPlaySound = EntityMethods.PlaySound
local EntitySetHealth = EntityMethods.SetHealth
local EntitySetMaxHealth = EntityMethods.SetMaxHealth
local EntitySetAmbientSound = EntityMethods.SetAmbientSound
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetLauncher = ProjectileMethods.GetLauncher
local ProjectileSetNewTargetGround = ProjectileMethods.SetNewTargetGround
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget
local ProjectileSetLifetime = ProjectileMethods.SetLifetime

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

-- upvalued read-only values
local DoNotCollideCategories = categories.TORPEDO + categories.MISSILE + categories.DIRECTFIRE
local OnImpactDestroyCategories = categories.ANTIMISSILE * categories.ALLPROJECTILES

local DefaultTerrainTypeFxImpact = GetTerrainType(-1, -1).FxImpact

-- create the tracker table for units
local identifier = "Projectile"
local simModel = import("/mods/profiler/modules/sim/model.lua")
local tracker = simModel.Hooks[identifier] or { }
tracker.MohoFunctions = tracker.MohoFunctions or { }
tracker.Functions = tracker.Functions or { }
simModel.Hooks[identifier] = tracker

local ProfilerFunctions = {
    "ChangeDetonateBelowHeight",
    "ChangeMaxZigZag",
    "ChangeZigZagFrequency",
    "CreateChildProjectile",
    "GetCurrentSpeed",
    "GetCurrentTargetPosition",
    "GetLauncher",
    "GetTrackingTarget",
    "GetVelocity",
    "SetAcceleration",
    "SetBallisticAcceleration",
    "SetCollideEntity",
    "SetCollideSurface",
    "SetCollision",
    "SetDamage",
    "SetDestroyOnWater",
    "SetLifetime",
    "SetLocalAngularVelocity",
    "SetMaxSpeed",
    "SetNewTarget",
    "SetNewTargetGround",
    "SetScaleVelocity",
    "SetStayUpright",
    "SetTurnRate",
    "SetVelocity",
    "SetVelocityAlign",
    "SetVelocityRandomUpVector",
    "StayUnderwater",
    "TrackTarget",
}

for k, func in ProfilerFunctions do 
    local element = ProjectileMethods[func]
    if type(element) == "cfunction" then 

        local lK = func 

        -- hook the function for profiling
        local old = ProjectileMethods[lK]
        ProjectileMethods[lK] = function(...)
            tracker.MohoFunctions[lK] = tracker.MohoFunctions[lK] or 0
            tracker.MohoFunctions[lK] = tracker.MohoFunctions[lK] + 1

            -- call the old function
            return old(unpack(arg))
        end
    end
end

Projectile = Class(ProjectileMethods, Entity) {

    -- Do not call the base class __init and __post_init, we already have a c++ object
        __init = function(self, spec)

        -- PROFILER START
        if not tracker.Functions["__init"] then 
            tracker.Functions["__init"]  = 0 
        end
        tracker.Functions["__init"] = tracker.Functions["__init"] + 1
        -- PROFILER END

    end,

    -- Do not call the base class __init and __post_init, we already have a c++ object
        __post_init = function(self, spec)

        -- PROFILER START
        if not tracker.Functions["__post_init"] then 
            tracker.Functions["__post_init"]  = 0 
        end
        tracker.Functions["__post_init"] = tracker.Functions["__post_init"] + 1
        -- PROFILER END

    end,

    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    -- FxImpactAirUnit = false,
    -- FxImpactLand = false,
    -- FxImpactNone = false,
    -- FxImpactProp = false,
    -- FxImpactShield = false,
    -- FxImpactWater = false,
    -- FxImpactUnderWater = false,
    -- FxImpactUnit = false,
    -- FxImpactProjectile = false,
    -- FxImpactProjectileUnderWater = false,
    -- FxOnKilled = false,

    -- FxAirUnitHitScale = 1,
    -- FxLandHitScale = 1,
    -- FxNoneHitScale = 1,
    -- FxPropHitScale = 1,
    -- FxProjectileHitScale = 1,
    -- FxProjectileUnderWaterHitScale = 1,
    -- FxShieldHitScale = 1,
    -- FxUnderWaterHitScale = 0.25,
    -- FxUnitHitScale = 1,
    -- FxWaterHitScale = 1,
    -- FxOnKilledScale = 1,

    -- this is always false
    -- FxImpactLandScorch = false,
    -- FxImpactLandScorchScale = 1.0,

    -- performance-wise this function just hurts and is not needed
    ForkThread = function(self, fn, ...)

        -- PROFILER START
        if not tracker.Functions["ForkThread"] then 
            tracker.Functions["ForkThread"]  = 0 
        end
        tracker.Functions["ForkThread"] = tracker.Functions["ForkThread"] + 1
        -- PROFILER END


        LOG("Projectile forkthread called at: " .. repr(debug.getinfo(2)))

        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            TrashBagAdd(self.Trash, thread)
            return thread
        else
            return nil
        end
    end,

    -- called by engine when made
        OnCreate = function(self, inWater)

        -- PROFILER START
        if not tracker.Functions["OnCreate"] then 
            tracker.Functions["OnCreate"]  = 0 
        end
        tracker.Functions["OnCreate"] = tracker.Functions["OnCreate"] + 1
        -- PROFILER END


        -- get blueprint into local scope for performance
        local blueprint = EntityGetBlueprint(self)

        -- store original blueprint for functions that need it
        self.Blueprint = blueprint
        self.BlueprintAudio = blueprint.Audio

        -- store values for direct access to prevent hashing / engine calls
        self.Army = EntityGetArmy(self)
        self.Launcher = ProjectileGetLauncher(self)

        -- used when colliding or taking damage, cached for efficiency
        self.BlueprintDoNotCollideList = blueprint.DoNotCollideList
        self.BlueprintDefenseMaxHealth = blueprint.Defense.MaxHealth or 1

        -- allocate damage data
        self.DamageData = { }

        -- set original health
        EntitySetMaxHealth(self, self.BlueprintDefenseMaxHealth)
        EntitySetHealth(self, self, self.BlueprintDefenseMaxHealth) -- 2nd self is instigator

        -- update target if we track
        if blueprint.Physics.TrackTargetGround then
            local pos = ProjectileGetCurrentTargetPosition(self)
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            ProjectileSetNewTargetGround(self, pos)
        end

        -- prepare trashbag
        self.Trash = TrashBag()
    end,

    -- receive damage data as deep-copy
    -- PERFORMANCE-TODO: Does this need to be a deep-copy?
        PassDamageData = function(self, DamageData)

        -- PROFILER START
        if not tracker.Functions["PassDamageData"] then 
            tracker.Functions["PassDamageData"]  = 0 
        end
        tracker.Functions["PassDamageData"] = tracker.Functions["PassDamageData"] + 1
        -- PROFILER END

        -- only copy data that is present
        local SelfDamageData = self.DamageData
        for k, value in DamageData do 
            SelfDamageData[k] = value
        end

        -- original approach to copying data
        -- self.DamageData.DamageRadius = DamageData.DamageRadius
        -- self.DamageData.DamageAmount = DamageData.DamageAmount
        -- self.DamageData.DamageType = DamageData.DamageType
        -- self.DamageData.DamageFriendly = DamageData.DamageFriendly
        -- self.DamageData.CollideFriendly = DamageData.CollideFriendly
        -- self.DamageData.DoTTime = DamageData.DoTTime
        -- self.DamageData.DoTPulses = DamageData.DoTPulses
        -- self.DamageData.MetaImpactAmount = DamageData.MetaImpactAmount
        -- self.DamageData.MetaImpactRadius = DamageData.MetaImpactRadius
        -- self.DamageData.Buffs = DamageData.Buffs
        -- self.DamageData.ArtilleryShieldBlocks = DamageData.ArtilleryShieldBlocks

        -- additional copy
        self.CollideFriendly = SelfDamageData.CollideFriendly
    end,

        DoDamage = function(self, instigator, DamageData, targetEntity)

        -- PROFILER START
        if not tracker.Functions["DoDamage"] then 
            tracker.Functions["DoDamage"]  = 0 
        end
        tracker.Functions["DoDamage"] = tracker.Functions["DoDamage"] + 1
        -- PROFILER END

        local damage = DamageData.DamageAmount
        if damage and damage > 0 then
            local position = EntityGetPosition(self)
            local radius = DamageData.DamageRadius
            if radius and radius > 0 then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    DamageArea(instigator, position, radius, damage, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, position, radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, position, targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.AreaDoTThread, instigator, position, DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), radius, damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            -- ONLY DO DAMAGE IF THERE IS DAMAGE DATA.  SOME PROJECTILE DO NOT DO DAMAGE WHEN THEY IMPACT.
            elseif DamageData.DamageAmount and targetEntity then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    Damage(instigator, position, targetEntity, DamageData.DamageAmount, DamageData.DamageType)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, position, radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, position, targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.UnitDoTThread, instigator, targetEntity, DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            end
        end
        if self.InnerRing and self.OuterRing then
            local pos = self:GetPosition()
            self.InnerRing:DoNukeDamage(self.Launcher, pos, self.Brain, self.Army, DamageData.DamageType or 'Nuke')
            self.OuterRing:DoNukeDamage(self.Launcher, pos, self.Brain, self.Army, DamageData.DamageType or 'Nuke')
        end
    end,

        OnCollisionCheck = function(self, other)

        -- PROFILER START
        if not tracker.Functions["OnCollisionCheck"] then 
            tracker.Functions["OnCollisionCheck"]  = 0 
        end
        tracker.Functions["OnCollisionCheck"] = tracker.Functions["OnCollisionCheck"] + 1
        -- PROFILER END


        -- if we return false the thing hitting us has no idea that it came into contact with us
        if self.Army == other.Army then return false end

        -- pass the default do-not-collide categories
        if EntityCategoryContains(DoNotCollideCategories, self) and EntityCategoryContains(DoNotCollideCategories, other) then
            return false
        end

        -- if it should only hit a specific target and we're not the one being tracked
        if other.Blueprint.Physics.HitAssignedTarget and ProjectileGetTrackingTarget(other) ~= self then
            return false
        end

        -- check for specific do-not-collide entities, such as for strategic missiles not hitting air
        for _, p in {{self, other}, {other, self}} do
            local dnc = p[1].BlueprintDoNotCollideList
            if dnc then
                for _, v in dnc do
                    if EntityCategoryContains(categories[v], p[2]) then
                        return false
                    end
                end
            end
        end

        return true
    end,

    -- called when a projectile receives damage
        OnDamage = function(self, instigator, amount, vector, damageType)

        -- PROFILER START
        if not tracker.Functions["OnDamage"] then 
            tracker.Functions["OnDamage"]  = 0 
        end
        tracker.Functions["OnDamage"] = tracker.Functions["OnDamage"] + 1
        -- PROFILER END

        if self.BlueprintDefenseMaxHealth then
            self:DoTakeDamage(instigator, amount, vector, damageType)
        else
            self:OnKilled(instigator, damageType)
        end
    end,

    -- called when a projectile should be de-allocated
        OnDestroy = function(self)

        -- PROFILER START
        if not tracker.Functions["OnDestroy"] then 
            tracker.Functions["OnDestroy"]  = 0 
        end
        tracker.Functions["OnDestroy"] = tracker.Functions["OnDestroy"] + 1
        -- PROFILER END

        TrashBagDestroy(self.Trash)
    end,

    -- called when a projectile takes damage
        DoTakeDamage = function(self, instigator, amount, vector, damageType)

        -- PROFILER START
        if not tracker.Functions["DoTakeDamage"] then 
            tracker.Functions["DoTakeDamage"]  = 0 
        end
        tracker.Functions["DoTakeDamage"] = tracker.Functions["DoTakeDamage"] + 1
        -- PROFILER END

        -- Check for valid projectile
        if not self or self:BeenDestroyed() then
            return
        end

        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if health <= 0 then
            if damageType == 'Reclaimed' then
                EntityDestroy(self)
            else
                local excessDamageRatio = 0.0

                -- Calculate the excess damage amount
                local excess = health - amount
                local maxHealth = self.BlueprintDefenseMaxHealth
                if excess < 0 and maxHealth > 0 then
                    excessDamageRatio = -excess / maxHealth
                end
                self:OnKilled(instigator, damageType, excessDamageRatio)
            end
        end
    end,

        OnKilled = function(self, instigator, type, overkillRatio)

        -- PROFILER START
        if not tracker.Functions["OnKilled"] then 
            tracker.Functions["OnKilled"]  = 0 
        end
        tracker.Functions["OnKilled"] = tracker.Functions["OnKilled"] + 1
        -- PROFILER END

        self.CreateImpactEffects(self, self.Army, self.FxOnKilled, self.FxOnKilledScale)
        EntityDestroy(self)
    end,

        DoMetaImpact = function(self, damageData)

        -- PROFILER START
        if not tracker.Functions["DoMetaImpact"] then 
            tracker.Functions["DoMetaImpact"]  = 0 
        end
        tracker.Functions["DoMetaImpact"] = tracker.Functions["DoMetaImpact"] + 1
        -- PROFILER END

        if damageData.MetaImpactRadius and damageData.MetaImpactAmount then
            local x, y, z = EntityGetPositionXYZ(self)
            y = GetSurfaceHeight(x, z)
            MetaImpact(self, { x, y, z }, damageData.MetaImpactRadius, damageData.MetaImpactAmount)
        end
    end,

        CreateImpactEffects = function(self, army, EffectTable, EffectScale)

        -- PROFILER START
        if not tracker.Functions["CreateImpactEffects"] then 
            tracker.Functions["CreateImpactEffects"]  = 0 
        end
        tracker.Functions["CreateImpactEffects"] = tracker.Functions["CreateImpactEffects"] + 1
        -- PROFILER END

        -- default values
        EffectScale = EffectScale or 1

        -- caching
        local fxImpactTrajectoryAligned = self.FxImpactTrajectoryAligned

        -- create the emitters
        local emit
        if EffectTable then 
            for _, v in EffectTable do

                -- construct emitter
                if fxImpactTrajectoryAligned then
                    emit = CreateEmitterAtBone(self, -2, army, v)
                else
                    emit = CreateEmitterAtEntity(self, army, v)
                end

                EmitterScaleEmitter(emit, EffectScale)
            end
        end
    end,

        CreateTerrainEffects = function(self, army, EffectTable, EffectScale)

        -- PROFILER START
        if not tracker.Functions["CreateTerrainEffects"] then 
            tracker.Functions["CreateTerrainEffects"]  = 0 
        end
        tracker.Functions["CreateTerrainEffects"] = tracker.Functions["CreateTerrainEffects"] + 1
        -- PROFILER END

        -- default values
        EffectScale = EffectScale or 1

        for _, v in EffectTable do
            local emit = CreateEmitterAtBone(self, -2, army, v)
            EmitterScaleEmitter(emit, EffectScale )
        end
    end,

        GetTerrainEffects = function(self, TargetType, ImpactEffectType)

        -- PROFILER START
        if not tracker.Functions["GetTerrainEffects"] then 
            tracker.Functions["GetTerrainEffects"]  = 0 
        end
        tracker.Functions["GetTerrainEffects"] = tracker.Functions["GetTerrainEffects"] + 1
        -- PROFILER END

        -- default value
        ImpactEffectType = ImpactEffectType or 'Default'

        -- get x / z position
        local x, y, z = EntityGetPositionXYZ(self)
    
        -- get terrain at that location and try and get some effects
        local TerrainType = GetTerrainType(x, z)
        local TerrainEffect = TerrainType.FXImpact[TargetType][ImpactEffectType] or DefaultTerrainTypeFxImpact[TargetType][ImpactEffectType] or { }
        return TerrainEffect
    end,

        OnCollisionCheckWeapon = function(self, firingWeapon)

        -- PROFILER START
        if not tracker.Functions["OnCollisionCheckWeapon"] then 
            tracker.Functions["OnCollisionCheckWeapon"]  = 0 
        end
        tracker.Functions["OnCollisionCheckWeapon"] = tracker.Functions["OnCollisionCheckWeapon"] + 1
        -- PROFILER END

        if not firingWeapon.CollideFriendly and self.Army == firingWeapon.unit.Army then
            return false
        end

        -- If this unit category is on the weapon's do-not-collide list, skip!
        local weaponBP = firingWeapon.Blueprint
        if weaponBP.DoNotCollideList then
            for k, v in weaponBP.DoNotCollideList do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end
        return true
    end,

    -- Create some cool explosions when we get destroyed
        OnImpact = function(self, targetType, targetEntity)

        -- PROFILER START
        if not tracker.Functions["OnImpact"] then 
            tracker.Functions["OnImpact"]  = 0 
        end
        tracker.Functions["OnImpact"] = tracker.Functions["OnImpact"] + 1
        -- PROFILER END

        
        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local army = self.Army
        local instigator = self.Launcher or self 
        local damageData = self.DamageData

        -- Do Damage
        self.DoDamage(self, instigator, damageData, targetEntity)

        -- Meta-Impact
        self.DoMetaImpact(self, damageData)

        -- Buffs (Stun, etc)
        self.DoUnitImpactBuffs(self, targetEntity)

        -- Possible 'target' values are:
        --  'Unit'
        --  'Terrain'
        --  'Water'
        --  'Air'
        --  'Prop'
        --  'Shield'
        --  'UnitAir'
        --  'UnderWater'
        --  'UnitUnderwater'
        --  'Projectile'
        --  'ProjectileUnderWater
        local ImpactEffects = false
        local ImpactEffectScale = 1
        local blueprint = self.Blueprint

        -- Sounds for all other impacts, ie: Impact<TargetTypeName>
        local blueprintAudio = self.BlueprintAudio
        local snd = blueprintAudio['Impact' .. targetType]
        if snd then
            EntityPlaySound(self, snd)
            -- Generic Impact Sound
        elseif blueprintAudio.Impact then
            EntityPlaySound(self, blueprintAudio.Impact)
        end

        -- ImpactEffects
        if targetType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif targetType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
        elseif targetType == 'Shield' then
            ImpactEffects = self.FxImpactShield
            ImpactEffectScale = self.FxShieldHitScale
        elseif targetType == 'Unit' then
            ImpactEffects = self.FxImpactUnit
            ImpactEffectScale = self.FxUnitHitScale
        elseif targetType == 'UnitAir' then
            ImpactEffects = self.FxImpactAirUnit
            ImpactEffectScale = self.FxAirUnitHitScale
        elseif targetType == 'Air' then
            ImpactEffects = self.FxImpactNone
            ImpactEffectScale = self.FxNoneHitScale
        elseif targetType == 'Projectile' then
            ImpactEffects = self.FxImpactProjectile
            ImpactEffectScale = self.FxProjectileHitScale
        elseif targetType == 'ProjectileUnderwater' then
            ImpactEffects = self.FxImpactProjectileUnderWater
            ImpactEffectScale = self.FxProjectileUnderWaterHitScale
        elseif targetType == 'Prop' then
            ImpactEffects = self.FxImpactProp
            ImpactEffectScale = self.FxPropHitScale
        elseif targetType == 'Underwater' or targetType == 'UnitUnderwater' then
            ImpactEffects = self.FxImpactUnderWater
            ImpactEffectScale = self.FxUnderWaterHitScale or 0.25
        else
            LOG('*ERROR: Projectile:OnImpact(): UNKNOWN TARGET TYPE ', repr(targetType))
        end

        -- default values
        ImpactEffects = ImpactEffects or { }
        ImpactEffectScale = ImpactEffectScale or 1

        local BlueprintDisplayImpactEffects = blueprint.Display.ImpactEffects
        local TerrainEffects = self.GetTerrainEffects(self, targetType, BlueprintDisplayImpactEffects.Type)
        self.CreateImpactEffects(self, army, ImpactEffects, ImpactEffectScale)
        self.CreateTerrainEffects(self, army, TerrainEffects, BlueprintDisplayImpactEffects.Scale or 1)

        local timeout = blueprint.Physics.ImpactTimeout
        if timeout and targetType == 'Terrain' then
            TrashBagAdd(self.Trash, ForkThread(self.ImpactTimeoutThread, self, timeout))
        else
            self.OnImpactDestroy(self, targetType, targetEntity)
        end
    end,

        OnImpactDestroy = function(self, targetType, targetEntity)

        -- PROFILER START
        if not tracker.Functions["OnImpactDestroy"] then 
            tracker.Functions["OnImpactDestroy"]  = 0 
        end
        tracker.Functions["OnImpactDestroy"] = tracker.Functions["OnImpactDestroy"] + 1
        -- PROFILER END

        local destroyOnImpact = self.DestroyOnImpact
        if destroyOnImpact or not targetEntity or
            (not destroyOnImpact and targetEntity and not EntityCategoryContains(OnImpactDestroyCategories, targetEntity)) then
            EntityDestroy(self)
        end
    end,

        ImpactTimeoutThread = function(self, seconds)

        -- PROFILER START
        if not tracker.Functions["ImpactTimeoutThread"] then 
            tracker.Functions["ImpactTimeoutThread"]  = 0 
        end
        tracker.Functions["ImpactTimeoutThread"] = tracker.Functions["ImpactTimeoutThread"] + 1
        -- PROFILER END

        WaitSeconds(seconds)
        EntityDestroy(self)
    end,

    -- When this projectile impacts with the target, do any buffs that have been passed to it.
        DoUnitImpactBuffs = function(self, target)

        -- PROFILER START
        if not tracker.Functions["DoUnitImpactBuffs"] then 
            tracker.Functions["DoUnitImpactBuffs"]  = 0 
        end
        tracker.Functions["DoUnitImpactBuffs"] = tracker.Functions["DoUnitImpactBuffs"] + 1
        -- PROFILER END

        local data = self.DamageData
        -- Check for buff
        if data.Buffs then
            -- Check for valid target
            for k, v in data.Buffs do
                if v.Add.OnImpact == true then
                    local radius = v.radius
                    if v.AppliedToTarget ~= true or (radius and radius > 0) then
                        target = self.Launcher
                    end
                    -- Check for target validity
                    if target and IsUnit(target) then
                        if radius and radius > 0 then
                            -- This is a radius buff
                            -- get the position of the projectile
                            target:AddBuff(v, self:GetPosition())
                        else
                            -- This is a single target buff
                            target:AddBuff(v)
                        end
                    end
                end
            end
        end
    end,

    -- this should never be called - use the actual function.
        GetCachePosition = function(self)

        -- PROFILER START
        if not tracker.Functions["GetCachePosition"] then 
            tracker.Functions["GetCachePosition"]  = 0 
        end
        tracker.Functions["GetCachePosition"] = tracker.Functions["GetCachePosition"] + 1
        -- PROFILER END

        return self:GetPosition()
    end,

    -- this should never be called - use the actual value.
        GetCollideFriendly = function(self)

        -- PROFILER START
        if not tracker.Functions["GetCollideFriendly"] then 
            tracker.Functions["GetCollideFriendly"]  = 0 
        end
        tracker.Functions["GetCollideFriendly"] = tracker.Functions["GetCollideFriendly"] + 1
        -- PROFILER END

        return self.CollideFriendly
    end,

    -- this should never be called - use the actual value.
        PassData = function(self, data)

        -- PROFILER START
        if not tracker.Functions["PassData"] then 
            tracker.Functions["PassData"]  = 0 
        end
        tracker.Functions["PassData"] = tracker.Functions["PassData"] + 1
        -- PROFILER END

        self.Data = data
    end,

    -- when the projectile exits the water
        OnExitWater = function(self)

        -- PROFILER START
        if not tracker.Functions["OnExitWater"] then 
            tracker.Functions["OnExitWater"]  = 0 
        end
        tracker.Functions["OnExitWater"] = tracker.Functions["OnExitWater"] + 1
        -- PROFILER END

        -- no projectile blueprint has this value set
        -- local bp = self.Blueprint.Audio.ExitWater
        -- if bp then
        --     self:PlaySound(bp)
        -- end
    end,

    -- when the projectile enters the water (think about torpedo bombers)
        OnEnterWater = function(self)

        -- PROFILER START
        if not tracker.Functions["OnEnterWater"] then 
            tracker.Functions["OnEnterWater"]  = 0 
        end
        tracker.Functions["OnEnterWater"] = tracker.Functions["OnEnterWater"] + 1
        -- PROFILER END

        local snd = self.BlueprintAudio.EnterWater
        if snd then
            self:PlaySound(snd)
        end
    end,

        AddFlare = function(self, tbl)

        -- PROFILER START
        if not tracker.Functions["AddFlare"] then 
            tracker.Functions["AddFlare"]  = 0 
        end
        tracker.Functions["AddFlare"] = tracker.Functions["AddFlare"] + 1
        -- PROFILER END

        if not tbl then return end
        if not tbl.Radius then return end
        self.MyFlare = Flare {
            Owner = self,
            Radius = tbl.Radius or 5,
            Category = tbl.Category or 'MISSILE',  -- We pass the category bp value along so that it actually has a function.
        }
        if tbl.Stack == true then -- Secondary flare hitboxes, one above, one below (Aeon TMD)
            self.MyUpperFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = tbl.OffsetMult,
                Category = tbl.Category or 'MISSILE',
            }
            self.MyLowerFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = -tbl.OffsetMult,
                Category = tbl.Category or 'MISSILE',
            }
            TrashBagAdd(self.Trash, self.MyUpperFlare)
            TrashBagAdd(self.Trash, self.MyLowerFlare)
        end

        TrashBagAdd(self.Trash, self.MyFlare)
    end,

        OnLostTarget = function(self)

        -- PROFILER START
        if not tracker.Functions["OnLostTarget"] then 
            tracker.Functions["OnLostTarget"]  = 0 
        end
        tracker.Functions["OnLostTarget"] = tracker.Functions["OnLostTarget"] + 1
        -- PROFILER END

        local physics = self.Blueprint.Physics
        if physics.TrackTarget then
            ProjectileSetLifetime(self, physics.OnLostTargetLifetime)
        end
    end,
}
