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

local TrashBag = _G.TrashBag
local TrashBagAdd = _G.TrashBag.Add 
local TrashBagDestroy = _G.TrashBag.Destroy

local ForkThread = ForkThread

local GetSurfaceHeight = _G.GetSurfaceHeight

local EntityCategoryContains = EntityCategoryContains

-- upvalued moho functions for performance

local EntityMethods = _G.moho.entity_methods
local EntitySetHealth = EntityMethods.SetHealth
local EntitySetMaxHealth = EntityMethods.SetMaxHealth
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetNewTargetGround = ProjectileMethods.SetNewTargetGround
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget

-- upvalued read-only values
local DoNotCollideCategories = categories.TORPEDO + categories.MISSILE + categories.DIRECTFIRE

Projectile = Class(ProjectileMethods, Entity) {

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __init = function(self, spec)
    end,

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __post_init = function(self, spec)
    end,

    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    FxImpactAirUnit = {},
    FxImpactLand = {},
    FxImpactNone = {},
    FxImpactProp = {},
    FxImpactShield = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactUnit = {},
    FxImpactProjectile = {},
    FxImpactProjectileUnderWater = {},
    FxOnKilled = {},

    FxAirUnitHitScale = 1,
    FxLandHitScale = 1,
    FxNoneHitScale = 1,
    FxPropHitScale = 1,
    FxProjectileHitScale = 1,
    FxProjectileUnderWaterHitScale = 1,
    FxShieldHitScale = 1,
    FxUnderWaterHitScale = 0.25,
    FxUnitHitScale = 1,
    FxWaterHitScale = 1,
    FxOnKilledScale = 1,

    FxImpactLandScorch = false,
    FxImpactLandScorchScale = 1.0,

    -- performance-wise this function just hurts and is not needed
    ForkThread = function(self, fn, ...)
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

        -- get blueprint into local scope for performance
        local blueprint = self:GetBlueprint()

        -- store original blueprint for functions that need it
        self.Blueprint = blueprint

        -- store values for direct access to prevent hashing / engine calls
        self.Army = self:GetArmy()
        self.Launcher = self:GetLauncher()

        self.BlueprintDoNotCollideList = blueprint.DoNotCollideList
        self.BlueprintDefenseMaxHealth = blueprint.Defense.MaxHealth or 1

        local audio = blueprint.Audio
        self.BlueprintAudioExistLoop = audio.ExistLoop
        self.BlueprintAudioExitWater = audio.ExitWater
        self.BlueprintAudioEnterWater = audio.EnterWater

        local physics = blueprint.Physics
        self.BlueprintPhysicsHitAssignedTarget = physics.HitAssignedTarget
        self.BlueprintPhysicsTrackTargetGround = physics.TrackTargetGround
        self.BlueprintPhysicsOnLostTargetLifetime = physics.OnLostTargetLifetime

        -- allocate damage data
        self.DamageData = {
            DamageRadius = false,
            DamageAmount = false,
            DamageType = false,
            DamageFriendly = false,
            MetaImpactAmount = false,
            MetaImpactRadius = false,
        }

        -- set original health
        EntitySetMaxHealth(self, self.BlueprintDefenseMaxHealth)
        EntitySetHealth(self, self, self.BlueprintDefenseMaxHealth) -- 2nd self is instigator

        -- set ambient sound if available
        local ambientSound = self.BlueprintAudioExistLoop
        if ambientSound then
            self:SetAmbientSound(ambientSound, nil)
        end

        -- update target if we track
        if self.BlueprintPhysicsTrackTargetGround then
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
        local SelfDamageData = self.DamageData
        SelfDamageData.DamageRadius = DamageData.DamageRadius
        SelfDamageData.DamageAmount = DamageData.DamageAmount
        SelfDamageData.DamageType = DamageData.DamageType
        SelfDamageData.DamageFriendly = DamageData.DamageFriendly
        SelfDamageData.CollideFriendly = DamageData.CollideFriendly
        SelfDamageData.DoTTime = DamageData.DoTTime
        SelfDamageData.DoTPulses = DamageData.DoTPulses
        SelfDamageData.MetaImpactAmount = DamageData.MetaImpactAmount
        SelfDamageData.MetaImpactRadius = DamageData.MetaImpactRadius
        SelfDamageData.Buffs = DamageData.Buffs
        SelfDamageData.ArtilleryShieldBlocks = DamageData.ArtilleryShieldBlocks
        SelfDamageData.InitialDamageAmount = DamageData.InitialDamageAmount
        self.CollideFriendly = SelfDamageData.CollideFriendly
    end,

    DoDamage = function(self, instigator, DamageData, targetEntity)
        local damage = DamageData.DamageAmount
        if damage and damage > 0 then
            local radius = DamageData.DamageRadius
            if radius and radius > 0 then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    DamageArea(instigator, self:GetPosition(), radius, damage, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, self:GetPosition(), radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, self:GetPosition(), targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.AreaDoTThread, instigator, self:GetPosition(), DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), radius, damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            -- ONLY DO DAMAGE IF THERE IS DAMAGE DATA.  SOME PROJECTILE DO NOT DO DAMAGE WHEN THEY IMPACT.
            elseif DamageData.DamageAmount and targetEntity then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    Damage(instigator, self:GetPosition(), targetEntity, DamageData.DamageAmount, DamageData.DamageType)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, self:GetPosition(), radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, self:GetPosition(), targetEntity, initialDmg, DamageData.DamageType)
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
            local dnc = p[1].Blueprint.DoNotCollideList
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
        if self.BlueprintDefenseMaxHealth then
            self:DoTakeDamage(instigator, amount, vector, damageType)
        else
            self:OnKilled(instigator, damageType)
        end
    end,

    -- called when a projectile should be de-allocated
    OnDestroy = function(self)
        TrashBagDestroy(self.Trash)
    end,

    -- called when a projectile takes damage
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Check for valid projectile
        if not self or self:BeenDestroyed() then
            return
        end

        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if health <= 0 then
            if damageType == 'Reclaimed' then
                self:Destroy()
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
        self:CreateImpactEffects(self.Army, self.FxOnKilled, self.FxOnKilledScale)
        self:Destroy()
    end,

    DoMetaImpact = function(self, damageData)
        if damageData.MetaImpactRadius and damageData.MetaImpactAmount then
            local pos = self:GetPosition()
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            MetaImpact(self, pos, damageData.MetaImpactRadius, damageData.MetaImpactAmount)
        end
    end,

    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for _, v in EffectTable do
            if self.FxImpactTrajectoryAligned then
                emit = CreateEmitterAtBone(self, -2, army, v)
            else
                emit = CreateEmitterAtEntity(self, army, v)
            end
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    CreateTerrainEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for _, v in EffectTable do
            emit = CreateEmitterAtBone(self, -2, army, v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    GetTerrainEffects = function(self, TargetType, ImpactEffectType)
        local pos = self:GetPosition()
        local TerrainType = nil

        if ImpactEffectType then
            TerrainType = GetTerrainType(pos.x, pos.z)
            if TerrainType.FXImpact[TargetType][ImpactEffectType] == nil then
                TerrainType = GetTerrainType(-1, -1)
            end
        else
            TerrainType = GetTerrainType(-1, -1)
            ImpactEffectType = 'Default'
        end

        return TerrainType.FXImpact[TargetType][ImpactEffectType] or {}
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)
        if not firingWeapon.CollideFriendly and self.Army == firingWeapon.unit.Army then
            return false
        end

        -- If this unit category is on the weapon's do-not-collide list, skip!
        local weaponBP = firingWeapon.Blueprint
        if weaponBP.DoNotCollideList then
            for k, v in pairs(weaponBP.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end
        return true
    end,

    -- Create some cool explosions when we get destroyed
    OnImpact = function(self, targetType, targetEntity)
        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local instigator = self:GetLauncher()
        if instigator == nil then
            instigator = self
        end
        local damageData = self.DamageData

        -- Do Damage
        self:DoDamage(instigator, damageData, targetEntity)

        -- Meta-Impact
        self:DoMetaImpact(damageData)

        -- Buffs (Stun, etc)
        self:DoUnitImpactBuffs(targetEntity)

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
        local ImpactEffects = {}
        local ImpactEffectScale = 1
        local bp = self.Blueprint
        local bpAud = bp.Audio

        -- Sounds for all other impacts, ie: Impact<TargetTypeName>
        local snd = bpAud['Impact'..targetType]
        if snd then
            self:PlaySound(snd)
            -- Generic Impact Sound
        elseif bpAud.Impact then
            self:PlaySound(bpAud.Impact)
        end

        -- ImpactEffects
        if targetType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif targetType == 'Underwater' or targetType == 'UnitUnderwater' then
            ImpactEffects = self.FxImpactUnderWater
            ImpactEffectScale = self.FxUnderWaterHitScale
        elseif targetType == 'Unit' then
            ImpactEffects = self.FxImpactUnit
            ImpactEffectScale = self.FxUnitHitScale
        elseif targetType == 'UnitAir' then
            ImpactEffects = self.FxImpactAirUnit
            ImpactEffectScale = self.FxAirUnitHitScale
        elseif targetType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
            if self.FxImpactLandScorch then
                Explosion.CreateRandomScorchSplatAtObject(self, self.FxImpactLandScorchScale, 150, 20, self.Army)
            end
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
        elseif targetType == 'Shield' then
            ImpactEffects = self.FxImpactShield
            ImpactEffectScale = self.FxShieldHitScale
        else
            LOG('*ERROR: Projectile:OnImpact(): UNKNOWN TARGET TYPE ', repr(targetType))
        end

        local TerrainEffects = self:GetTerrainEffects(targetType, bp.Display.ImpactEffects.Type)
        self:CreateImpactEffects(self.Army, ImpactEffects, ImpactEffectScale)
        self:CreateTerrainEffects(self.Army, TerrainEffects, bp.Display.ImpactEffects.Scale or 1)

        local timeout = bp.Physics.ImpactTimeout
        if timeout and targetType == 'Terrain' then
            TrashBagAdd(self.Trash, ForkThread(self.ImpactTimeoutThread, self, timeout))
        else
            self:OnImpactDestroy(targetType, targetEntity)
        end
    end,

    OnImpactDestroy = function(self, targetType, targetEntity)
        if self.DestroyOnImpact or not targetEntity or
            (not self.DestroyOnImpact and targetEntity and not EntityCategoryContains(categories.ANTIMISSILE * categories.ALLPROJECTILES, targetEntity)) then
            self:Destroy()
        end
    end,

    ImpactTimeoutThread = function(self, seconds)
        WaitSeconds(seconds)
        self:Destroy()
    end,

    -- When this projectile impacts with the target, do any buffs that have been passed to it.
    DoUnitImpactBuffs = function(self, target)
        local data = self.DamageData
        -- Check for buff
        if data.Buffs then
            -- Check for valid target
            for k, v in data.Buffs do
                if v.Add.OnImpact == true then
                    if v.AppliedToTarget ~= true or (v.Radius and v.Radius > 0) then
                        target = self:GetLauncher()
                    end
                    -- Check for target validity
                    if target and IsUnit(target) then
                        if v.Radius and v.Radius > 0 then
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
        return self:GetPosition()
    end,

    -- this should never be called - use the actual value.
    GetCollideFriendly = function(self)
        return self.CollideFriendly
    end,

    -- this should never be called - use the actual value.
    PassData = function(self, data)
        self.Data = data
    end,

    -- when the projectile exits the water
    OnExitWater = function(self)
        local bp = self.BlueprintAudioExitWater
        if bp then
            self:PlaySound(bp)
        end
    end,

    -- when the projectile enters the water (think about torpedo bombers)
    OnEnterWater = function(self)
        local bp = self.BlueprintAudioEnterWater
        if bp then
            self:PlaySound(bp)
        end
    end,

    AddFlare = function(self, tbl)
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
        if self.BlueprintPhysicsTrackTarget then
            self:SetLifetime(self.BlueprintPhysicsOnLostTargetLifetime or 0.5)
        end
    end,
}
