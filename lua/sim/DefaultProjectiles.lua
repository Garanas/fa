-----------------------------------------------------------------
-- File     : /lua/defaultprojectiles.lua
-- Author(s): John Comes, Gordon Duclos
-- Summary  : Script for default projectiles
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Projectile = import('/lua/sim/Projectile.lua').Projectile
local UnitsInSphere = import('/lua/utilities.lua').GetTrueEnemyUnitsInSphere
local GetDistanceBetweenTwoEntities = import('/lua/utilities.lua').GetDistanceBetweenTwoEntities
local OCProjectiles = {}


-- globals as upvalues for performance 
local Damage = Damage
local DamageRing = DamageRing
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateTrail = CreateTrail
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- math functions as upvalues for performance
local MathFloor = _G.math.floor
local MathMin = _G.math.min
local MathMax = _G.math.max 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetHealth = EntityMethods.GetHealth
local EntityPlaySound = EntityMethods.PlaySound
local EntityBeenDestroyed = EntityMethods.BeenDestroyed
local EntityCreateProjectile = EntityMethods.CreateProjectile
local EntitySetAmbientSound = EntityMethods.SetAmbientSound

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate

local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetCollision = ProjectileMethods.SetCollision

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

local TrashAdd = TrashBag.Add

-- attach for CTRL + SHIFT F replacement

-----------------------------------------------------------------
-- Null Shell
-----------------------------------------------------------------

NullShell = Class(Projectile) {}

-----------------------------------------------------------------
-- PROJECTILE WITH ATTACHED EFFECT EMITTERS
-----------------------------------------------------------------

EmitterProjectile = Class(Projectile) {
    FxTrails = {'/effects/emitters/missile_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,

    OnCreate = function(self)
        Projectile.OnCreate(self)

        local fxTrails = self.FxTrails
        if fxTrails then 
            local army = self.Army
            local fxTrailScale = self.FxTrailScale
            local fxTrailOffset = self.FxTrailOffset
            for i in fxTrails do
                local emit = CreateEmitterOnEntity(self, army, fxTrails[i])
                EmitterScaleEmitter(emit, fxTrailScale)
                EmitterOffsetEmitter(emit, 0, 0, fxTrailOffset)
            end
        end
    end,
}

-----------------------------------------------------------------
-- BEAM PROJECTILES
-----------------------------------------------------------------
SingleBeamProjectile = Class(EmitterProjectile) {

    BeamName = '/effects/emitters/default_beam_01_emit.bp',
    FxTrails = false,

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        local army = self.Army
        local beamName = self.BeamName
        if beamName then
            CreateBeamEmitterOnEntity(self, -1, army, beamName)
        end
    end,
}

MultiBeamProjectile = Class(EmitterProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    FxTrails = false,

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        local army = self.Army
        local beams = self.Beams
        for k, v in beams do
            CreateBeamEmitterOnEntity(self, -1, army, v)
        end
    end,
}

local NukeProjectileOnImpactCategories = categories.PROJECTILE * categories.ANTIMISSILE * categories.TECH_THREE

-- Nukes
NukeProjectile = Class(NullShell) {

    OnCreate = function(self)
        NullShell.OnCreate(self)

        -- set ambient sound if available
        local ambientSound = self.Blueprint.Audio.ExistLoop
        if ambientSound then
            EntitySetAmbientSound(self, ambientSound, nil)
        end
    end,

    MovementThread = function(self)
        local army = self.Army
        local launcher = self.Launcher
		self.Nuke = true
        self.CreateEffects(self, self.InitialEffects, army, 1)
        ProjectileTrackTarget(self, false)
        WaitSeconds(2.5) -- Height
        ProjectileSetCollision(self, true)
        self.CreateEffects(self, self.LaunchEffects, army, 1)
        WaitSeconds(2.5)
        self.CreateEffects(self, self.ThrustEffects, army, 3)
        WaitSeconds(2.5)
        ProjectileTrackTarget(self, true) -- Turn ~90 degrees towards target
        ProjectileSetDestroyOnWater(self, true)
        ProjectileSetTurnRate(self, 45)
        WaitSeconds(2) -- Now set turn rate to zero so nuke flies straight
        ProjectileSetTurnRate(self, 0)
        ProjectileSetAcceleration(self, 0.001)
        self.WaitTime = 0.5
        while not EntityBeenDestroyed(self) do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetSquaredDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 150 * 150 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            ProjectileSetTurnRate(self, 0)
        elseif dist > 75 * 75 and dist <= 150 * 150 then
            -- Increase check intervals
            self.WaitTime = 0.3
        elseif dist > 32 * 32 and dist <= 75 * 75 then
            -- Further increase check intervals
            self.WaitTime = 0.1
        elseif dist < 32 * 32 then
            -- Turn the missile down
            ProjectileSetTurnRate(self, 50)
        end
    end,

    GetSquaredDistanceToTarget = function(self)
        local tpos = ProjectileGetCurrentTargetPosition(self)
        local mpos = EntityGetPosition(self)
        return VDist2Sq(mpos[1], mpos[3], tpos[1], tpos[3])
    end,

    CreateEffects = function(self, EffectTable, army, scale)
        if EffectTable then 
            local trash = self.Trash
            EffectScale = EffectScale or 1
            for k, v in EffectTable do
                local emit = CreateEmitterAtEntity(self,army,v)
                EmitterScaleEmitter(emit, EffectScale)
                TrashAdd(trash, emit)
            end
        end
    end,

    ForceThread = function(self)
        -- Knockdown force rings
        local position = EntityGetPosition(self)
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
        WaitSeconds(0.1)
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(NukeProjectileOnImpactCategories, TargetEntity) then
            -- Play the explosion sound
            local snd = self.Blueprint.Audio.NukeExplosion
            if snd then
                EntityPlaySound(self, snd)
            end

            -- create the entity
            local effectEntity = EntityCreateProjectile(self, self.effectEntityPath, 0, 0, 0, nil, nil, nil)
            ProjectileSetCollision(effectEntity, false)
            TrashAdd(effectEntity.Trash, ForkThread(effectEntity.EffectThread, effectEntity))
            TrashAdd(self.Trash, ForkThread(self.ForceThread, self))

            -- allow other nukes to toy with the entity
            self.effectEntity = effectEntity
        end
        NullShell.OnImpact(self, TargetType, TargetEntity)
    end,

    LauncherCallbacks = function(self)
        local launcher = self.Launcher
        if launcher and not launcher.Dead and launcher.EventCallbacks.ProjectileDamaged then
            self.ProjectileDamaged = {}
            for k,v in launcher.EventCallbacks.ProjectileDamaged do
                table.insert(self.ProjectileDamaged, v)
            end
        end
        ProjectileSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        TrashAdd(self.Trash, ForkThread(self.MovementThread, self))
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        if self.ProjectileDamaged then
            for k,v in self.ProjectileDamaged do
                v(self)
            end
        end
        NullShell.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
		local bp = self.Blueprint.Defense.MaxHealth
			if bp then
			self:DoTakeDamage(instigator, amount, vector, damageType)
		else
			self:OnKilled(instigator, damageType)
		end
    end,
}

-----------------------------------------------------------------
-- POLY-TRAIL PROJECTILES
-----------------------------------------------------------------
SinglePolyTrailProjectile = Class(EmitterProjectile) {

    PolyTrail = '/effects/emitters/test_missile_trail_emit.bp',
    PolyTrailOffset = 0,
    FxTrails = false,

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        local polyTrail = self.PolyTrail
        if polyTrail then
            local army = self.Army
            local polyTrailOffset = self.PolyTrailOffset
            local emit = CreateTrail(self, -1, army, polyTrail)
            EmitterOffsetEmitter(emit, 0, 0, self.PolyTrailOffset)
        end
    end,
}

MultiPolyTrailProjectile = Class(EmitterProjectile) {

    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = { 0 },
    FxTrails = false,
    RandomPolyTrails = 0,   -- Count of how many are selected randomly for PolyTrail table

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        -- see if we have trails
        local polyTrails = self.PolyTrails
        if polyTrails then

            -- information that is used in both branches
            local army = self.Army
            local randomPolyTrails = self.RandomPolyTrails
            local polyTrailOffset = self.PolyTrailOffset
            local NumPolyTrails = table.getn(self.PolyTrails)   -- ouch

            -- check if they should be random or not
            if randomPolyTrails ~= 0 then
                for i = 1, randomPolyTrails do
                    local index = MathFloor(Random(1, NumPolyTrails))
                    local emit = CreateTrail(self, -1, army, polyTrails[index])
                    EmitterOffsetEmitter(emit, 0, 0, polyTrailOffset[index])
                end
            else
                for i = 1, NumPolyTrails do
                    local emit = CreateTrail(self, -1, army, polyTrails[i])
                    EmitterOffsetEmitter(emit, 0, 0, polyTrailOffset[i])
                end
            end
        end
    end,
}


-----------------------------------------------------------------
-- COMPOSITE EMITTER PROJECTILES - MULTIPURPOSE PROJECTILES
-- - THAT COMBINES BEAMS, POLYTRAILS, AND NORMAL EMITTERS
-----------------------------------------------------------------

-- LIGHTWEIGHT VERSION THAT LIMITS USE TO 1 BEAM, 1 POLYTRAIL, AND STANDARD EMITTERS
SingleCompositeEmitterProjectile = Class(SinglePolyTrailProjectile) {

    BeamName = '/effects/emitters/default_beam_01_emit.bp',
    FxTrails = false,

    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        local beamName = self.BeamName
        if beamName ~= '' then
            CreateBeamEmitterOnEntity(self, -1, self.Army, beamName)
        end
    end,
}

-- HEAVYWEIGHT VERSION, ALLOWS FOR MULTIPLE BEAMS, POLYTRAILS, AND STANDARD EMITTERS
MultiCompositeEmitterProjectile = Class(MultiPolyTrailProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = {0},
    RandomPolyTrails = 0,   -- Count of how many are selected randomly for PolyTrail table
    FxTrails = false,

    OnCreate = function(self)
        MultiPolyTrailProjectile.OnCreate(self)
        
        local army = self.Army
        local beams = self.Beams
        for k, v in beams do
            CreateBeamEmitterOnEntity(self, -1, army, v)
        end
    end,
}

-----------------------------------------------------------------
-- TRAIL ON ENTERING WATER PROJECTILE
-----------------------------------------------------------------
OnWaterEntryEmitterProjectile = Class(Projectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,
    PolyTrail = false,
    PolyTrailOffset = 0,
    TrailDelay = 5,
    EnterWaterSound = 'Torpedo_Enter_Water_01',

    OnCreate = function(self, inWater)
        Projectile.OnCreate(self, inWater)
        if inWater then
            local army = self.Army
            local fxTrails = self.FxTrails
            if fxTrails then 
                local fxTrailScale = self.FxTrailScale
                local fxTrailOffset = self.FxTrailOffset
                for i in fxTrails do
                    local emit = CreateEmitterOnEntity(self, army, fxTrails[i])
                    EmitterScaleEmitter(emit, fxTrailScale)
                    EmitterOffsetEmitter(emit, 0, 0, fxTrailOffset)
                end
            end
            local polyTrail = self.PolyTrail
            if polyTrail then
                local emit = CreateTrail(self, -1, army, polyTrail)
                EmitterOffsetEmitter(emit, 0, 0, self.PolyTrailOffset)
            end
        end
    end,

    EnterWaterThread = function(self)
        WaitTicks(self.TrailDelay)

        local army = self.Army
        local fxTrails = self.FxTrails
        if fxTrails then 
            for i in fxTrails do
                local fxTrailScale = self.FxTrailScale
                local fxTrailOffset = self.FxTrailOffset
                local emit = CreateEmitterOnEntity(self, army, fxTrails[i])
                EmitterScaleEmitter(emit, fxTrailScale)
                EmitterOffsetEmitter(emit, 0, 0, fxTrailOffset)
            end
        end
        local polyTrail = self.PolyTrail
        if polyTrail then
            local emit = CreateTrail(self, -1, army, polyTrail)
            EmitterOffsetEmitter(emit, 0, 0, self.PolyTrailOffset)
        end
    end,

    OnEnterWater = function(self)
        Projectile.OnEnterWater(self)
        ProjectileTrackTarget(self, true)
        ProjectileStayUnderwater(self, true)
        self.TTT1 = ForkThread(self.EnterWaterThread)
        TrashAdd(self.Trash, self.TTT1)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        Projectile.OnImpact(self, TargetType, TargetEntity)
        KillThread(self.TTT1)
    end,
}

-----------------------------------------------------------------
-- GENERIC DEBRIS PROJECTILE
-----------------------------------------------------------------
BaseGenericDebris = Class(EmitterProjectile){
    FxUnitHitScale = 0.25,
    FxWaterHitScale = 0.25,
    FxUnderWaterHitScale = 0.25,
    FxNoneHitScale = 0.25,
    FxImpactLand = false,
    FxLandHitScale = 0.5,
    FxTrails = false,
    FxTrailScale = 1,
}

-----------------------------------------------------------
-- PROJECTILE THAT ADJUSTS DAMAGE AND ENERGY COST ON IMPACT
-----------------------------------------------------------
OverchargeProjectile = Class() {
    OnImpact = function(self, targetType, targetEntity)
        --[[WARN('Inside OCPROJ OnImpact')
        LOG(targetType)
        LOG(targetEntity)
        if targetEntity and IsUnit(targetEntity) then
            LOG(targetEntity.UnitId)
        end]]

        -- Stop us doing blueprint damage in the other OnImpact call if we ditch this one without resetting self.DamageData
        self.DamageData.DamageAmount = 0

        local launcher = self.Launcher
        if not launcher then return end

        local wep = launcher:GetWeaponByLabel('OverCharge')
        if not wep then return end

        --  Table layout for Overcharge data section
        --  Overcharge = {
        --      energyMult = _, -- What proportion of current storage are we allowed to spend?
        --      commandDamage = _, -- Takes effect in ACUUnit DoTakeDamage()
        --      structureDamage = _, -- Takes effect in StructureUnit DoTakeDamage() & Shield  ApplyDamage()
        --      maxDamage = _,
        --      minDamage = _,
        --  },

        local data = wep.Blueprint.Overcharge
        if not data then return end

        -- Set the damage dealt by the projectile for hitting the floor or an ACUUnit
        -- Energy drained is calculated by the relationship equations
        local damage = data.minDamage

        if targetEntity then
            -- Handle hitting shields. We want the unit underneath, not the shield itself
            if not IsUnit(targetEntity) then
                if not targetEntity.Owner then -- We hit something odd, not a shield
                    WARN('Overcharge hit something that was not the ground, a shield, or a unit')
                    LOG(targetType)
                    return
                end

                targetEntity = targetEntity.Owner
            end


                -- Get max energy available to drain according to how much we have
                local energyAvailable = launcher:GetAIBrain():GetEconomyStored('ENERGY')
                local energyLimit = energyAvailable * data.energyMult

                if OCProjectiles[self.Army] > 1 then
                    energyLimit = energyLimit / OCProjectiles[self.Army]
                end

                local energyLimitDamage = self:EnergyAsDamage(energyLimit)

                -- Find max available damage
                damage = MathMin(data.maxDamage, energyLimitDamage)

                -- How much damage do we actually need to kill the unit?
                local idealDamage = EntityGetHealth(targetEntity)
                local maxHP = self:UnitsDetection(targetType, targetEntity)

                idealDamage = maxHP or data.minDamage

                targetCats = targetEntity.Blueprint.CategoriesHash

                      -----SHIELDS------
                if targetEntity.MyShield and targetEntity.MyShield.ShieldType == 'Bubble' then
                    if targetCats.STRUCTURE then
                        idealDamage = data.minDamage
                    else
                        idealDamage = targetEntity.MyShield:GetMaxHealth()
                    end
	                --MaxHealth instead of GetHealth because with getHealth OC won't kill bubble shield which is in AoE range but has more hp than targetEntity.MyShield.
                    --good against group of mobile shields
                end

                      ------ ACU -------
                if targetCats.COMMAND and not maxHP then -- no units around ACU - min.damage
                    idealDamage = data.minDamage
                end

                damage = MathMin(damage, idealDamage)
                damage = MathMax(data.minDamage, damage)

                -- prevents radars blinks if there is less than 5k e in storage when OC hits the target
                if energyAvailable < 5000 then
                    damage = energyLimitDamage
                end

            end

        -- Turn the final damage into energy
        local drain = self:DamageAsEnergy(damage)

        --LOG('Drain is ' .. drain)
        --LOG('Damage is ' .. damage)
        self.DamageData.DamageAmount = damage

        if drain > 0 then
            launcher.EconDrain = CreateEconomyEvent(launcher, drain, 0, 0)
            TrashAdd(
                launcher.Trash, ForkThread(
                    function() -- new closure each time this fork thread launches, ouch
                        WaitFor(self.EconDrain)
                        RemoveEconomyEvent(self, self.EconDrain)
                        self.EconDrain = nil

                        local army = self.Army
                        OCProjectiles[army] = OCProjectiles[army] - 1

                        -- if oc depletes a mobile shield it kills the generator, vet counted, no wreck left
                        if targetCats.DIESTOOCDEPLETINGSHIELD and not targetEntity.MyShield:IsUp() then
                            targetEntity:Kill(self, 'Overcharge', 2)
                            self:OnKilledUnit(targetEntity, targetEntity:GetVeterancyValue())
                        end
                    end,
                    launcher
                )
            )
        end
    end,

    -- y = 3000e^(0.000095(x+15500))-10090 = old values
    -- y = 4x = new values
    -- https://www.desmos.com/calculator/ap0kazbdp0
    DamageAsEnergy = function(self, damage)
        return damage * 4
    end,

    EnergyAsDamage = function(self, energy)
        return energy / 4
    end,

    UnitsDetection = function(self, targetType, targetEntity)
        -- looking for units around target which are in splash range
        local launcher = self.Launcher
        local maxHP = 0

        local position = EntityGetPosition(self)
        local surroundingUnits = UnitsInSphere(launcher, position, 2.7, categories.MOBILE -categories.COMMAND) or {}
        for _, unit in surroundingUnits do
            local unitHealth = EntityGetHealth(unit)
            if unit.MyShield and unitHealth + EntityGetHealth(unit.MyShield) > maxHP then
                maxHP = unitHealth + EntityGetHealth(unit.MyShield)
            elseif unitHealth > maxHP then
                maxHP = unitHealth
            end
        end

        local surroundingUnits = UnitsInSphere(launcher, position, 13.2, categories.EXPERIMENTAL*categories.LAND*categories.MOBILE) or {}
        for _, unit in surroundingUnits do
            -- Special for fatty's shield
            local unitHealth = EntityGetHealth(unit)
            if EntityCategoryContains(categories.UEF, unit) and unit.MyShield._IsUp and unit.MyShield:GetMaxHealth() > maxHP then
                maxHP = unit.MyShield:GetMaxHealth()
            elseif unitHealth > maxHP then
                local distance = MathMin(unit.Blueprint.SizeX, unit.Blueprint.SizeZ)
                if GetDistanceBetweenTwoEntities(unit, self) < distance + self.DamageData.DamageRadius then
                    maxHP = unitHealth
                end
            end
        end

        if EntityCategoryContains(categories.EXPERIMENTAL, targetEntity) and EntityGetHealth(targetEntity) > maxHP then
            maxHP = EntityGetHealth(targetEntity)
            --[[ we need this because if OC shell hitted top part of GC model its health won't be in our table
            Bug appeared since we use shell.pos in getUnitsInSphere instead of target.pos.
            Shell is too far from actual target.pos(target pos is somewhere near land and shell is near GC's head)
            and getUnits returns nothing. Same to GetDistance. Distance between shell and GC pos > than MathMin(x,z) size]]
        end

        if maxHP ~= 0 then
            return maxHP
        end
    end,

    OnCreate = function(self)
        local army = self:GetArmy()
        self.Army = army

        if not OCProjectiles[army] then
            OCProjectiles[army] = 0
        end

        OCProjectiles[army] = OCProjectiles[army] + 1
    end,
}
