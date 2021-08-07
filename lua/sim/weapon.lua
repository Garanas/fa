-- ****************************************************************************
-- **
-- **  File     :  /lua/sim/Weapon.lua
-- **  Author(s):  John Comes
-- **
-- **  Summary  : The base weapon class for all weapons in the game.
-- **
-- **  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity
local NukeDamage = import('/lua/sim/NukeDamage.lua').NukeAOE
local Set = import('/lua/system/setutils.lua')

local ParseEntityCategoryProperly = import('/lua/sim/CategoryUtils.lua').ParseEntityCategoryProperly

-- Contains all possible priorities found inside (weapon) blueprint files. It is
-- cached once and allows for quick string -> category conversion.
local CacheAllDefaultPriorities = false

-- Finds unique priorities of all weapons of all units and pre-parses those. This 
-- function populates the 'CacheAllDefaultPriorities' defined above.
local function ParsePriorities()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    local finalPriorities = {}

    for _, id in idlist do
        local weapons = GetUnitBlueprintByName(id).Weapon

        for weaponNum, weapon in weapons or {} do
            for line, priority in weapon.TargetPriorities or {} do
                if not finalPriorities[priority] then
                    if string.find(priority, '%(') then
                        finalPriorities[priority] = ParseEntityCategoryProperly(priority)
                    else
                        finalPriorities[priority] = ParseEntityCategory(priority)
                    end
                end
            end
        end
    end

    return finalPriorities
end


-- create the tracker table for units
local identifier = "Weapon"
local simModel = import("/mods/profiler/modules/sim/model.lua")
local tracker = simModel.Hooks[identifier] or { }
tracker.MohoFunctions = tracker.MohoFunctions or { }
tracker.Functions = tracker.Functions or { }
simModel.Hooks[identifier] =  tracker

local ProfilerFunctions = { 
    "TransferTarget",
    "IsFireControl",
    "ChangeDamage",
    "CanFire",
    "ChangeMaxRadius",
    "BeenDestroyed",
    "ChangeMaxHeightDiff",
    "SetFireTargetLayerCaps",
    "CreateProjectile",
    "SetEnabled",
    "ChangeFiringTolerance",
    "SetTargetingPriorities",
    "GetCurrentTargetPos",
    "GetProjectileBlueprint",
    "SetTargetGround",
    "ResetTarget",
    "SetFireControl",
    "ChangeRateOfFire",
    "ChangeProjectileBlueprint",
    "GetFireClockPct",
    "WeaponHasTarget",
    "GetFiringRandomness",
    "SetFiringRandomness",
    "PlaySound",
    "SetTargetEntity",
    "GetBlueprint",
    "ChangeMinRadius",
    "FireWeapon",
    "GetCurrentTarget",
    "ChangeDamageRadius",
    "ChangeDamageType",
    "DoInstaHit",
}

local mohoTable = moho.weapon_methods 
for k, func in ProfilerFunctions do
    local element = mohoTable[func]
    if type(element) == "cfunction" then 

        local lK = func 

        -- hook the function for profiling
        local old = mohoTable[lK]
        mohoTable[lK] = function(...)
            tracker.MohoFunctions[lK] = tracker.MohoFunctions[lK] or 0
            tracker.MohoFunctions[lK] = tracker.MohoFunctions[lK] + 1

            -- call the old function
            return old(unpack(arg))
        end
    end
end


-- Contains all default weapon priorities that are defined in blueprint files. It is
-- cached when a weapon is made for the first time. The ID is defined in Blueprints.lua and
-- is essentially <unitblueprintid-weaponnumber>. As an example for the Zthuee: xsl0103-1.
local CacheAllWeaponPriorities = { } 

Weapon = Class(moho.weapon_methods) {
        __init = function(self, unit)

        -- PROFILER START
        if not tracker.Functions["__init"] then 
            tracker.Functions["__init"]  = 0 
        end
        tracker.Functions["__init"] = tracker.Functions["__init"] + 1
        -- PROFILER END

        self.unit = unit
    end,

        OnCreate = function(self)

        -- PROFILER START
        if not tracker.Functions["OnCreate"] then 
            tracker.Functions["OnCreate"]  = 0 
        end
        tracker.Functions["OnCreate"] = tracker.Functions["OnCreate"] + 1
        -- PROFILER END


        -- cache blueprint
        local blueprint = self:GetBlueprint()
        self.Blueprint = blueprint

        -- share trashbag with unit
        local unit = self.unit
        local trash = unit.Trash
        if not trash then 
            unit.Trash = TrashBag()
            trash = unit.Trash
        end

        self.Trash = trash 

        -- initialize valid targets (atlantis that is underwater can't use sams, for example)
        local layer = unit:GetCurrentLayer()
        self:SetValidTargetsForCurrentLayer(layer)

        -- initialize turret if we are one
        if blueprint.Turreted then
            self:SetupTurret()
        end

        -- set the default weapon priorities
        self:SetWeaponPriorities()

        -- initialize some state
        self.CollideFriendly = blueprint.CollideFriendly == true
        self.DisabledBuffs = { }
        self.DamageMod = 0
        self.DamageRadiusMod = 0
        self.NumTargets = 0

        -- check if we should start loaded
        local initStore = blueprint.InitialProjectileStorage
        if initStore and initStore > 0 then
            local maxProjectileStorage = blueprint.MaxProjectileStorage
            if maxProjectileStorage and maxProjectileStorage < initStore then
                initStore = maxProjectileStorage
            end
            local nuke = false
            if blueprint.NukeWeapon then
                nuke = true
            end

            -- add the ammo the next tick to prevent errors
            TrashAdd(self.Trash, ForkThread(self.AmmoThread, self, nuke, initStore))
        end
    end,

    -- Adds in ammo for tactical and strategical launchers - needs to be delayed 
    -- by one tick to ensure engine is ready 
        AmmoThread = function(self, nuke, amount)

        -- PROFILER START
        if not tracker.Functions["AmmoThread"] then 
            tracker.Functions["AmmoThread"]  = 0 
        end
        tracker.Functions["AmmoThread"] = tracker.Functions["AmmoThread"] + 1
        -- PROFILER END

        WaitSeconds(0.1)
        if nuke then
            self.unit:GiveNukeSiloAmmo(amount)
        else
            self.unit:GiveTacticalSiloAmmo(amount)
        end
    end,

    -- Initializes all the turrets of the weapon.
        SetupTurret = function(self)

        -- PROFILER START
        if not tracker.Functions["SetupTurret"] then 
            tracker.Functions["SetupTurret"]  = 0 
        end
        tracker.Functions["SetupTurret"] = tracker.Functions["SetupTurret"] + 1
        -- PROFILER END

        -- cache for performance
        local unit = self.unit
        local blueprint = self.Blueprint

        -- get turret bones
        local yawBone = blueprint.TurretBoneYaw
        local pitchBone = blueprint.TurretBonePitch
        local muzzleBone = blueprint.TurretBoneMuzzle
        local precedence = blueprint.AimControlPrecedence or 10

        -- check to make sure they're valid
        if not (unit.IsValidBone(unit, yawBone) and unit.IsValidBone(unit, pitchBone) and unit.IsValidBone(unit, muzzleBone)) then
            error('*ERROR: Bone aborting turret setup due to bone issues.', 2)
            return
        end

        -- dual-turret manipulator (UEF heavy gunship)
        self.BlueprintTurretDualManipulators = blueprint.TurretDualManipulators
        if self.BlueprintTurretDualManipulators then
                    -- these are optional, they default to nil
            local pitchBone2 = blueprint.TurretBoneDualPitch
            local muzzleBone2 = blueprint.TurretBoneDualMuzzle

            -- check if these are valid, assuming they exist
            if pitchBone2 and muzzleBone2 then
                if not (unit.IsValidBone(unit, pitchBone2) and unit.IsValidBone(unit, muzzleBone2)) then
                    error('*ERROR: Bone aborting turret setup due to pitch/muzzle bone2 issues.', 2)
                    return
                end
            end

            -- create controllers
            local aimControl = CreateAimController(self, 'Torso', yawBone)
            local aimRight = CreateAimController(self, 'Right', pitchBone, pitchBone, muzzleBone)
            local aimLeft = CreateAimController(self, 'Left', pitchBone2, pitchBone2, muzzleBone2)
            aimControl:SetPrecedence(precedence)
            aimRight:SetPrecedence(precedence)
            aimLeft:SetPrecedence(precedence)

            self:SetFireControl('Right')

            -- clean up controllers
            self.Trash:Add(aimControl)
            self.Trash:Add(aimRight)
            self.Trash:Add(aimLeft)

            -- store in self for later reference
            self.AimControl = aimControl
            self.AimRight = aimRight 
            self.AimLeft = aimLeft

        -- single-turret manipulator (essentially all the turrets in the game)
        else
            -- create controller
            local aimControl = CreateAimController(self, 'Default', yawBone, pitchBone, muzzleBone)
            aimControl:SetPrecedence(precedence)

            -- clean up controllers
            self.Trash:Add(aimControl)

            -- store in self for later reference
            self.AimControl = aimControl

            
            -- check if racks need to follow turret
            if blueprint.RackSlavedToTurret then 

                -- check if we have any rack bones
                local rackBones = blueprint.RackBones
                if rackBones[1] then
                    for k, v in rackBones do
                        if v.RackBone ~= pitchBone then
                            -- create slaver
                            local slaver = CreateSlaver(self.unit, v.RackBone, pitchBone)
                            slaver:SetPrecedence(precedence-1)

                            -- clean up slaver
                            self.Trash:Add(slaver)
                        end
                    end
                end
            end
        end

        -- structures do not reset pose
        if EntityCategoryContains(categories.STRUCTURE, self.unit) then
            self.AimControl:SetResetPoseTime(9999999)
        end

        -- initialize yaw values
        local turretYaw = blueprint.TurretYaw
        local turretYawRange = blueprint.TurretYawRange
        local turretyawmin = turretYaw - turretYawRange
        local turretyawmax = turretYaw + turretYawRange

        local turretyawspeed = blueprint.TurretYawSpeed

        -- initialize pitch values
        local turretPitch = blueprint.TurretPitch
        local turretPitchRange = blueprint.TurretPitchRange

        local turretpitchmin = turretPitch - turretPitchRange
        local turretpitchmax = turretPitch + turretPitchRange
        local turretpitchspeed = blueprint.TurretPitchSpeed

        -- set firing arcs
        self.AimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
        if self.BlueprintTurretDualManipulators then 
            self.AimRight:SetFiringArc(turretyawmin/12, turretyawmax/12, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            self.AimLeft:SetFiringArc(turretyawmin/12, turretyawmax/12, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
        end

        -- store in self for later reference
        self.TurretYawMin = turretyawmin
        self.TurretYawMax = turretyawmax
        self.TurretYawSpeed = turretyawspeed

        self.TurretPitchMin = turretpitchmin
        self.TurretPitchMax = turretpitchmax
        self.TurretPitchSpeed = turretpitchspeed
    end,

    -- Enables or disables the aim controller
        AimManipulatorSetEnabled = function(self, enabled)

        -- PROFILER START
        if not tracker.Functions["AimManipulatorSetEnabled"] then 
            tracker.Functions["AimManipulatorSetEnabled"]  = 0 
        end
        tracker.Functions["AimManipulatorSetEnabled"] = tracker.Functions["AimManipulatorSetEnabled"] + 1
        -- PROFILER END

        if self.AimControl then
            self.AimControl:SetEnabled(enabled)
        end
    end,

    -- Do not use this function. Instead, access the underlying value directly.
        GetAimManipulator = function(self)

        -- PROFILER START
        if not tracker.Functions["GetAimManipulator"] then 
            tracker.Functions["GetAimManipulator"]  = 0 
        end
        tracker.Functions["GetAimManipulator"] = tracker.Functions["GetAimManipulator"] + 1
        -- PROFILER END

        return self.AimControl
    end,

    -- Sets the turret yaw speed.
        SetTurretYawSpeed = function(self, speed)

        -- PROFILER START
        if not tracker.Functions["SetTurretYawSpeed"] then 
            tracker.Functions["SetTurretYawSpeed"]  = 0 
        end
        tracker.Functions["SetTurretYawSpeed"] = tracker.Functions["SetTurretYawSpeed"] + 1
        -- PROFILER END

        local aimControl = self.AimControl
        if aimControl then
            self.TurretYawSpeed = speed
            aimControl:SetFiringArc(self.TurretYawMin, self.TurretYawMax, speed, self.TurretPitchMin, self.TurretPitchMax, self.TurretPitchSpeed)
        end
    end,

    -- Sets the turret pitch speed.
        SetTurretPitchSpeed = function(self, speed)

        -- PROFILER START
        if not tracker.Functions["SetTurretPitchSpeed"] then 
            tracker.Functions["SetTurretPitchSpeed"]  = 0 
        end
        tracker.Functions["SetTurretPitchSpeed"] = tracker.Functions["SetTurretPitchSpeed"] + 1
        -- PROFILER END

        local aimControl = self.AimControl
        if aimControl then
            self.TurretPitchSpeed = speed
            aimControl:SetFiringArc(self.TurretYawMin, self.TurretYawMax, self.TurretYawSpeed, self.TurretPitchMin, self.TurretPitchMax, speed)
        end
    end,

    -- Do not use this function. Use self.TurretYawMin and self.TurretYawMax instead.
        GetTurretYawMinMax = function(self)

        -- PROFILER START
        if not tracker.Functions["GetTurretYawMinMax"] then 
            tracker.Functions["GetTurretYawMinMax"]  = 0 
        end
        tracker.Functions["GetTurretYawMinMax"] = tracker.Functions["GetTurretYawMinMax"] + 1
        -- PROFILER END

        local bp = self.Blueprint
        local turretyawmin = bp.TurretYaw - bp.TurretYawRange
        local turretyawmax = bp.TurretYaw + bp.TurretYawRange
        return turretyawmin, turretyawmax
    end,

    -- Do not use this function. Use self.TurretYawSpeed instead.
        GetTurretYawSpeed = function(self)

        -- PROFILER START
        if not tracker.Functions["GetTurretYawSpeed"] then 
            tracker.Functions["GetTurretYawSpeed"]  = 0 
        end
        tracker.Functions["GetTurretYawSpeed"] = tracker.Functions["GetTurretYawSpeed"] + 1
        -- PROFILER END

        return self.Blueprint.TurretYawSpeed
    end,

    -- Do not use this function. Use self.TurretPitchMin and self.TurretPitchMax instead.
        GetTurretPitchMinMax = function(self)

        -- PROFILER START
        if not tracker.Functions["GetTurretPitchMinMax"] then 
            tracker.Functions["GetTurretPitchMinMax"]  = 0 
        end
        tracker.Functions["GetTurretPitchMinMax"] = tracker.Functions["GetTurretPitchMinMax"] + 1
        -- PROFILER END

        local bp = self.Blueprint
        local turretpitchmin = bp.TurretPitch - bp.TurretPitchRange
        local turretpitchmax = bp.TurretPitch + bp.TurretPitchRange
        return turretpitchmin, turretpitchmax
    end,

    -- Do not use this function. Use self.TurretPitchSpeed instead.
        GetTurretPitchSpeed = function(self)

        -- PROFILER START
        if not tracker.Functions["GetTurretPitchSpeed"] then 
            tracker.Functions["GetTurretPitchSpeed"]  = 0 
        end
        tracker.Functions["GetTurretPitchSpeed"] = tracker.Functions["GetTurretPitchSpeed"] + 1
        -- PROFILER END

        return self.Blueprint.TurretPitchSpeed
    end,

    -- Called when the weapon is firing.
        OnFire = function(self)

        -- PROFILER START
        if not tracker.Functions["OnFire"] then 
            tracker.Functions["OnFire"]  = 0 
        end
        tracker.Functions["OnFire"] = tracker.Functions["OnFire"] + 1
        -- PROFILER END

        self:PlayWeaponSound('Fire')
        self:DoOnFireBuffs()
    end,

    -- Called when the weapon is enabled. Useful for unpacking / packing the weapon.
        OnEnableWeapon = function(self)

        -- PROFILER START
        if not tracker.Functions["OnEnableWeapon"] then 
            tracker.Functions["OnEnableWeapon"]  = 0 
        end
        tracker.Functions["OnEnableWeapon"] = tracker.Functions["OnEnableWeapon"] + 1
        -- PROFILER END

    end,

    -- Called when the weapon gains a target.
        OnGotTarget = function(self)

        -- PROFILER START
        if not tracker.Functions["OnGotTarget"] then 
            tracker.Functions["OnGotTarget"]  = 0 
        end
        tracker.Functions["OnGotTarget"] = tracker.Functions["OnGotTarget"] + 1
        -- PROFILER END

        if self.DisabledFiringBones and self.unit.Animator then
            for key, value in self.DisabledFiringBones do
                self.unit.Animator:SetBoneEnabled(value, false)
            end
        end
        self.NumTargets = self.NumTargets + 1
    end,

    -- Called when the weapon loses a target.
        OnLostTarget = function(self)

        -- PROFILER START
        if not tracker.Functions["OnLostTarget"] then 
            tracker.Functions["OnLostTarget"]  = 0 
        end
        tracker.Functions["OnLostTarget"] = tracker.Functions["OnLostTarget"] + 1
        -- PROFILER END

        if self.DisabledFiringBones and self.unit.Animator then
            for key, value in self.DisabledFiringBones do
                self.unit.Animator:SetBoneEnabled(value, true)
            end
        end

        self.NumTargets = self.NumTargets - 1
        if self.NumTargets < 0 then
            self.NumTargets = 0
        end
    end,

    -- Called when the weapon is tracking a target.
        OnStartTracking = function(self, label)

        -- PROFILER START
        if not tracker.Functions["OnStartTracking"] then 
            tracker.Functions["OnStartTracking"]  = 0 
        end
        tracker.Functions["OnStartTracking"] = tracker.Functions["OnStartTracking"] + 1
        -- PROFILER END

        self:PlayWeaponSound('BarrelStart')
        self:PlayWeaponAmbientSound('BarrelLoop')
    end,

    -- Called when the weapon has stopped tracking a target.
        OnStopTracking = function(self, label)

        -- PROFILER START
        if not tracker.Functions["OnStopTracking"] then 
            tracker.Functions["OnStopTracking"]  = 0 
        end
        tracker.Functions["OnStopTracking"] = tracker.Functions["OnStopTracking"] + 1
        -- PROFILER END

        self:PlayWeaponSound('BarrelStop')
        self:StopWeaponAmbientSound('BarrelLoop')
        if EntityCategoryContains(categories.STRUCTURE, self.unit) then
            self.AimControl:SetResetPoseTime(9999999)
        end

    end,

    -- Plays a weapon sound if available.
        PlayWeaponSound = function(self, sound)

        -- PROFILER START
        if not tracker.Functions["PlayWeaponSound"] then 
            tracker.Functions["PlayWeaponSound"]  = 0 
        end
        tracker.Functions["PlayWeaponSound"] = tracker.Functions["PlayWeaponSound"] + 1
        -- PROFILER END

        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        self:PlaySound(bp.Audio[sound])
    end,

    -- Plays an ambient weapon sound if available. This is commonly used for (uef) turrets.
        PlayWeaponAmbientSound = function(self, sound)

        -- PROFILER START
        if not tracker.Functions["PlayWeaponAmbientSound"] then 
            tracker.Functions["PlayWeaponAmbientSound"]  = 0 
        end
        tracker.Functions["PlayWeaponAmbientSound"] = tracker.Functions["PlayWeaponAmbientSound"] + 1
        -- PROFILER END

        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        if not self.AmbientSounds then
            self.AmbientSounds = {}
        end
        if not self.AmbientSounds[sound] then

            -- why does this make a new entity?
            local sndEnt = Entity {}
            self.AmbientSounds[sound] = sndEnt
            self.unit.Trash:Add(sndEnt)
            sndEnt:AttachTo(self.unit,-1)
        end
        self.AmbientSounds[sound]:SetAmbientSound(bp.Audio[sound], nil)
    end,

    -- Stops playing an ambient weapon sound if available. This is commonly used for (uef) turrets.
        StopWeaponAmbientSound = function(self, sound)

        -- PROFILER START
        if not tracker.Functions["StopWeaponAmbientSound"] then 
            tracker.Functions["StopWeaponAmbientSound"]  = 0 
        end
        tracker.Functions["StopWeaponAmbientSound"] = tracker.Functions["StopWeaponAmbientSound"] + 1
        -- PROFILER END

        if not self.AmbientSounds then return end
        if not self.AmbientSounds[sound] then return end
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        self.AmbientSounds[sound]:Destroy()
        self.AmbientSounds[sound] = nil
    end,

    -- Called by the unit when it is trying to move. Useful for weapons that need to pack / unpack
        OnMotionHorzEventChange = function(self, new, old)

        -- PROFILER START
        if not tracker.Functions["OnMotionHorzEventChange"] then 
            tracker.Functions["OnMotionHorzEventChange"]  = 0 
        end
        tracker.Functions["OnMotionHorzEventChange"] = tracker.Functions["OnMotionHorzEventChange"] + 1
        -- PROFILER END

    end,

    -- Initializes the damage table by copying values from the weapon.
        GetDamageTableInternal = function(self)

        -- PROFILER START
        if not tracker.Functions["GetDamageTableInternal"] then 
            tracker.Functions["GetDamageTableInternal"]  = 0 
        end
        tracker.Functions["GetDamageTableInternal"] = tracker.Functions["GetDamageTableInternal"] + 1
        -- PROFILER END

        local weaponBlueprint = self.Blueprint
        local damageTable = {}
        damageTable.InitialDamageAmount = weaponBlueprint.InitialDamage or 0
        damageTable.DamageRadius = weaponBlueprint.DamageRadius + (self.DamageRadiusMod or 0)
        damageTable.DamageAmount = weaponBlueprint.Damage + (self.DamageMod or 0)
        damageTable.DamageType = weaponBlueprint.DamageType
        damageTable.DamageFriendly = weaponBlueprint.DamageFriendly
        if damageTable.DamageFriendly == nil then
            damageTable.DamageFriendly = true
        end
        damageTable.CollideFriendly = weaponBlueprint.CollideFriendly or false
        damageTable.DoTTime = weaponBlueprint.DoTTime
        damageTable.DoTPulses = weaponBlueprint.DoTPulses
        damageTable.MetaImpactAmount = weaponBlueprint.MetaImpactAmount
        damageTable.MetaImpactRadius = weaponBlueprint.MetaImpactRadius
        damageTable.ArtilleryShieldBlocks = weaponBlueprint.ArtilleryShieldBlocks

        -- Add buff
        damageTable.Buffs = {}
        if weaponBlueprint.Buffs ~= nil then
            for k, v in weaponBlueprint.Buffs do
                if not self.DisabledBuffs[v.BuffType] then
                    damageTable.Buffs[k] = v
                end
            end
        end

        return damageTable
    end,

    damageTableCache = false,
        GetDamageTable = function(self)

        -- PROFILER START
        if not tracker.Functions["GetDamageTable"] then 
            tracker.Functions["GetDamageTable"]  = 0 
        end
        tracker.Functions["GetDamageTable"] = tracker.Functions["GetDamageTable"] + 1
        -- PROFILER END

        if not self.damageTableCache then self.damageTableCache = self:GetDamageTableInternal() end
        return self.damageTableCache
    end,

    -- Creates a projectile for the weapon.
        CreateProjectileForWeapon = function(self, bone)

        -- PROFILER START
        if not tracker.Functions["CreateProjectileForWeapon"] then 
            tracker.Functions["CreateProjectileForWeapon"]  = 0 
        end
        tracker.Functions["CreateProjectileForWeapon"] = tracker.Functions["CreateProjectileForWeapon"] + 1
        -- PROFILER END

        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            local bp = self.Blueprint

            if bp.NukeOuterRingDamage and bp.NukeOuterRingRadius and bp.NukeOuterRingTicks and bp.NukeOuterRingTotalTime and
                bp.NukeInnerRingDamage and bp.NukeInnerRingRadius and bp.NukeInnerRingTicks and bp.NukeInnerRingTotalTime then
                proj.InnerRing = NukeDamage()
                proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks, bp.NukeInnerRingTotalTime)
                proj.OuterRing = NukeDamage()
                proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks, bp.NukeOuterRingTotalTime)

                -- Need to store these three for later, in case the missile lands after the launcher dies
                proj.Launcher = self.unit
                proj.Army = self.unit.Army
                proj.Brain = self.unit:GetAIBrain()
            end
        end
        return proj
    end,

    -- Changes the valid targets when a layer is changed. For example: sams lose all target for atlantis when it dives
        SetValidTargetsForCurrentLayer = function(self, newLayer)

        -- PROFILER START
        if not tracker.Functions["SetValidTargetsForCurrentLayer"] then 
            tracker.Functions["SetValidTargetsForCurrentLayer"]  = 0 
        end
        tracker.Functions["SetValidTargetsForCurrentLayer"] = tracker.Functions["SetValidTargetsForCurrentLayer"] + 1
        -- PROFILER END

        -- LOG('SetValidTargetsForCurrentLayer, layer = ', newLayer)
        local weaponBlueprint = self.Blueprint
        if weaponBlueprint.FireTargetLayerCapsTable then
            if weaponBlueprint.FireTargetLayerCapsTable[newLayer] then
                -- LOG('Setting Target Layer Caps to ', weaponBlueprint.FireTargetLayerCapsTable[newLayer])
                self:SetFireTargetLayerCaps(weaponBlueprint.FireTargetLayerCapsTable[newLayer])
            else
                -- LOG('Setting Target Layer Caps to None')
                self:SetFireTargetLayerCaps('None')
            end
        end
    end,

    -- Called when the weapon is destroyed. Typically the trash bag is emptied here, but we share that with the unit.
        OnDestroy = function(self)

        -- PROFILER START
        if not tracker.Functions["OnDestroy"] then 
            tracker.Functions["OnDestroy"]  = 0 
        end
        tracker.Functions["OnDestroy"] = tracker.Functions["OnDestroy"] + 1
        -- PROFILER END

    end,

    -- Sets the priorities of the weapon.
        SetWeaponPriorities = function(self, priTable)

        -- PROFILER START
        if not tracker.Functions["SetWeaponPriorities"] then 
            tracker.Functions["SetWeaponPriorities"]  = 0 
        end
        tracker.Functions["SetWeaponPriorities"] = tracker.Functions["SetWeaponPriorities"] + 1
        -- PROFILER END


        -- if we're here for the first time - cache the priorities we find in all weapon files
        if not CacheAllDefaultPriorities then
            CacheAllDefaultPriorities = ParsePriorities()
        end
        
        -- the 2nd argument is nil if we're initializing the weapon
        if not priTable then

            -- find our weapon id and see if we did this weapon before
            local blueprint = self.Blueprint 
            local weaponId = blueprint.BlueprintId
            local priorities = CacheAllWeaponPriorities[weaponId]

            -- if we have not do this weapon before then do it and cache it
            if not priorities then 
                local targetPriorities = blueprint.TargetPriorities
                -- not all weapons have target priorities defined
                if targetPriorities then
                    local prioritiesCount = 0
                    priorities = { }

                    -- for each category
                    for k, v in targetPriorities do

                        -- if we have this category cached then add it
                        if CacheAllDefaultPriorities[v] then
                            prioritiesCount = prioritiesCount + 1
                            priorities[prioritiesCount] = CacheAllDefaultPriorities[v]

                        -- otherwise parse it and add it to the category cache
                        else
                            if string.find(v, '%(') then
                                CacheAllDefaultPriorities[v] = ParseEntityCategoryProperly(v)

                                prioritiesCount = prioritiesCount + 1
                                priorities[prioritiesCount] = CacheAllDefaultPriorities[v]
                            else
                                CacheAllDefaultPriorities[v] = ParseEntityCategory(v)

                                prioritiesCount = prioritiesCount + 1
                                priorities[prioritiesCount] = CacheAllDefaultPriorities[v]
                            end
                        end
                    end

                    -- store the resulting table
                    CacheAllWeaponPriorities[weaponId] = priorities
                end
            end

            -- set weapon priorities. Note that if a weapon / unit doesn't have the table then it remains nil
            if priorities then 
                self:SetTargetingPriorities(priorities)
            end
        else
            if type(priTable[1]) == 'string' then
                local priorityTable = {}
                for k, v in priTable do
                    table.insert(priorityTable, ParseEntityCategory(v))
                end
                self:SetTargetingPriorities(priorityTable)
            else
                self:SetTargetingPriorities(priTable)
            end
        end
    end,

    -- Checks whether the weapon uses energy. 
        WeaponUsesEnergy = function(self)

        -- PROFILER START
        if not tracker.Functions["WeaponUsesEnergy"] then 
            tracker.Functions["WeaponUsesEnergy"]  = 0 
        end
        tracker.Functions["WeaponUsesEnergy"] = tracker.Functions["WeaponUsesEnergy"] + 1
        -- PROFILER END

        local bp = self.Blueprint
        if bp.EnergyRequired and bp.EnergyRequired > 0 then
            return true
        end
        return false
    end,

    -- Calls the global forkthread, adding self as the 2nd argument. Do not use - instead call
    -- the global forkthread and add to the weapon trashbag.
        ForkThread = function(self, fn, ...)

        -- PROFILER START
        if not tracker.Functions["ForkThread"] then 
            tracker.Functions["ForkThread"]  = 0 
        end
        tracker.Functions["ForkThread"] = tracker.Functions["ForkThread"] + 1
        -- PROFILER END

        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.unit.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    -- Called when a unit gains veterancy.
        OnVeteranLevel = function(self, old, new)

        -- PROFILER START
        if not tracker.Functions["OnVeteranLevel"] then 
            tracker.Functions["OnVeteranLevel"]  = 0 
        end
        tracker.Functions["OnVeteranLevel"] = tracker.Functions["OnVeteranLevel"] + 1
        -- PROFILER END

        local bp = self.Blueprint.Buffs
        if not bp then return end

        local lvlkey = 'VeteranLevel' .. new
        for k, v in bp do
            if v.Add[lvlkey] == true then
                self:AddBuff(v)
            end
        end
    end,

    -- Adds a weapon buff.
        AddBuff = function(self, buffTbl)

        -- PROFILER START
        if not tracker.Functions["AddBuff"] then 
            tracker.Functions["AddBuff"]  = 0 
        end
        tracker.Functions["AddBuff"] = tracker.Functions["AddBuff"] + 1
        -- PROFILER END

        self.unit:AddWeaponBuff(buffTbl, self)
    end,

    -- Adds a damage modification (can be both positive and negative)
        AddDamageMod = function(self, dmgMod)

        -- PROFILER START
        if not tracker.Functions["AddDamageMod"] then 
            tracker.Functions["AddDamageMod"]  = 0 
        end
        tracker.Functions["AddDamageMod"] = tracker.Functions["AddDamageMod"] + 1
        -- PROFILER END

        self.DamageMod = self.DamageMod + dmgMod
        self.damageTableCache = false
    end,

    -- Adds a damage radius modification (can be both positive and negative)
        AddDamageRadiusMod = function(self, dmgRadMod)

        -- PROFILER START
        if not tracker.Functions["AddDamageRadiusMod"] then 
            tracker.Functions["AddDamageRadiusMod"]  = 0 
        end
        tracker.Functions["AddDamageRadiusMod"] = tracker.Functions["AddDamageRadiusMod"] + 1
        -- PROFILER END

        self.DamageRadiusMod = self.DamageRadiusMod + (dmgRadMod or 0)
        self.damageTableCache = false
    end,

    -- Buffs that only apply when the weapon is firing.
        DoOnFireBuffs = function(self)

        -- PROFILER START
        if not tracker.Functions["DoOnFireBuffs"] then 
            tracker.Functions["DoOnFireBuffs"]  = 0 
        end
        tracker.Functions["DoOnFireBuffs"] = tracker.Functions["DoOnFireBuffs"] + 1
        -- PROFILER END

        local data = self.Blueprint
        if data.Buffs then
            for k, v in data.Buffs do
                if v.Add.OnFire == true then
                    self.unit:AddBuff(v)
                end
            end
        end
    end,

    -- Disables a buff.
        DisableBuff = function(self, buffname)

        -- PROFILER START
        if not tracker.Functions["DisableBuff"] then 
            tracker.Functions["DisableBuff"]  = 0 
        end
        tracker.Functions["DisableBuff"] = tracker.Functions["DisableBuff"] + 1
        -- PROFILER END

        if buffname then
            self.DisabledBuffs[buffname] = true
        else
            -- Error
            error('ERROR: DisableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

        ReEnableBuff = function(self, buffname)

        -- PROFILER START
        if not tracker.Functions["ReEnableBuff"] then 
            tracker.Functions["ReEnableBuff"]  = 0 
        end
        tracker.Functions["ReEnableBuff"] = tracker.Functions["ReEnableBuff"] + 1
        -- PROFILER END

        if buffname then
            self.DisabledBuffs[buffname] = nil
        else
            -- Error
            error('ERROR: ReEnableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

    -- Method to mark weapon when parent unit gets loaded on to a transport unit
        SetOnTransport = function(self, transportstate)

        -- PROFILER START
        if not tracker.Functions["SetOnTransport"] then 
            tracker.Functions["SetOnTransport"]  = 0 
        end
        tracker.Functions["SetOnTransport"] = tracker.Functions["SetOnTransport"] + 1
        -- PROFILER END

        self.onTransport = transportstate
        if not transportstate then
            -- send a message to tell the weapon that the unit just got dropped and needs to restart aim
            self:OnLostTarget()
        end
        -- Disable weapon if on transport and not allowed to fire from it
        if not self.unit.Blueprint.Transport.CanFireFromTransport then
            if transportstate then
                self.WeaponDisabledOnTransport = true
                self:SetWeaponEnabled(false)
            else
                self:SetWeaponEnabled(true)
                self.WeaponDisabledOnTransport = false
            end
        end
    end,

    -- Method to retreive onTransport information. True if the parent unit has been loaded on to a transport unit
        GetOnTransport = function(self)

        -- PROFILER START
        if not tracker.Functions["GetOnTransport"] then 
            tracker.Functions["GetOnTransport"]  = 0 
        end
        tracker.Functions["GetOnTransport"] = tracker.Functions["GetOnTransport"] + 1
        -- PROFILER END

        return self.onTransport
    end,

    -- This is the function to set a weapon enabled.
    -- If the weapon is enhabled by an enhancement, this will check to see if the unit has the enhancement before
    -- allowing it to try to be enabled or disabled.
        SetWeaponEnabled = function(self, enable)

        -- PROFILER START
        if not tracker.Functions["SetWeaponEnabled"] then 
            tracker.Functions["SetWeaponEnabled"]  = 0 
        end
        tracker.Functions["SetWeaponEnabled"] = tracker.Functions["SetWeaponEnabled"] + 1
        -- PROFILER END

        if not enable then
            self:SetEnabled(enable)
            return
        end
        local bp = self.Blueprint.EnabledByEnhancement
        if bp then
            for k, v in SimUnitEnhancements[self.unit.EntityId] or {} do
                if v == bp then
                    self:SetEnabled(enable)
                    return
                end
            end
            -- Enhancement needed but doesn't have it, don't allow weapon to be enabled.
            return
        end
        self:SetEnabled(enable)
    end,
}
