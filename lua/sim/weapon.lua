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

-- Contains all default weapon priorities that are defined in blueprint files. It is
-- cached when a weapon is made for the first time. The ID is defined in Blueprints.lua and
-- is essentially <unitblueprintid-weaponnumber>. As an example for the Zthuee: xsl0103-1.
local CacheAllWeaponPriorities = { } 

Weapon = Class(moho.weapon_methods) {
    __init = function(self, unit)
        self.unit = unit
    end,

    OnCreate = function(self)

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

    AmmoThread = function(self, nuke, amount)
        WaitSeconds(0.1)
        if nuke then
            self.unit:GiveNukeSiloAmmo(amount)
        else
            self.unit:GiveTacticalSiloAmmo(amount)
        end
    end,

    SetupTurret = function(self)
        -- cache for performance
        local unit = self.unit
        local blueprint = self.Blueprint

        -- get turret bones
        local yawBone = blueprint.TurretBoneYaw
        local pitchBone = blueprint.TurretBonePitch
        local muzzleBone = blueprint.TurretBoneMuzzle
        local precedence = blueprint.AimControlPrecedence or 10

        -- these are optional, they default to nil
        local pitchBone2 = blueprint.TurretBoneDualPitch
        local muzzleBone2 = blueprint.TurretBoneDualMuzzle

        -- check to make sure they're valid
        if not (unit.IsValidBone(unit, yawBone) and unit.IsValidBone(unit, pitchBone) and unit.IsValidBone(unit, muzzleBone)) then
            error('*ERROR: Bone aborting turret setup due to bone issues.', 2)
            return
        end

        -- check if these are valid, assuming they exist
        if pitchBone2 and muzzleBone2 then
            if not (unit.IsValidBone(unit, pitchBone2) and unit.IsValidBone(unit, muzzleBone2)) then
                error('*ERROR: Bone aborting turret setup due to pitch/muzzle bone2 issues.', 2)
                return
            end
        end


        if yawBone and pitchBone and muzzleBone then
            if blueprint.TurretDualManipulators then
                self.AimControl = CreateAimController(self, 'Torso', yawBone)
                self.AimRight = CreateAimController(self, 'Right', pitchBone, pitchBone, muzzleBone)
                self.AimLeft = CreateAimController(self, 'Left', pitchBone2, pitchBone2, muzzleBone2)
                self.AimControl:SetPrecedence(precedence)
                self.AimRight:SetPrecedence(precedence)
                self.AimLeft:SetPrecedence(precedence)
                if EntityCategoryContains(categories.STRUCTURE, unit) then
                    self.AimControl:SetResetPoseTime(9999999)
                end
                self:SetFireControl('Right')
                self.Trash:Add(self.AimControl)
                self.Trash:Add(self.AimRight)
                self.Trash:Add(self.AimLeft)
            else
                self.AimControl = CreateAimController(self, 'Default', yawBone, pitchBone, muzzleBone)
                if EntityCategoryContains(categories.STRUCTURE, self.unit) then
                    self.AimControl:SetResetPoseTime(9999999)
                end
                self.Trash:Add(self.AimControl)
                self.AimControl:SetPrecedence(precedence)
                if blueprint.RackSlavedToTurret and not table.empty(blueprint.RackBones) then
                    for k, v in blueprint.RackBones do
                        if v.RackBone ~= pitchBone then
                            local slaver = CreateSlaver(self.unit, v.RackBone, pitchBone)
                            slaver:SetPrecedence(precedence-1)
                            self.Trash:Add(slaver)
                        end
                    end
                end
            end
        else
            error('*ERROR: Trying to setup a turreted weapon but there are yaw bones, pitch bones or muzzle bones missing from the blueprint.', 2)
        end


        local numbersexist = true
        local turretyawmin, turretyawmax, turretyawspeed
        local turretpitchmin, turretpitchmax, turretpitchspeed

        -- SETUP MANIPULATORS AND SET TURRET YAW, PITCH AND SPEED
        if blueprint.TurretYaw and blueprint.TurretYawRange then
            turretyawmin, turretyawmax = self:GetTurretYawMinMax()
        else
            numbersexist = false
        end
        if blueprint.TurretYawSpeed then
            turretyawspeed = self:GetTurretYawSpeed()
        else
            numbersexist = false
        end
        if blueprint.TurretPitch and blueprint.TurretPitchRange then
            turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
        else
            numbersexist = false
        end
        if blueprint.TurretPitchSpeed then
            turretpitchspeed = self:GetTurretPitchSpeed()
        else
            numbersexist = false
        end
        if numbersexist then
            self.AimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            if self.AimRight then
                self.AimRight:SetFiringArc(turretyawmin/12, turretyawmax/12, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            end
            if self.AimLeft then
                self.AimLeft:SetFiringArc(turretyawmin/12, turretyawmax/12, turretyawspeed, turretpitchmin, turretpitchmax, turretpitchspeed)
            end
        else
            local strg = '*ERROR: TRYING TO SETUP A TURRET WITHOUT ALL TURRET NUMBERS IN BLUEPRINT, ABORTING TURRET SETUP. WEAPON: ' .. blueprint.Label .. ' UNIT: '.. self.unit.UnitId
            error(strg, 2)
        end
    end,

    AimManipulatorSetEnabled = function(self, enabled)
        if self.AimControl then
            self.AimControl:SetEnabled(enabled)
        end
    end,

    GetAimManipulator = function(self)
        return self.AimControl
    end,

    SetTurretYawSpeed = function(self, speed)
        local turretyawmin, turretyawmax = self:GetTurretYawMinMax()
        local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
        local turretpitchspeed = self:GetTurretPitchSpeed()
        if self.AimControl then
            self.AimControl:SetFiringArc(turretyawmin, turretyawmax, speed, turretpitchmin, turretpitchmax, turretpitchspeed)
        end
    end,

    SetTurretPitchSpeed = function(self, speed)
        local turretyawmin, turretyawmax = self:GetTurretYawMinMax()
        local turretpitchmin, turretpitchmax = self:GetTurretPitchMinMax()
        local turretpitchspeed = self:GetTurretYawSpeed()
        if self.AimControl then
            self.AimControl:SetFiringArc(turretyawmin, turretyawmax, turretyawspeed, turretpitchmin, turretpitchmax, speed)
        end
    end,

    GetTurretYawMinMax = function(self)
        local bp = self.Blueprint
        local turretyawmin = bp.TurretYaw - bp.TurretYawRange
        local turretyawmax = bp.TurretYaw + bp.TurretYawRange
        return turretyawmin, turretyawmax
    end,

    GetTurretYawSpeed = function(self)
        return self.Blueprint.TurretYawSpeed
    end,

    GetTurretPitchMinMax = function(self)
        local bp = self.Blueprint
        local turretpitchmin = bp.TurretPitch - bp.TurretPitchRange
        local turretpitchmax = bp.TurretPitch + bp.TurretPitchRange
        return turretpitchmin, turretpitchmax
    end,

    GetTurretPitchSpeed = function(self)
        return self.Blueprint.TurretPitchSpeed
    end,

    OnFire = function(self)
        self:PlayWeaponSound('Fire')
        self:DoOnFireBuffs()
    end,

    OnEnableWeapon = function(self)
    end,

    OnGotTarget = function(self)
        if self.DisabledFiringBones and self.unit.Animator then
            for key, value in self.DisabledFiringBones do
                self.unit.Animator:SetBoneEnabled(value, false)
            end
        end
        self.NumTargets = self.NumTargets + 1
    end,

    OnLostTarget = function(self)
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

    OnStartTracking = function(self, label)
        self:PlayWeaponSound('BarrelStart')
        self:PlayWeaponAmbientSound('BarrelLoop')
    end,

    OnStopTracking = function(self, label)
        self:PlayWeaponSound('BarrelStop')
        self:StopWeaponAmbientSound('BarrelLoop')
        if EntityCategoryContains(categories.STRUCTURE, self.unit) then
            self.AimControl:SetResetPoseTime(9999999)
        end

    end,

    PlayWeaponSound = function(self, sound)
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        self:PlaySound(bp.Audio[sound])
    end,

    PlayWeaponAmbientSound = function(self, sound)
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        if not self.AmbientSounds then
            self.AmbientSounds = {}
        end
        if not self.AmbientSounds[sound] then
            local sndEnt = Entity {}
            self.AmbientSounds[sound] = sndEnt
            self.unit.Trash:Add(sndEnt)
            sndEnt:AttachTo(self.unit,-1)
        end
        self.AmbientSounds[sound]:SetAmbientSound(bp.Audio[sound], nil)
    end,

    StopWeaponAmbientSound = function(self, sound)
        if not self.AmbientSounds then return end
        if not self.AmbientSounds[sound] then return end
        local bp = self.Blueprint
        if not bp.Audio[sound] then return end
        self.AmbientSounds[sound]:Destroy()
        self.AmbientSounds[sound] = nil
    end,

    OnMotionHorzEventChange = function(self, new, old)
    end,

    GetDamageTableInternal = function(self)
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
        if not self.damageTableCache then self.damageTableCache = self:GetDamageTableInternal() end
        return self.damageTableCache
    end,

    CreateProjectileForWeapon = function(self, bone)
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

    SetValidTargetsForCurrentLayer = function(self, newLayer)
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

    OnDestroy = function(self)
    end,

    SetWeaponPriorities = function(self, priTable)

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

            -- set the default weapon priorities
            if priorities then 
                self:SetTargetingPriorities(priorities)
            end
        else
            if type(priTable[1]) == 'string' then
                LOG("String pri table")
                local priorityTable = {}
                for k, v in priTable do
                    table.insert(priorityTable, ParseEntityCategory(v))
                end
                self:SetTargetingPriorities(priorityTable)
            else
                LOG("non-string pri table")
                self:SetTargetingPriorities(priTable)
            end
        end
    end,

    WeaponUsesEnergy = function(self)
        local bp = self.Blueprint
        if bp.EnergyRequired and bp.EnergyRequired > 0 then
            return true
        end
        return false
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.unit.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    OnVeteranLevel = function(self, old, new)
        local bp = self.Blueprint.Buffs
        if not bp then return end

        local lvlkey = 'VeteranLevel' .. new
        for k, v in bp do
            if v.Add[lvlkey] == true then
                self:AddBuff(v)
            end
        end
    end,

    AddBuff = function(self, buffTbl)
        self.unit:AddWeaponBuff(buffTbl, self)
    end,

    AddDamageMod = function(self, dmgMod)
        self.DamageMod = self.DamageMod + dmgMod
        self.damageTableCache = false
    end,

    AddDamageRadiusMod = function(self, dmgRadMod)
        self.DamageRadiusMod = self.DamageRadiusMod + (dmgRadMod or 0)
        self.damageTableCache = false
    end,

    DoOnFireBuffs = function(self)
        local data = self.Blueprint
        if data.Buffs then
            for k, v in data.Buffs do
                if v.Add.OnFire == true then
                    self.unit:AddBuff(v)
                end
            end
        end
    end,

    DisableBuff = function(self, buffname)
        if buffname then
            self.DisabledBuffs[buffname] = true
        else
            -- Error
            error('ERROR: DisableBuff in weapon.lua does not have a buffname')
        end
        self.damageTableCache = false
    end,

    ReEnableBuff = function(self, buffname)
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
        return self.onTransport
    end,

    -- This is the function to set a weapon enabled.
    -- If the weapon is enhabled by an enhancement, this will check to see if the unit has the enhancement before
    -- allowing it to try to be enabled or disabled.
    SetWeaponEnabled = function(self, enable)
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
