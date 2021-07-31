-----------------------------------------------------------------
-- File     :  /lua/EffectUtilities.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Effect Utility functions for scripts.
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local Utils = import('utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- upvalues instead of globals

-- often used imports
local RandomFloat = Utils.GetRandomFloat -- really

-- often used globals
local Warp = Warp
local Vector = Vector
local Random = Random 
local WaitSeconds = WaitSeconds
local CreateLightParticle = CreateLightParticle
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateAttachedEmitter = CreateAttachedEmitter
local AttachBeamEntityToEntity = AttachBeamEntityToEntity

local TrashAdd = TrashBag.Add

-- often used math functions
local MathCeil = math.ceil 
local MathMin = math.min 
local MathMax = math.max 
local MathAbs = math.abs 
local MathPow = math.pow

-- often used metatable functions
local EntityGetPosition = moho.entity_methods.GetPosition
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed

local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete
local UnitCreateProjectile = moho.unit_methods.CreateProjectile

local ProjectileSetVelocity = moho.projectile_methods.SetVelocity
local ProjectileSetScale = moho.projectile_methods.SetScale

-- todo
local EffectOffsetEmitter = moho.IEffect.OffsetEmitter
local EffectScaleEmitter = moho.IEffect.ScaleEmitter
local EffectSetEmitterParam = moho.IEffect.SetEmitterParam

function CreateEffects(obj, army, EffectTable)

    -- initialize emitters table for optimized population
    local n = 0
    local emitters = {}

    -- populate it
    for _, v in EffectTable do
        n = n + 1
        emitters[n] = CreateEmitterAtEntity(obj, army, v)
    end

    -- return both table and the number of elements
    return emitters, n
end

function CreateEffectsWithOffset(obj, army, EffectTable, x, y, z)
    -- initialize emitters table for optimized population
    local n = 0
    local emitters = {}

    -- populate it
    for _, v in EffectTable  do
        n = n + 1
        emitters[n] = EffectOffsetEmitter(CreateEmitterAtEntity(obj, army, v), x, y, z)
    end

    -- return both table and the number of elements
    return emitters, n
end

function CreateEffectsWithRandomOffset(obj, army, EffectTable, xRange, yRange, zRange)
    -- initialize emitters table for optimized population
    local n = 0
    local emitters = {}

    -- populate it
    for _, v in EffectTable do
        emitters[n] = EffectOffsetEmitter(CreateEmitterOnEntity(obj, army, v), Utils.GetRandomOffset(xRange, yRange, zRange, 1))
        n = n + 1
    end

    -- return both table and the number of elements
    return emitters, n
end

function CreateBoneEffects(obj, bone, army, EffectTable)
    -- initialize emitters table for optimized population
    local n = 0
    local emitters = {}

    -- populate it
    for _, v in EffectTable do
        n = n + 1
        emitters[n] = CreateEmitterAtBone(obj, bone, army, v)
    end

    -- return both table and the number of elements
    return emitters, n
end

function CreateBoneEffectsOffset(obj, bone, army, EffectTable, x, y, z)
    -- initialize emitters table for optimized population
    local n = 0
    local emitters = {}

    -- populate it
    for _, v in EffectTable do
        n = n + 1
        emitters[n] = EffectOffsetEmitter(CreateEmitterAtBone(obj, bone, army, v), x, y, z)
    end

    -- return both table and the number of elements
    return emitters
end

function CreateBoneTableEffects(obj, BoneTable, army, EffectTable)
    -- initialize emitters table for optimized population
    local n = 0 
    local emitters = { }
    
    -- populate it
    for _, vBone in BoneTable do
        for _, vEffect in EffectTable do
            n = n + 1
            emitters[n] = CreateEmitterAtBone(obj, vBone, army, vEffect)
        end
    end

    -- return both table and the number of elements
    return emitters, n 
end

function CreateBoneTableRangedScaleEffects(obj, BoneTable, EffectTable, army, ScaleMin, ScaleMax)
    -- initialize emitters table for optimized population
    local n = 0
    local emitters = { }

    -- populate it
    for _, vBone in BoneTable do
        for _, vEffect in EffectTable do
            n = n + 1
            emitters[n] = EffectScaleEmitter(CreateEmitterAtBone(obj, vBone, army, vEffect), RandomFloat(ScaleMin, ScaleMax))
        end
    end

    -- return both table and the number of elements
    return emitters, n 
end

function CreateRandomEffects(obj, army, EffectTable, NumEffects)
    -- get number of entries
    local NumTableEntries = table.getn(EffectTable)

    -- initialize emitters table for optimized population
    local emitters = {}

    -- populate it
    for i = 1, NumEffects do
        local ri = Utils.GetRandomInt(1, NumTableEntries)
        emitters[i] = CreateEmitterOnEntity(obj, army, EffectTable[ri])
    end
    
        -- return both table and the number of elements
    return emitters, NumEffects
end

function ScaleEmittersParam(Emitters, param, minRange, maxRange)
    local diff = maxRange - minRange
    for _, v in Emitters do
        v:SetEmitterParam(param, minRange + diff * Random())
    end
end

function CreateBuildCubeThread(unitBeingBuilt, builder, OnBeingBuiltEffectsBag)
    unitBeingBuilt.BuildingCube = true
    local bp = unitBeingBuilt.Blueprint
    local mul = 1.15
    local xPos, yPos, zPos = EntityGetPositionXYZ(unitBeingBuilt)
    local proj = nil
    yPos = yPos + (bp.Physics.MeshExtentsOffsetY or 0)

    local x = bp.Physics.MeshExtentsX or (bp.Footprint.SizeX * mul)
    local z = bp.Physics.MeshExtentsZ or (bp.Footprint.SizeZ * mul)
    local y = bp.Physics.MeshExtentsY or (0.5 + (x + z) * 0.1)

    -- Create a quick glow effect at location where unit is goig to be built
    proj = UnitCreateProjectile(unitBeingBuilt, '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, 0, 0, nil, nil, nil)
    ProjectileSetScale(proj, x * 1.05, y * 0.2, z * 1.05)
    WaitSeconds(0.1)

    if unitBeingBuilt.Dead then
        return
    end

    local BuildBaseEffect = UnitCreateProjectile(unitBeingBuilt, '/effects/Entities/UEFBuildEffect/UEFBuildEffect03_proj.bp', 0, 0, 0, nil, nil, nil)
    TrashAdd(OnBeingBuiltEffectsBag, BuildBaseEffect)
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)
    Warp(BuildBaseEffect, Vector(xPos, yPos - y, zPos))
    ProjectileSetScale(BuildBaseEffect, x, y, z)
    ProjectileSetVelocity(BuildBaseEffect, 0, 1.4 * y, 0)
    WaitSeconds(0.7)

    if unitBeingBuilt.Dead then
        return
    end

    if not EntityBeenDestroyed(BuildBaseEffect) then
        ProjectileSetVelocity(BuildBaseEffect, 0)
    end

    unitBeingBuilt:ShowBone(0, true)
    unitBeingBuilt:HideLandBones()
    unitBeingBuilt.BeingBuiltShowBoneTriggered = true

    local lComplete = UnitGetFractionComplete(unitBeingBuilt)
    WaitSeconds(0.2)

    if unitBeingBuilt.Dead then
        return
    end

    -- Create glow slice cuts and resize base cube
    local slice = nil
    local SlicePeriod = 1.1
    local cComplete = UnitGetFractionComplete(unitBeingBuilt)
    while not unitBeingBuilt.Dead and  cComplete < 1.0 do
        if lComplete < cComplete and not EntityBeenDestroyed(BuildBaseEffect) then
            proj = UnitCreateProjectile(BuildBaseEffect, '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, y * (1 - cComplete), 0, nil, nil, nil)
            TrashAdd(OnBeingBuiltEffectsBag, proj)
            slice = MathAbs(lComplete - cComplete)
            ProjectileSetScale(proj, x, y * slice, z)
            ProjectileSetScale(BuildBaseEffect, x, y * (1 - cComplete), z)
        end
        WaitSeconds(SlicePeriod)

        if unitBeingBuilt.Dead then
            break
        end
        lComplete = cComplete
        cComplete = UnitGetFractionComplete(unitBeingBuilt)
    end
    unitBeingBuilt.BuildingCube = nil
end

function CreateUEFUnitBeingBuiltEffects(builder, unitBeingBuilt, BuildEffectsBag)
    local buildAttachBone = builder.Blueprint.Display.BuildAttachBone
    TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, buildAttachBone, builder.Army, '/effects/emitters/uef_mobile_unit_build_01_emit.bp'))
end

function CreateUEFBuildSliceBeams(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local buildbp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(unitBeingBuilt)
    y = y + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamEndEntity = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    TrashAdd(BuildEffectsBag, BeamEndEntity)

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            TrashAdd(BuildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, builder.Army, BeamBuildEmtBp))
            TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, BuildBone, builder.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end

    -- Determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local mul = 1.15
    local ox = buildbp.Physics.MeshExtentsX or (buildbp.Footprint.SizeX * mul)
    local oz = buildbp.Physics.MeshExtentsZ or (buildbp.Footprint.SizeZ * mul)
    local oy = (buildbp.Physics.MeshExtentsY or (0.5 + (ox + oz) * 0.1))

    ox = ox * 0.5
    oz = oz * 0.5

    -- Determine the the 2 closest edges of the build cube and use those for the location of our laser
    local VectorExtentsList = { Vector(x + ox, y + oy, z + oz), Vector(x + ox, y + oy, z - oz), Vector(x - ox, y + oy, z + oz), Vector(x - ox, y + oy, z - oz) }
    local endVec1 = Utils.GetClosestVector(EntityGetPosition(builder), VectorExtentsList)

    for k, v in VectorExtentsList do
        if v == endVec1 then
            table.remove(VectorExtentsList, k)
        end
    end

    local endVec2 = Utils.GetClosestVector(EntityGetPosition(builder), VectorExtentsList)
    local cx1, cy1, cz1 = endVec1[1], endVec1[2], endVec1[3]
    local cx2, cy2, cz2 = endVec2[1], endVec2[2], endVec2[3]

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velX = 2 * (endVec2.x - endVec1.x)
    local velY = 2 * (endVec2.y - endVec1.y)
    local velZ = 2 * (endVec2.z - endVec1.z)

    if UnitGetFractionComplete(unitBeingBuilt) == 0 then
        Warp(BeamEndEntity, Vector((cx1 + cx2) * 0.5, ((cy1 + cy2) * 0.5) - oy, (cz1 + cz2) * 0.5))
        WaitSeconds(0.7)
    end

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not EntityBeenDestroyed(builder) and not EntityBeenDestroyed(unitBeingBuilt) do
        if flipDirection then
            Warp(BeamEndEntity, Vector(cx1, (cy1 - (oy * UnitGetFractionComplete(unitBeingBuilt))), cz1))
            ProjectileSetVelocity(BeamEndEntity, velX, velY, velZ)
            flipDirection = false
        else
            Warp(BeamEndEntity, Vector(cx2, (cy2 - (oy * UnitGetFractionComplete(unitBeingBuilt))), cz2))
            ProjectileSetVelocity(BeamEndEntity, -velX, -velY, -velZ)
            flipDirection = true
        end
        WaitSeconds(0.5)
    end
end

function CreateUEFCommanderBuildSliceBeams(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local buildbp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(unitBeingBuilt)
    y = y + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamEndEntity = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    local BeamEndEntity2 = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    TrashAdd(BuildEffectsBag, BeamEndEntity)
    TrashAdd(BuildEffectsBag, BeamEndEntity2)

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            TrashAdd(BuildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, builder.Army, BeamBuildEmtBp))
            TrashAdd(BuildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity2, -1, builder.Army, BeamBuildEmtBp))
            TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, BuildBone, builder.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end

    -- Determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local mul = 1.15
    local ox = buildbp.Physics.MeshExtentsX or (buildbp.Footprint.SizeX * mul)
    local oz = buildbp.Physics.MeshExtentsZ or (buildbp.Footprint.SizeZ * mul)
    local oy = (buildbp.Physics.MeshExtentsY or (0.5 + (ox + oz) * 0.1))

    ox = ox * 0.5
    oz = oz * 0.5

    -- Determine the the 2 closest edges of the build cube and use those for the location of our laser
    local VectorExtentsList = { Vector(x + ox, y + oy, z + oz), Vector(x + ox, y + oy, z - oz), Vector(x - ox, y + oy, z + oz), Vector(x - ox, y + oy, z - oz) }
    local endVec1 = Utils.GetClosestVector(EntityGetPosition(builder), VectorExtentsList)

    for k, v in VectorExtentsList do
        if v == endVec1 then
            table.remove(VectorExtentsList, k)
        end
    end

    local endVec2 = Utils.GetClosestVector(EntityGetPosition(builder), VectorExtentsList)
    local cx1, cy1, cz1 = endVec1[1], endVec1[2], endVec1[3]
    local cx2, cy2, cz2 = endVec2[1], endVec2[2], endVec2[3]

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velX = 2 * (endVec2.x - endVec1.x)
    local velY = 2 * (endVec2.y - endVec1.y)
    local velZ = 2 * (endVec2.z - endVec1.z)

    if UnitGetFractionComplete(unitBeingBuilt) == 0 then
        Warp(BeamEndEntity, Vector(cx1, cy1 - oy, cz1))
        Warp(BeamEndEntity2, Vector(cx2, cy2 - oy, cz2))
        WaitSeconds(0.7)
    end

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not EntityBeenDestroyed(builder) and not EntityBeenDestroyed(unitBeingBuilt) do
        if flipDirection then
            Warp(BeamEndEntity, Vector(cx1, (cy1 - (oy * UnitGetFractionComplete(unitBeingBuilt))), cz1))
            ProjectileSetVelocity(BeamEndEntity, velX, velY, velZ)
            Warp(BeamEndEntity2, Vector(cx2, (cy2 - (oy * UnitGetFractionComplete(unitBeingBuilt))), cz2))
            ProjectileSetVelocity(BeamEndEntity2, -velX, -velY, -velZ)
            flipDirection = false
        else
            Warp(BeamEndEntity, Vector(cx2, (cy2 - (oy * UnitGetFractionComplete(unitBeingBuilt))), cz2))
            ProjectileSetVelocity(BeamEndEntity, -velX, -velY, -velZ)
            Warp(BeamEndEntity2, Vector(cx1, (cy1 - (oy * UnitGetFractionComplete(unitBeingBuilt))), cz1))
            ProjectileSetVelocity(BeamEndEntity2, velX, velY, velZ)
            flipDirection = true
        end
        WaitSeconds(0.5)
    end
end

function CreateDefaultBuildBeams(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local ox, oy, oz = EntityGetPositionXYZ(unitBeingBuilt)
    local BeamEndEntity = Entity()
    TrashAdd(BuildEffectsBag, BeamEndEntity)
    Warp(BeamEndEntity, Vector(ox, oy, oz))

    local BuildBeams = {}

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            local beamEffect = AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, builder.Army, BeamBuildEmtBp)
            table.insert(BuildBeams, beamEffect)
            TrashAdd(BuildEffectsBag, beamEffect)
        end
    end

    CreateEmitterOnEntity(BeamEndEntity, builder.Army, '/effects/emitters/sparks_08_emit.bp')
    local waitTime = RandomFloat(0.3, 1.5)

    while not EntityBeenDestroyed(builder) and not EntityBeenDestroyed(unitBeingBuilt) do
        local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)
        Warp(BeamEndEntity, Vector(ox + x, oy + y, oz + z))
        WaitSeconds(waitTime)
    end
end

function CreateAeonBuildBaseThread(unitBeingBuilt, builder, EffectsBag)
    local bp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(unitBeingBuilt)
    local mul = 0.5
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil
    WaitSeconds(0.1)

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    ProjectileSetScale(BuildBaseEffect, sx, sy * 1.5, sz)
    Warp(BuildBaseEffect, Vector(x, y, z))
    BuildBaseEffect:SetOrientation(unitBeingBuilt:GetOrientation(), true)
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)
    TrashAdd(EffectsBag, BuildBaseEffect)

    CreateEmitterOnEntity(BuildBaseEffect, builder.Army, '/effects/emitters/aeon_being_built_ambient_01_emit.bp')
        :SetEmitterCurveParam('X_POSITION_CURVE', 0, sx * 1.5)
        :SetEmitterCurveParam('Z_POSITION_CURVE', 0, sz * 1.5)

    CreateEmitterOnEntity(BuildBaseEffect, builder.Army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
        :ScaleEmitter((sx + sz) * 0.3)

    local slider = CreateSlider(unitBeingBuilt, 0)
    slider:SetWorldUnits(true)
    slider:SetGoal(0, -sy, 0)
    slider:SetSpeed(-1)

    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while not unitBeingBuilt.Dead and fraction < 1 do
        scale = 1.2 - MathPow(fraction, 4)
        ProjectileSetScale(BuildBaseEffect, sx * scale, 1.5 * sy * scale, sz * scale)
        slider:SetGoal(0, (fraction * sy - sy), 0)
        WaitSeconds(0.1)
        fraction = UnitGetFractionComplete(unitBeingBuilt)
    end

    slider:Destroy()
    BuildBaseEffect:Destroy()
end

local BeamBuildEmtBp = '/effects/emitters/build_beam_02_emit.bp'

function CreateCybranBuildBeams(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)

    -- if we got any bones that apply to this
    if BuildEffectBones then

        -- create one beam end and keep it
        if not builder.BuildBeamEnd then 
            -- construct entity and trash it when the engineer gets trashed
            builder.BuildBeamEnd = Entity()
            TrashAdd(builder.Trash, builder.BuildBeamEnd)
        end

        -- to local scope
        local army = builder.Army
        local beamEnd = builder.BuildBeamEnd

        -- hold up a bit for cinematics
        WaitSeconds(0.2)

        -- find a location and warp the beam
        local ox, oy, oz = EntityGetPositionXYZ(unitBeingBuilt)
        Warp(beamEnd, Vector(ox, oy, oz))

        -- attach emitters
        TrashAdd(BuildEffectsBag, CreateEmitterOnEntity(beamEnd, army, EffectTemplate.CybranBuildSparks01))
        TrashAdd(BuildEffectsBag, CreateEmitterOnEntity(beamEnd, army, EffectTemplate.CybranBuildFlash01))

        -- attach effects
        for i, BuildBone in BuildEffectBones do
            TrashAdd(BuildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, beamEnd, -1, builder.Army, BeamBuildEmtBp))
        end

        -- move them around
        while not EntityBeenDestroyed(builder) and not EntityBeenDestroyed(unitBeingBuilt) do

            -- get a new random position and warp
            local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)
            if beamEnd and not EntityBeenDestroyed(beamEnd) then
                Warp(beamEnd, Vector(ox + x, oy + y, oz + z))
            end

            WaitSeconds(0.4)
        end
    end
end

function SpawnBuildBots(builder, unitBeingBuilt, BuildEffectsBag)

    -- keeps track of the maximum number of build bots
    if not builder.BuildMaximumBots then 
        -- build power is converted into bots, clamp to 10
        builder.BuildMaximumBots = MathMin(MathCeil((10 + builder:GetBuildRate()) / 15), 10)
    end

    -- keeps track of the build bots themselves
    if not builder.BuildBots then
        builder.BuildBots = {}
    end

    -- to local scope
    local BuildBots = builder.BuildBots
    local BuildMaximumBots = builder.BuildMaximumBots
    local unitBeingBuiltArmy = unitBeingBuilt.Army or nil

    -- If is new, won't spawn build bots if they might accidentally capture the unit
    if unitBeingBuiltArmy and ( builder.Army == unitBeingBuiltArmy or IsHumanUnit(unitBeingBuilt) ) then

        local x, y, z = EntityGetPositionXYZ(builder)
        local q = builder:GetOrientation()

        -- iterate over the build bots
        for k = 1, BuildMaximumBots do 

            -- to local scope
            local bot = BuildBots[k]
            if (not bot) or (EntityBeenDestroyed(bot)) then
                -- make a new bot
                bot = CreateUnit('ura0001', builder.Army, x, y + 0.1 * k , z, q[1], q[2], q[3], q[4], 'Air')

                -- make bot unkillable
                bot:SetCanTakeDamage(false)
                bot:SetCanBeKilled(false)
                bot.spawnedBy = builder

                -- keep track of it
                BuildBots[k] = bot 
            end 

            -- change to build state
            ChangeState(bot, bot.BuildState)
        end

        return BuildBots, BuildMaximumBots
    end
end

function CreateCybranEngineerBuildEffects(builder, BuildBones, BuildBots, BuildEffectsBag)
    -- Create build constant build effect for each build effect bone defined
    if BuildBones and BuildBots then
        for _, vBone in BuildBones do
            for _, vEffect in  EffectTemplate.CybranBuildUnitBlink01 do
                TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, vBone, builder.Army, vEffect))
            end
            WaitSeconds(RandomFloat(0.2, 1))
        end

        if EntityBeenDestroyed(builder) then
            return
        end

        local i = 1
        for _, vBot in BuildBots do
            if not vBot or EntityBeenDestroyed(vBot) then
                continue
            end

            TrashAdd(BuildEffectsBag, AttachBeamEntityToEntity(builder, BuildBones[i], vBot, -1, builder.Army, '/effects/emitters/build_beam_03_emit.bp'))
            i = i + 1
        end
    end
end

function CreateCybranFactoryBuildEffects(builder, unitBeingBuilt, BuildBones, BuildEffectsBag)
    local BuildEffects = {
        '/effects/emitters/sparks_03_emit.bp',
        '/effects/emitters/flashes_01_emit.bp',
    }
    local UnitBuildEffects = {
        '/effects/emitters/build_cybran_spark_flash_04_emit.bp',
        '/effects/emitters/build_sparks_blue_02_emit.bp',
    }

    CreateCybranBuildBeams(builder, unitBeingBuilt, BuildBones.BuildEffectBones, BuildEffectsBag)

    for _, vB in BuildBones.BuildEffectBones do
        for _, vE in BuildEffects do
            TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, vB, builder.Army, vE))
        end
    end

    TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, BuildBones.BuildAttachBone, builder.Army, '/effects/emitters/cybran_factory_build_01_emit.bp'))

    -- Add sparks to the collision box of the unit being built
    local sx, sy, sz = 0
    while not unitBeingBuilt.Dead and UnitGetFractionComplete(unitBeingBuilt) < 1 do
        sx, sy, sz = unitBeingBuilt:GetRandomOffset(1)
        for _, vE in UnitBuildEffects do
            CreateEmitterOnEntity(unitBeingBuilt, builder.Army, vE):EffectOffsetEmitter(sx, sy, sz)
        end
        WaitSeconds(RandomFloat(0.1, 0.6))
    end
end

function CreateAeonConstructionUnitBuildingEffects(builder, unitBeingBuilt, BuildEffectsBag)
    TrashAdd(BuildEffectsBag, CreateEmitterOnEntity(builder, builder.Army, '/effects/emitters/aeon_build_01_emit.bp'))

    local beamEnd = Entity()
    TrashAdd(BuildEffectsBag, beamEnd)
    Warp(beamEnd, EntityGetPosition(unitBeingBuilt))

    for _, v in EffectTemplate.AeonBuildBeams01 do
        local beamEffect = AttachBeamEntityToEntity(builder, 0, beamEnd, -1, builder.Army, v)
        beamEffect:SetEmitterParam('POSITION_Z', 0.45)
        TrashAdd(BuildEffectsBag, beamEffect)
    end
end

function CreateAeonCommanderBuildingEffects(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)
    local beamEnd = Entity()
    TrashAdd(BuildEffectsBag, beamEnd)
    Warp(beamEnd, EntityGetPosition(unitBeingBuilt))

    for _, vBone in BuildEffectBones do
        TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, vBone, builder.Army, '/effects/emitters/aeon_build_02_emit.bp'))

        for _, v in EffectTemplate.AeonBuildBeams01 do
            local beamEffect = AttachBeamEntityToEntity(builder, vBone, beamEnd, -1, builder.Army, v)
            TrashAdd(BuildEffectsBag, beamEffect)
        end
    end
end

function CreateAeonFactoryBuildingEffects(builder, unitBeingBuilt, BuildEffectBones, BuildBone, EffectsBag)
    local bp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(builder, BuildBone)
    local mul = 1
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', 0, 0, 1, nil, nil, nil)
    if builder:IsPaused() then
        local fraction = UnitGetFractionComplete(unitBeingBuilt)
        local scale = 1 - MathPow(fraction, 2)
        ProjectileSetScale(BuildBaseEffect, sx * scale, 1.5 * sy * scale, sz * scale)
    else
        ProjectileSetScale(BuildBaseEffect, sx, 1.5 * sy, sz)
    end
    Warp(BuildBaseEffect, Vector(x, y - 0.05, z))
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)
    TrashAdd(EffectsBag, BuildBaseEffect)

    if not builder:IsPaused() then
        CreateEmitterOnEntity(BuildBaseEffect, builder.Army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        :SetEmitterCurveParam('X_POSITION_CURVE', 0, sx * 1.5)
        :SetEmitterCurveParam('Z_POSITION_CURVE', 0, sz * 1.5)

        CreateEmitterOnEntity(BuildBaseEffect, builder.Army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
        :ScaleEmitter((sx + sz) * 0.3)

        for _, vBone in BuildEffectBones do
            TrashAdd(EffectsBag, CreateAttachedEmitter(builder, vBone, builder.Army, '/effects/emitters/aeon_build_03_emit.bp'))
            for _, vBeam in EffectTemplate.AeonBuildBeams02 do
                local beamEffect = AttachBeamEntityToEntity(builder, vBone, builder, BuildBone, builder.Army, vBeam)
                TrashAdd(EffectsBag, beamEffect)
            end
        end
    end

    local slider = CreateSlider(unitBeingBuilt, 0)
    TrashAdd(unitBeingBuilt.Trash, slider)
    TrashAdd(EffectsBag, slider)
    slider:SetWorldUnits(true)
    if builder:IsPaused() then
        local fraction = UnitGetFractionComplete(unitBeingBuilt)
        slider:SetSpeed(0)
        slider:SetGoal(0, 0.5 * (fraction * sy - sy), 0)
    else
        slider:SetSpeed(-1)
        slider:SetGoal(0, -sy * 0.5, 0)
    end

    if not builder:IsPaused() then
        local fraction = UnitGetFractionComplete(unitBeingBuilt)
        local scale
        while not unitBeingBuilt.Dead and fraction < 1 and not IsDestroyed(slider) do
            scale = 1 - MathPow(fraction, 2)
            ProjectileSetScale(BuildBaseEffect, sx * scale, 1.5 * sy * scale, sz * scale)
            slider:SetGoal(0, 0.5 * (fraction * sy - sy), 0)
            WaitSeconds(0.1)
            fraction = UnitGetFractionComplete(unitBeingBuilt)
        end

        slider:Destroy()
        BuildBaseEffect:Destroy()
    end
end

function CreateSeraphimUnitEngineerBuildingEffects(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)
    for _, vBone in BuildEffectBones do
        TrashAdd(BuildEffectsBag, CreateAttachedEmitter(builder, vBone, builder.Army, '/effects/emitters/seraphim_build_01_emit.bp'))

        for _, v in EffectTemplate.SeraphimBuildBeams01 do
            local beamEffect = AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, builder.Army, v)
            TrashAdd(BuildEffectsBag, beamEffect)
        end
    end
end

function CreateSeraphimFactoryBuildingEffectsUnPause(builder, unitBeingBuilt, BuildEffectBones, BuildBone, EffectsBag)
    local bp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(builder, BuildBone)
    local mul = 1
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = (1 - UnitGetFractionComplete(unitBeingBuilt)) * bp.Physics.MeshExtentsY or (1 - UnitGetFractionComplete(unitBeingBuilt)) * sx + sz

    local slice = nil

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/SeraphimBuildEffect01/SeraphimBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    ProjectileSetScale(BuildBaseEffect, sx, 1, sz)
    BuildBaseEffect:SetOrientation(unitBeingBuilt:GetOrientation(), true)
    Warp(BuildBaseEffect, Vector(x, y - 0.05, z))
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)
    TrashAdd(EffectsBag, BuildBaseEffect)

    for _, vBone in BuildEffectBones do
        TrashAdd(EffectsBag, CreateAttachedEmitter(builder, vBone, builder.Army, '/effects/emitters/seraphim_build_01_emit.bp'))
        for _, vBeam in EffectTemplate.SeraphimBuildBeams01 do
            TrashAdd(EffectsBag, AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, builder.Army, vBeam))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_02_emit.bp'))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_03_emit.bp'))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_04_emit.bp'))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_05_emit.bp'))
        end
    end

    local slider = CreateSlider(unitBeingBuilt, 0)
    TrashAdd(unitBeingBuilt.Trash, slider)
    TrashAdd(EffectsBag, slider)
    slider:SetWorldUnits(true)
    slider:SetGoal(0, 0, 0)
    slider:SetSpeed(-1)
    WaitFor(slider)

    if not slider:BeenDestroyed() then
        slider:SetGoal(0, -sy, 0)
        slider:SetSpeed(0.05)
    end

    -- Wait till we are 80% done building, then snap our slider to
    while not unitBeingBuilt.Dead and UnitGetFractionComplete(unitBeingBuilt) < 0.8 do
        WaitSeconds(0.5)
    end

    if not unitBeingBuilt.Dead then
        if not EntityBeenDestroyed(BuildBaseEffect) then
            BuildBaseEffect:SetScaleVelocity(-0.6, -0.6, -0.6)
        end
        if not slider:BeenDestroyed() then
            slider:SetSpeed(1)
        end
        WaitSeconds(0.5)
    end

    if not EntityBeenDestroyed(BuildBaseEffect) then
        BuildBaseEffect:Destroy()
    end
end

function CreateSeraphimFactoryBuildingEffects(builder, unitBeingBuilt, BuildEffectBones, BuildBone, EffectsBag)
    local bp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(builder, BuildBone)
    local mul = 1
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz
    local sy_pause = (1 - UnitGetFractionComplete(unitBeingBuilt)) * bp.Physics.MeshExtentsY or (1 - UnitGetFractionComplete(unitBeingBuilt)) * sx + sz

    local slice = nil

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/SeraphimBuildEffect01/SeraphimBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    ProjectileSetScale(BuildBaseEffect, sx, 1, sz)
    BuildBaseEffect:SetOrientation(unitBeingBuilt:GetOrientation(), true)
    Warp(BuildBaseEffect, Vector(x, y - 0.05, z))
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)
    TrashAdd(EffectsBag, BuildBaseEffect)

    for _, vBone in BuildEffectBones do
        TrashAdd(EffectsBag, CreateAttachedEmitter(builder, vBone, builder.Army, '/effects/emitters/seraphim_build_01_emit.bp'))
        for _, vBeam in EffectTemplate.SeraphimBuildBeams01 do
            if not builder:IsPaused() then
                TrashAdd(EffectsBag, AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, builder.Army, vBeam))
            end
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_02_emit.bp'))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_03_emit.bp'))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_04_emit.bp'))
            TrashAdd(EffectsBag, CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, '/effects/emitters/seraphim_being_built_ambient_05_emit.bp'))
        end
    end

    local slider = CreateSlider(unitBeingBuilt, 0)
    TrashAdd(unitBeingBuilt.Trash, slider)
    TrashAdd(EffectsBag, slider)
    slider:SetWorldUnits(true)
    if builder:IsPaused() then
        slider:SetGoal(0, sy_pause, 0)
        slider:SetSpeed(0)
    else
        slider:SetGoal(0, sy, 0)
        slider:SetSpeed(-1)
        WaitFor(slider)

        if not slider:BeenDestroyed() then
            slider:SetGoal(0, 0, 0)
            slider:SetSpeed(0.05)
        end

        -- Wait till we are 80% done building, then snap our slider to
        while not unitBeingBuilt.Dead and UnitGetFractionComplete(unitBeingBuilt) < 0.8 do
            WaitSeconds(0.5)
        end

        if not unitBeingBuilt.Dead then
            if not EntityBeenDestroyed(BuildBaseEffect) then
                BuildBaseEffect:SetScaleVelocity(-0.6, -0.6, -0.6)
            end
            if not slider:BeenDestroyed() then
                slider:SetSpeed(2)
            end
            WaitSeconds(0.5)
        end

        if not slider:BeenDestroyed() then
            slider:Destroy()
        end

        if not EntityBeenDestroyed(BuildBaseEffect) then
            BuildBaseEffect:Destroy()
        end
    end
end

function CreateSeraphimBuildThread(unitBeingBuilt, builder, EffectsBag, scaleFactor)
    local bp = unitBeingBuilt.Blueprint
    local x, y, z = EntityGetPositionXYZ(unitBeingBuilt)
    local mul = 0.5
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil
    WaitSeconds(0.1)

    local BuildBaseEffect = UnitCreateProjectile(unitBeingBuilt, '/effects/entities/SeraphimBuildEffect01/SeraphimBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    ProjectileSetScale(BuildBaseEffect, sx, 1, sz)
    BuildBaseEffect:SetOrientation(unitBeingBuilt:GetOrientation(), true)
    Warp(BuildBaseEffect, Vector(x, y, z))
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)
    TrashAdd(EffectsBag, BuildBaseEffect)

    local BuildEffectBaseEmitters = {
        '/effects/emitters/seraphim_being_built_ambient_01_emit.bp',
    }

    local BuildEffectsEmitters = {
        '/effects/emitters/seraphim_being_built_ambient_02_emit.bp',
        '/effects/emitters/seraphim_being_built_ambient_03_emit.bp',
        '/effects/emitters/seraphim_being_built_ambient_04_emit.bp',
        '/effects/emitters/seraphim_being_built_ambient_05_emit.bp',
    }

    local AdjustedEmitters = {}
    local effect = nil
    for _, vEffect in BuildEffectsEmitters do
        effect = CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, vEffect):ScaleEmitter(scaleFactor)
        table.insert(AdjustedEmitters, effect)
        TrashAdd(EffectsBag, effect)
    end

    for _, vEffect in BuildEffectBaseEmitters do
        effect = CreateAttachedEmitter(BuildBaseEffect, -1, builder.Army, vEffect):ScaleEmitter(scaleFactor)
        table.insert(AdjustedEmitters, effect)
        TrashAdd(EffectsBag, effect)
    end

    -- Poll the unit being built every 0.5 a second to adjust the effects to match
    local fractionComplete = UnitGetFractionComplete(unitBeingBuilt)
    local unitScaleMetric = unitBeingBuilt:GetFootPrintSize() * 0.65
    while not unitBeingBuilt.Dead and fractionComplete < 1.0 do
        WaitSeconds(0.5)
        fractionComplete = UnitGetFractionComplete(unitBeingBuilt)
        for _, vEffect in AdjustedEmitters do
            vEffect:ScaleEmitter(scaleFactor + (unitScaleMetric * fractionComplete))
        end
    end

    CreateLightParticleIntel(unitBeingBuilt, -1, unitBeingBuilt.Army, unitBeingBuilt:GetFootPrintSize() * 7, 8, 'glow_02', 'ramp_blue_22')

    WaitSeconds(0.5)
    BuildBaseEffect:Destroy()
end

function CreateSeraphimBuildBaseThread(unitBeingBuilt, builder, EffectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, EffectsBag, 1)
end

function CreateSeraphimExperimentalBuildBaseThread(unitBeingBuilt, builder, EffectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, EffectsBag, 2)
end

function CreateAdjacencyBeams(unit, adjacentUnit, AdjacencyBeamsBag)
    local info = {
        Unit = adjacentUnit,
        Trash = TrashBag(),
    }

    table.insert(AdjacencyBeamsBag, info)

    local uBp = unit.Blueprint
    local aBp = adjacentUnit.Blueprint
    local faction = uBp.General.FactionName

    -- Determine which effects we will be using
    local nodeMesh = nil
    local beamEffect = nil
    local emitterNodeEffects = {}
    local numNodes = 2
    local nodeList = {}
    local validAdjacency = true


    local unitPos = EntityGetPosition(unit)
    local adjPos = EntityGetPosition(adjacentUnit)

    -- Create hub start/end and all midpoint nodes
    local unitHub = {
        entity = Entity{},
        pos = EntityGetPosition(unit),
    }
    local adjacentHub = {
        entity = Entity{},
        pos = EntityGetPosition(adjacentUnit),
    }

    local spec = {
        Owner = unit,
    }

    if faction == 'Aeon' then
        nodeMesh = '/effects/entities/aeonadjacencynode/aeonadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_aeon_beam_0' .. Utils.GetRandomInt(1, 3) .. '_emit.bp'
        numNodes = 3
    elseif faction == 'Cybran' then
        nodeMesh = '/effects/entities/cybranadjacencynode/cybranadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_cybran_beam_01_emit.bp'
    elseif faction == 'UEF' then
        nodeMesh = '/effects/entities/uefadjacencynode/uefadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_uef_beam_01_emit.bp'
    elseif faction == 'Seraphim' then
        nodeMesh = '/effects/entities/seraphimadjacencynode/seraphimadjacencynode_mesh'
        table.insert(emitterNodeEffects, EffectTemplate.SAdjacencyAmbient01)
        if  Utils.GetDistanceBetweenTwoVectors(unitHub.pos, adjacentHub.pos) < 2.5 then
            numNodes = 1
        else
            numNodes = 3
            table.insert(emitterNodeEffects, EffectTemplate.SAdjacencyAmbient02)
            table.insert(emitterNodeEffects, EffectTemplate.SAdjacencyAmbient03)
        end
    end

    for i = 1, numNodes do
        local node =
        {
            entity = Entity(spec),
            pos = {0, 0, 0},
            mesh = nil,
        }
        node.entity:SetVizToNeutrals('Intel')
        node.entity:SetVizToEnemies('Intel')
        table.insert(nodeList, node)
    end

    local verticalOffset = 0.05

    -- Move Unit Pos towards adjacent unit by bounding box size
    local uBpSizeX = uBp.SizeX * 0.5
    local uBpSizeZ = uBp.SizeZ * 0.5
    local aBpSizeX = aBp.SizeX * 0.5
    local aBpSizeZ = aBp.SizeZ * 0.5

    -- To Determine positioning, need to use the bounding box or skirt size
    local uBpSkirtX = uBp.Physics.SkirtSizeX * 0.5
    local uBpSkirtZ = uBp.Physics.SkirtSizeZ * 0.5
    local aBpSkirtX = aBp.Physics.SkirtSizeX * 0.5
    local aBpSkirtZ = aBp.Physics.SkirtSizeZ * 0.5

    -- Get edge corner positions, {TOP, LEFT, BOTTOM, RIGHT}
    local unitSkirtBounds = {
        unitHub.pos[3] - uBpSkirtZ,
        unitHub.pos[1] - uBpSkirtX,
        unitHub.pos[3] + uBpSkirtZ,
        unitHub.pos[1] + uBpSkirtX,
    }
    local adjacentSkirtBounds = {
        adjacentHub.pos[3] - aBpSkirtZ,
        adjacentHub.pos[1] - aBpSkirtX,
        adjacentHub.pos[3] + aBpSkirtZ,
        adjacentHub.pos[1] + aBpSkirtX,
    }

    -- Figure out the best matching ogrid position on units bounding box
    -- depending on it's skirt size
    -- Unit bottom or top skirt is aligned to adjacent unit
    if unitSkirtBounds[3] == adjacentSkirtBounds[1] or unitSkirtBounds[1] == adjacentSkirtBounds[3] then

        local sharedSkirtLower = unitSkirtBounds[4] - (unitSkirtBounds[4] - adjacentSkirtBounds[2])
        local sharedSkirtUpper = unitSkirtBounds[4] - (unitSkirtBounds[4] - adjacentSkirtBounds[4])
        local sharedSkirtLen = sharedSkirtUpper - sharedSkirtLower

        -- Depending on shared skirt bounds, determine the position of unit hub
        -- Find out how many times the shared skirt fits into the unit hub shared skirt
        local numAdjSkirtsOnUnitSkirt = (uBpSkirtX * 2) / sharedSkirtLen
        local numUnitSkirtsOnAdjSkirt = (aBpSkirtX * 2) / sharedSkirtLen

         -- Z-offset, offset adjacency hub positions the proper direction
        if unitSkirtBounds[3] == adjacentSkirtBounds[1] then
            unitHub.pos[3] = unitHub.pos[3] + uBpSizeZ
            adjacentHub.pos[3] = adjacentHub.pos[3] - aBpSizeZ
        else -- unitSkirtBounds[1] == adjacentSkirtBounds[3]
            unitHub.pos[3] = unitHub.pos[3] - uBpSizeZ
            adjacentHub.pos[3] = adjacentHub.pos[3] + aBpSizeZ
        end

        -- X-offset, Find the shared adjacent x position range
        -- If we have more than skirt on this section, then we need to adjust the x position of the unit hub
        if numAdjSkirtsOnUnitSkirt > 1 or numUnitSkirtsOnAdjSkirt < 1 then
            local uSkirtLen = (unitSkirtBounds[4] - unitSkirtBounds[2]) * 0.5           -- Unit skirt length
            local uGridUnitSize = (uBpSizeX * 2) / uSkirtLen                            -- Determine one grid of adjacency along that length
            local xoffset = MathAbs(unitSkirtBounds[2] - adjacentSkirtBounds[2]) * 0.5 -- Get offset of the unit along the skirt
            unitHub.pos[1] = (unitHub.pos[1] - uBpSizeX) + (xoffset * uGridUnitSize) + (uGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

        -- If we have more than skirt on this section, then we need to adjust the x position of the adjacent hub
        if numUnitSkirtsOnAdjSkirt > 1  or numAdjSkirtsOnUnitSkirt < 1 then
            local aSkirtLen = (adjacentSkirtBounds[4] - adjacentSkirtBounds[2]) * 0.5   -- Adjacent unit skirt length
            local aGridUnitSize = (aBpSizeX * 2) / aSkirtLen                            -- Determine one grid of adjacency along that length ??
            local xoffset = MathAbs(adjacentSkirtBounds[2] - unitSkirtBounds[2]) * 0.5    -- Get offset of the unit along the adjacent unit
            adjacentHub.pos[1] = (adjacentHub.pos[1] - aBpSizeX) + (xoffset * aGridUnitSize) + (aGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

    -- Unit right or top left is aligned to adjacent unit
    elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] or unitSkirtBounds[2] == adjacentSkirtBounds[4] then
        local sharedSkirtLower = unitSkirtBounds[3] - (unitSkirtBounds[3] - adjacentSkirtBounds[1])
        local sharedSkirtUpper = unitSkirtBounds[3] - (unitSkirtBounds[3] - adjacentSkirtBounds[3])
        local sharedSkirtLen = sharedSkirtUpper - sharedSkirtLower

        -- Depending on shared skirt bounds, determine the position of unit hub
        -- Find out how many times the shared skirt fits into the unit hub shared skirt
        local numAdjSkirtsOnUnitSkirt = (uBpSkirtX * 2) / sharedSkirtLen
        local numUnitSkirtsOnAdjSkirt = (aBpSkirtX * 2) / sharedSkirtLen

        -- X-offset
        if unitSkirtBounds[4] == adjacentSkirtBounds[2] then
            unitHub.pos[1] = unitHub.pos[1] + uBpSizeX
            adjacentHub.pos[1] = adjacentHub.pos[1] - aBpSizeX
        else -- unitSkirtBounds[2] == adjacentSkirtBounds[4]
            unitHub.pos[1] = unitHub.pos[1] - uBpSizeX
            adjacentHub.pos[1] = adjacentHub.pos[1] + aBpSizeX
        end

        -- Z-offset, Find the shared adjacent x position range
        -- If we have more than skirt on this section, then we need to adjust the x position of the unit hub
        if numAdjSkirtsOnUnitSkirt > 1 or numUnitSkirtsOnAdjSkirt < 1 then
            local uSkirtLen = (unitSkirtBounds[3] - unitSkirtBounds[1]) * 0.5           -- Unit skirt length
            local uGridUnitSize = (uBpSizeZ * 2) / uSkirtLen                            -- Determine one grid of adjacency along that length
            local zoffset = MathAbs(unitSkirtBounds[1] - adjacentSkirtBounds[1]) * 0.5 -- Get offset of the unit along the skirt
            unitHub.pos[3] = (unitHub.pos[3] - uBpSizeZ) + (zoffset * uGridUnitSize) + (uGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

        -- If we have more than skirt on this section, then we need to adjust the x position of the adjacent hub
        if numUnitSkirtsOnAdjSkirt > 1 or numAdjSkirtsOnUnitSkirt < 1 then
            local aSkirtLen = (adjacentSkirtBounds[3] - adjacentSkirtBounds[1]) * 0.5   -- Adjacent unit skirt length
            local aGridUnitSize = (aBpSizeZ * 2) / aSkirtLen                            -- Determine one grid of adjacency along that length ??
            local zoffset = MathAbs(adjacentSkirtBounds[1] - unitSkirtBounds[1]) * 0.5    -- Get offset of the unit along the adjacent unit
            adjacentHub.pos[3] = (adjacentHub.pos[3] - aBpSizeZ) + (zoffset * aGridUnitSize) + (aGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end
    end

    -- Setup our midpoint positions
    if faction == 'Aeon' or faction == 'Seraphim' then
        local DirectionVec = Utils.GetDifferenceVector(unitHub.pos, adjacentHub.pos)
        local Dist = Utils.GetDistanceBetweenTwoVectors(unitHub.pos, adjacentHub.pos)
        local PerpVec = Utils.Cross(DirectionVec, Vector(0, 0.35, 0))
        local segmentLen = 1 / (numNodes + 1)
        local halfDist = Dist * 0.5

        if Utils.GetRandomInt(0, 1) == 1 then
            PerpVec[1] = -PerpVec[1]
            PerpVec[2] = -PerpVec[2]
            PerpVec[3] = -PerpVec[3]
        end

        local offsetMul = 0.15

        for i = 1, numNodes do
            local segmentMul = i * segmentLen

            if segmentMul <= 0.5 then
                offsetMul = offsetMul + 0.12
            else
                offsetMul = offsetMul - 0.12
            end

            nodeList[i].pos = {
                unitHub.pos[1] - (DirectionVec[1] * segmentMul) - (PerpVec[1] * offsetMul),
                nil,
                unitHub.pos[3] - (DirectionVec[3] * segmentMul) - (PerpVec[3] * offsetMul),
            }
        end
    elseif faction == 'Cybran' then
        if unitPos[1] == adjPos[1] or unitPos[3] == adjPos[3] then
            local Dist = Utils.GetDistanceBetweenTwoVectors(unitHub.pos, adjacentHub.pos)
            local DirectionVec = Utils.GetScaledDirectionVector(unitHub.pos, adjacentHub.pos, RandomFloat(0.35, Dist * 0.48))
            DirectionVec[2] = 0
            local PerpVec = Utils.Cross(DirectionVec, Vector(0, RandomFloat(0.2, 0.35), 0))

            if Utils.GetRandomInt(0, 1) == 1 then
                PerpVec[1] = -PerpVec[1]
                PerpVec[2] = -PerpVec[2]
                PerpVec[3] = -PerpVec[3]
            end

            -- Initialize 2 midpoint segments
            nodeList[1].pos = {unitHub.pos[1] - DirectionVec[1], unitHub.pos[2] - DirectionVec[2], unitHub.pos[3] - DirectionVec[3]}
            nodeList[2].pos = {adjacentHub.pos[1] + DirectionVec[1], adjacentHub.pos[2] + DirectionVec[2], adjacentHub.pos[3] + DirectionVec[3]}

            -- Offset beam positions
            nodeList[1].pos[1] = nodeList[1].pos[1] - PerpVec[1]
            nodeList[1].pos[3] = nodeList[1].pos[3] - PerpVec[3]
            nodeList[2].pos[1] = nodeList[2].pos[1] + PerpVec[1]
            nodeList[2].pos[3] = nodeList[2].pos[3] + PerpVec[3]

            unitHub.pos[1] = unitHub.pos[1] - PerpVec[1]
            unitHub.pos[3] = unitHub.pos[3] - PerpVec[3]
            adjacentHub.pos[1] = adjacentHub.pos[1] + PerpVec[1]
            adjacentHub.pos[3] = adjacentHub.pos[3] + PerpVec[3]
        else
            -- Unit bottom skirt is on top skirt of adjacent unit
            if unitSkirtBounds[3] == adjacentSkirtBounds[1] then
                nodeList[1].pos[1] = unitHub.pos[1]
                nodeList[2].pos[1] = adjacentHub.pos[1]
                nodeList[1].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) - (RandomFloat(0, 1))
                nodeList[2].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) + (RandomFloat(0, 1))
            elseif unitSkirtBounds[1] == adjacentSkirtBounds[3] then
                nodeList[1].pos[1] = unitHub.pos[1]
                nodeList[2].pos[1] = adjacentHub.pos[1]
                nodeList[1].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) + (RandomFloat(0, 1))
                nodeList[2].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) - (RandomFloat(0, 1))
            elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] then
                nodeList[1].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) - (RandomFloat(0, 1))
                nodeList[2].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) + (RandomFloat(0, 1))
                nodeList[1].pos[3] = unitHub.pos[3]
                nodeList[2].pos[3] = adjacentHub.pos[3]
            elseif unitSkirtBounds[2] == adjacentSkirtBounds[4] then
                nodeList[1].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) + (RandomFloat(0, 1))
                nodeList[2].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) - (RandomFloat(0, 1))
                nodeList[1].pos[3] = unitHub.pos[3]
                nodeList[2].pos[3] = adjacentHub.pos[3]
            else
                validAdjacency = false
            end
        end
    elseif faction == 'UEF' then
        if unitPos[1] == adjPos[1] or unitPos[3] == adjPos[3] then
            local DirectionVec = Utils.GetScaledDirectionVector(unitHub.pos, adjacentHub.pos, 0.35)
            DirectionVec[2] = 0
            local PerpVec = Utils.Cross(DirectionVec, Vector(0, 0.35, 0))
            if Utils.GetRandomInt(0, 1) == 1 then
                PerpVec[1] = -PerpVec[1]
                PerpVec[2] = -PerpVec[2]
                PerpVec[3] = -PerpVec[3]
            end

            -- Initialize 2 midpoint segments
            for _, v in nodeList do
                v.pos = Utils.GetMidPoint(unitHub.pos, adjacentHub.pos)
            end

            -- Offset beam positions
            nodeList[1].pos[1] = nodeList[1].pos[1] - PerpVec[1]
            nodeList[1].pos[3] = nodeList[1].pos[3] - PerpVec[3]
            nodeList[2].pos[1] = nodeList[2].pos[1] + PerpVec[1]
            nodeList[2].pos[3] = nodeList[2].pos[3] + PerpVec[3]

            unitHub.pos[1] = unitHub.pos[1] - PerpVec[1]
            unitHub.pos[3] = unitHub.pos[3] - PerpVec[3]
            adjacentHub.pos[1] = adjacentHub.pos[1] + PerpVec[1]
            adjacentHub.pos[3] = adjacentHub.pos[3] + PerpVec[3]
        else
            -- Unit bottom skirt is on top skirt of adjacent unit
            if unitSkirtBounds[3] == adjacentSkirtBounds[1] or unitSkirtBounds[1] == adjacentSkirtBounds[3] then
                nodeList[1].pos[1] = unitHub.pos[1]
                nodeList[2].pos[1] = adjacentHub.pos[1]
                nodeList[1].pos[3] = (unitHub.pos[3] + adjacentHub.pos[3]) * 0.5
                nodeList[2].pos[3] = (unitHub.pos[3] + adjacentHub.pos[3]) * 0.5

            -- Unit right skirt is on left skirt of adjacent unit
            elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] or unitSkirtBounds[2] == adjacentSkirtBounds[4] then
                nodeList[1].pos[1] = (unitHub.pos[1] + adjacentHub.pos[1]) * 0.5
                nodeList[2].pos[1] = (unitHub.pos[1] + adjacentHub.pos[1]) * 0.5
                nodeList[1].pos[3] = unitHub.pos[3]
                nodeList[2].pos[3] = adjacentHub.pos[3]
            else
                validAdjacency = false
            end
        end
    end

    if validAdjacency then
        -- Offset beam positions above the ground at current positions terrain height
        for _, v in nodeList do
            v.pos[2] = GetTerrainHeight(v.pos[1], v.pos[3]) + verticalOffset
        end

        unitHub.pos[2] = GetTerrainHeight(unitHub.pos[1], unitHub.pos[3]) + verticalOffset
        adjacentHub.pos[2] = GetTerrainHeight(adjacentHub.pos[1], adjacentHub.pos[3]) + verticalOffset

        -- Set the mesh of the entity and attach any node effects
        for i = 1, numNodes do
            nodeList[i].entity:SetMesh(nodeMesh, false)
            nodeList[i].mesh = true
            if emitterNodeEffects[i] ~= nil and not table.empty(emitterNodeEffects[i]) then
                for _, vEmit in emitterNodeEffects[i] do
                    emit = CreateAttachedEmitter(nodeList[i].entity, 0, unit.Army, vEmit)
                    TrashAdd(info.Trash, emit)
                    TrashAdd(unit.Trash, emit)
                end
            end
        end

        -- Insert start and end points into our list
        table.insert(nodeList, 1, unitHub)
        table.insert(nodeList, adjacentHub)

        -- Warp everything to its final position
        for i = 1, numNodes + 2 do
            Warp(nodeList[i].entity, nodeList[i].pos)
            TrashAdd(info.Trash, nodeList[i].entity)
            TrashAdd(unit.Trash, nodeList[i].entity)
        end

        -- Attach beams to the adjacent unit
        for i = 1, numNodes + 1 do
            if nodeList[i].mesh ~= nil then
                local vec = Utils.GetDirectionVector(Vector(nodeList[i].pos[1], nodeList[i].pos[2], nodeList[i].pos[3]), Vector(nodeList[i + 1].pos[1], nodeList[i + 1].pos[2], nodeList[i + 1].pos[3]))
                nodeList[i].entity:SetOrientation(OrientFromDir(vec), true)
            end
            if beamEffect then
                local beam = AttachBeamEntityToEntity(nodeList[i].entity, -1, nodeList[i + 1].entity, -1, unit.Army, beamEffect)
                TrashAdd(info.Trash, beam)
                TrashAdd(unit.Trash, beam)
            end
        end
    end
end

function PlaySacrificingEffects(unit, target_unit)
    local bp = unit.Blueprint
    local faction = bp.General.FactionName

    if faction == 'Aeon' then
        for _, v in EffectTemplate.ASacrificeOfTheAeon01 do
            TrashAdd(unit.Trash, CreateEmitterOnEntity(unit, unit.Army, v))
        end
    end
end

function PlaySacrificeEffects(unit, target_unit)
    local bp = unit.Blueprint
    local faction = bp.General.FactionName

    if faction == 'Aeon' then
        for _, v in EffectTemplate.ASacrificeOfTheAeon02 do
            CreateEmitterAtEntity(target_unit, unit.Army, v)
        end
    end
end

function PlayReclaimEffects(reclaimer, reclaimed, BuildEffectBones, EffectsBag)
    local pos = EntityGetPosition(reclaimed)
    pos[2] = GetTerrainHeight(pos[1], pos[3])

    local beamEnd = Entity()
    TrashAdd(EffectsBag, beamEnd)
    Warp(beamEnd, pos)

    for _, vBone in BuildEffectBones do
        for _, vEmit in EffectTemplate.ReclaimBeams do
            local beamEffect = AttachBeamEntityToEntity(reclaimer, vBone, beamEnd, -1, reclaimer.Army, vEmit)
            TrashAdd(EffectsBag, beamEffect)
        end
    end

    for _, v in EffectTemplate.ReclaimObjectAOE do
        TrashAdd(EffectsBag, CreateEmitterOnEntity(reclaimed, reclaimer.Army, v))
    end
end

function PlayReclaimEndEffects(reclaimer, reclaimed)
    local army = -1
    if reclaimer then
        army = reclaimer.Army
    end
    for _, v in EffectTemplate.ReclaimObjectEnd do
        CreateEmitterAtEntity(reclaimed, army, v)
    end

    CreateLightParticleIntel(reclaimed, -1, army, 4, 6, 'glow_02', 'ramp_flare_02')
end

function PlayCaptureEffects(capturer, captive, BuildEffectBones, EffectsBag)
    for _, vBone in BuildEffectBones do
        for _, vEmit in EffectTemplate.CaptureBeams do
            local beamEffect = AttachBeamEntityToEntity(capturer, vBone, captive, -1, capturer.Army, vEmit)
            TrashAdd(EffectsBag, beamEffect)
        end
    end
end

function CreateCybranQuantumGateEffect(unit, bone1, bone2, TrashBag, startwaitSeed)
    -- Adding a quick wait here so that unit bone positions are correct
    WaitSeconds(startwaitSeed)

    local BeamEmtBp = '/effects/emitters/cybran_gate_beam_01_emit.bp'
    local pos1 = EntityGetPosition(unit, bone1)
    local pos2 = EntityGetPosition(unit, bone2)
    pos1[2] = pos1[2] - 0.72
    pos2[2] = pos2[2] - 0.72

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamStartEntity = UnitCreateProjectile(unit, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    TrashAdd(TrashBag, BeamStartEntity)
    Warp(BeamStartEntity, pos1)

    local BeamEndEntity = UnitCreateProjectile(unit, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    TrashAdd(TrashBag, BeamEndEntity)
    Warp(BeamEndEntity, pos2)

    -- Create beam effect
    TrashAdd(TrashBag, AttachBeamEntityToEntity(BeamStartEntity, -1, BeamEndEntity, -1, unit.Army, BeamEmtBp))

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velY = 1
    ProjectileSetVelocity(BeamEndEntity, 0, velY, 0)

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not EntityBeenDestroyed(unit) do

        if flipDirection then
            ProjectileSetVelocity(BeamStartEntity, 0, velY, 0)
            ProjectileSetVelocity(BeamEndEntity, 0, velY, 0)
            flipDirection = false
        else
            ProjectileSetVelocity(BeamStartEntity, 0, -velY, 0)
            ProjectileSetVelocity(BeamEndEntity, 0, -velY, 0)
            flipDirection = true
        end
        WaitSeconds(1.5)
    end
end

function CreateEnhancementEffectAtBone(unit, bone, TrashBag)
    for _, vEffect in EffectTemplate.UpgradeBoneAmbient do
        TrashAdd(TrashBag, CreateAttachedEmitter(unit, bone, unit.Army, vEffect))
    end
end

function CreateEnhancementUnitAmbient(unit, bone, TrashBag)
    for _, vEffect in EffectTemplate.UpgradeUnitAmbient do
        TrashAdd(TrashBag, CreateAttachedEmitter(unit, bone, unit.Army, vEffect))
    end
end

function CleanupEffectBag(self, EffectBag)
    for _, v in self[EffectBag] do
        v:Destroy()
    end
    self[EffectBag] = {}
end

function SeraphimRiftIn(unit)
    unit:HideBone(0, true)

    for _, v in EffectTemplate.SerRiftIn_Small do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
    WaitSeconds (2.0)

    CreateLightParticle(unit, -1, unit.Army, 4, 15, 'glow_05', 'ramp_jammer_01')
    WaitSeconds (0.1)

    unit:ShowBone(0, true)
    WaitSeconds (0.25)

    for _, v in EffectTemplate.SerRiftIn_SmallFlash do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
end

function SeraphimRiftInLarge(unit)
    unit:HideBone(0, true)

    for _, v in EffectTemplate.SerRiftIn_Large do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
    WaitSeconds (2.0)

    CreateLightParticle(unit, -1, unit.Army, 25, 15, 'glow_05', 'ramp_jammer_01')
    WaitSeconds (0.1)

    unit:ShowBone(0, true)
    WaitSeconds (0.25)

    for _, v in EffectTemplate.SerRiftIn_LargeFlash do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
end

function CybranBuildingInfection(unit)
    for _, v in EffectTemplate.CCivilianBuildingInfectionAmbient do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
end

function CybranQaiShutdown(unit)
    for _, v in EffectTemplate.CQaiShutdown do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
end

function AeonHackACU(unit)
    for _, v in EffectTemplate.AeonOpHackACU do
        CreateAttachedEmitter (unit, -1, unit.Army, v)
    end
end

-- New function for insta capture fix
function IsHumanUnit(self)
    for _, Army in ScenarioInfo.ArmySetup do
        if Army.ArmyIndex == self.Army then
            if Army.Human == true then
                return true
            else
                return false
            end
        end
    end
end

function PlayTeleportChargingEffects(unit, TeleportDestination, EffectsBag, teleDelay)
    -- Plays teleport effects for the given unit
    if not unit then
        return
    end

    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)

    TeleportDestination = TeleportLocationToSurface(TeleportDestination)

    -- Play tele FX at unit location
    if bp.Display.TeleportEffects.PlayChargeFxAtUnit ~= false then
        unit:PlayUnitAmbientSound('TeleportChargingAtUnit')

        if faction == 'UEF' then
            -- We recycle the teleport destination effects since they are way more epic
            unit.TeleportChargeBag = {}
            local telefx = EffectTemplate.UEFTeleportCharge02
            for _, v in telefx do
                local fx = CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2) -- To make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
                table.insert(unit.TeleportChargeBag, fx)
                TrashAdd(EffectsBag, fx)
            end

            -- Make steam FX
            local totalBones = unit:GetBoneCount() - 1
            for _, v in EffectTemplate.UnitTeleportSteam01 do
                for bone = 1, totalBones do
                    local emitter = CreateAttachedEmitter(unit, bone, unit.Army, v):SetEmitterParam('Lifetime', 9999) -- Adjust the lifetime so we always teleport before its done

                    table.insert(unit.TeleportChargeBag, emitter)
                    TrashAdd(EffectsBag, emitter)
                end
            end
        -- Use a per-bone FX construction rather than wrap-around for the non-UEF factions
        elseif faction == 'Cybran' then
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.CybranTeleportCharge01, EffectsBag)
        elseif faction == 'Seraphim' then
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.SeraphimTeleportCharge01, EffectsBag)
        else
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.GenericTeleportCharge01, EffectsBag)
        end
    end

    if teleDelay then
        WaitTicks(teleDelay * 10)
    end

    -- Play tele FX at destination, including sounds
    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        -- Customized version of PlayUnitAmbientSound() from unit.lua to play sound at target destination
        local sound = 'TeleportChargingAtDestination'
        local sndEnt = false

        unit.TeleportSoundChargeBag = {}
        if sound and bp.Audio[sound] then
            if not unit.AmbientSounds then
                unit.AmbientSounds = {}
            end
            if not unit.AmbientSounds[sound] then
                sndEnt = Entity {}
                unit.AmbientSounds[sound] = sndEnt
                TrashAdd(unit.Trash, sndEnt)
                Warp(sndEnt, TeleportDestination) -- Warping sound entity to destination so ambient sound plays there (and not at unit)
                table.insert(unit.TeleportSoundChargeBag, sndEnt)
            end
            unit.AmbientSounds[sound]:SetAmbientSound(bp.Audio[sound], nil)
        end

        -- Using a barebone entity to position effects, it is destroyed afterwards
        local TeleportDestFxEntity = Entity()
        Warp(TeleportDestFxEntity, TeleportDestination)
        unit.TeleportDestChargeBag = {}

        if faction == 'UEF' then
            local telefx = EffectTemplate.UEFTeleportCharge02
            for _, v in telefx do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2) -- To make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
                table.insert(unit.TeleportDestChargeBag, fx)
                TrashAdd(EffectsBag, fx)
            end
        elseif faction == 'Cybran' then
            local pos = table.copy(TeleportDestination)
            pos[2] = pos[2] + Yoffset -- Make sure sphere isn't half in the ground
            local sphere = TeleportCreateCybranSphere(unit, pos, 0.01)

            local telefx = EffectTemplate.CybranTeleportCharge02

            for _, v in telefx do
                local fx = CreateEmitterAtEntity(sphere, unit.Army, v)
                fx:ScaleEmitter(0.01 * unit.TeleportCybranSphereScale)
                table.insert(unit.TeleportDestChargeBag, fx)
                TrashAdd(EffectsBag, fx)
            end
        elseif faction == 'Seraphim' then
            local telefx = EffectTemplate.SeraphimTeleportCharge02
            for _, v in telefx do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.01)
                table.insert(unit.TeleportDestChargeBag, fx)
                TrashAdd(EffectsBag, fx)
            end

            TeleportDestFxEntity:Destroy()
        else
            local telefx = EffectTemplate.GenericTeleportCharge02
            for _, v in telefx do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.01)
                table.insert(unit.TeleportDestChargeBag, fx)
                TrashAdd(EffectsBag, fx)
            end

            TeleportDestFxEntity:Destroy()
        end
    end
end

function TeleportGetUnitYOffset(unit)
    -- Returns how high to create effects to make the effects appear in the center of the unit
    local bp = unit.Blueprint
    return bp.Display.TeleportEffects.FxChargeAtDestOffsetY or ((bp.Physics.MeshExtentsY or bp.SizeY or 2) / 2)
end

function TeleportGetUnitSizes(unit)
    -- Returns the sizes of the unit, to be used for teleportation effects
    local bp = unit.Blueprint
    return (bp.Display.TeleportEffects.FxSizeX or bp.Physics.MeshExtentsX or bp.SizeX or 1),
           (bp.Display.TeleportEffects.FxSizeY or bp.Physics.MeshExtentsY or bp.SizeY or 1),
           (bp.Display.TeleportEffects.FxSizeZ or bp.Physics.MeshExtentsZ or bp.SizeZ or 1),
           (bp.Display.TeleportEffects.FxOffsetX or bp.CollisionOffsetX or 0),
           (bp.Display.TeleportEffects.FxOffsetY or bp.CollisionOffsetY or 0),
           (bp.Display.TeleportEffects.FxOffsetZ or bp.CollisionOffsetZ or 0)
end

function TeleportLocationToSurface(loc)
    -- Takes the given location, adjust the Y value to the surface height on that location
    local pos = table.copy(loc)
    pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
    return pos
end

function TeleportShowChargeUpFxAtUnit(unit, effectTemplate, EffectsBag)
    -- Creates charge up effects at the unit
    local bp = unit.Blueprint
    local bones = bp.Display.TeleportEffects.ChargeFxAtUnitBones or {Bone = 0, Offset = {0, 0.25, 0}, }
    local bone, ox, oy, oz
    local emitters = {}
    for _, value in bones do
        bone = value.Bone or 0
        ox = value.Offset[1] or 0
        oy = value.Offset[2] or 0
        oz = value.Offset[3] or 0
        for _, v in effectTemplate do
            local fx = CreateEmitterAtBone(unit, bone, unit.Army, v):EffectOffsetEmitter(ox, oy, oz)
            table.insert(emitters, fx)
            TrashAdd(EffectsBag, fx)
        end
    end

    return emitters
end

function TeleportCreateCybranSphere(unit, location, initialScale)
    -- Creates the sphere used by Cybran teleportation effects
    local bp = unit.Blueprint
    local scale = 1

    local sx, sy, sz = TeleportGetUnitSizes(unit)
    local scale = 1.25 * MathMax(sx, MathMax(sy, sz))
    unit.TeleportCybranSphereScale = scale

    local sphere = Entity()
    sphere:SetPosition(location, true)
    sphere:SetMesh('/effects/Entities/CybranTeleport/CybranTeleport_mesh', false)
    sphere:SetDrawScale(initialScale or scale)
    unit.TeleportCybranSphere = sphere
    TrashAdd(unit.Trash, sphere)

    sphere:SetVizToAllies('Intel')
    sphere:SetVizToEnemies('Intel')
    sphere:SetVizToFocusPlayer('Intel')
    sphere:SetVizToNeutrals('Intel')

    return sphere
end

function TeleportChargingProgress(unit, fraction)
    local bp = unit.Blueprint

    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        fraction = MathMin(MathMax(fraction, 0.01), 1)
        local faction = bp.General.FactionName

        if faction == 'UEF' then
            -- Increase rotation of effects as progressing
            if unit.TeleportDestChargeBag then
                local scale = 0.75 + (0.5 * MathMax(fraction, 0.01))
                for _, fx in unit.TeleportDestChargeBag do
                    fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction))
                    fx:ScaleEmitter(scale)
                end

                -- Scale FX at unit location as well
                for _, fx in unit.TeleportChargeBag do
                    fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction))
                    fx:ScaleEmitter(scale)
                end
            end
        elseif faction == 'Cybran' then
            -- Increase size of sphere and effects as progressing
            local scale = MathMax(fraction, 0.01) * (unit.TeleportCybranSphereScale or 5)
            if unit.TeleportCybranSphere then
                unit.TeleportCybranSphere:SetDrawScale(scale)
            end
            if unit.TeleportDestChargeBag then
                for _, fx in unit.TeleportDestChargeBag do
                   fx:ScaleEmitter(scale)
                end
            end
        elseif unit.TeleportDestChargeBag then
            -- Increase size of effects as progressing

            local scale = (2 * fraction) - MathPow(fraction, 2)
            for _, fx in unit.TeleportDestChargeBag do
               fx:ScaleEmitter(scale)
            end
        end
    end
end

function PlayTeleportOutEffects(unit, EffectsBag)
    -- Fired when the unit is being teleported, just before the unit is taken from its original location
    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)

    if bp.Display.TeleportEffects.PlayTeleportOutFx ~= false then
        unit:PlayUnitSound('TeleportOut')

        if faction == 'UEF' then
            local scaleX, scaleY, scaleZ = TeleportGetUnitSizes(unit)
            local cfx = UnitCreateProjectile(unit, '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, 0, 0, nil, nil, nil)
            ProjectileSetScale(proj, scaleX, scaleY, scaleZ)
            TrashAdd(EffectsBag, cfx)

            CreateLightParticle(unit, -1, unit.Army, 3, 7, 'glow_03', 'ramp_blue_02')
            local templ = unit.TeleportOutFxOverride or EffectTemplate.UEFTeleportOut01
            for _, v in templ do
                CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
            end
        elseif faction == 'Cybran' then
            CreateLightParticle(unit, -1, unit.Army, 4, 10, 'glow_02', 'ramp_red_06')
            local templ = unit.TeleportOutFxOverride or EffectTemplate.CybranTeleportOut01
            for _, v in templ do
                CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
            end
        elseif faction == 'Seraphim' then
            CreateLightParticle(unit, -1, unit.Army, 4, 15, 'glow_05', 'ramp_jammer_01')
            local templ = unit.TeleportOutFxOverride or EffectTemplate.SeraphimTeleportOut01
            for _, v in templ do
                CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
            end
        else  -- Aeon or other factions
            local templ = unit.TeleportOutFxOverride or EffectTemplate.GenericTeleportOut01
            for _, v in templ do
                CreateEmitterAtEntity(unit, unit.Army, v)
            end
        end
    end
end

function DoTeleportInDamage(unit)
    -- Check for teleport dummy weapon and deal the specified damage. Also show fx.
    local bp = unit.Blueprint
    local Yoffset = TeleportGetUnitYOffset(unit)

    local dmg = 0
    local dmgRadius = 0
    local dmgType = 'Normal'
    local dmgFriendly = false
    if bp.Weapon then
        for _, wep in bp.Weapon do
            if wep.Label == 'TeleportWeapon' then
                dmg = wep.Damage or dmg
                dmgRadius = wep.DamageRadius or dmgRadius
                dmgType = wep.DamageType or dmgType
                dmgFriendly = wep.DamageFriendly or dmgFriendly
                break
            end
        end
        if dmg > 0 and dmgRadius > 0 then
            local faction = bp.General.FactionName
            local army = unit.Army
            local templ
            if unit.TeleportInWeaponFxOverride then
                templ = unit.TeleportInWeaponFxOverride
            elseif faction == 'UEF' then
                templ = EffectTemplate.UEFTeleportInWeapon01
            elseif faction == 'Cybran' then
                templ = EffectTemplate.CybranTeleportInWeapon01
            elseif faction == 'Seraphim' then
                templ = EffectTemplate.SeraphimTeleportInWeapon01
            else -- Aeon or other factions
                templ = EffectTemplate.GenericTeleportInWeapon01
            end

            local MeshExtentsY = (bp.Physics.MeshExtentsY or 1)
            for _, v in templ do
                CreateEmitterAtEntity(unit, army, v):EffectOffsetEmitter(0, Yoffset, 0)
            end

            DamageArea(unit, EntityGetPosition(unit), dmgRadius, dmg, dmgType, dmgFriendly)
        end
    end
end

function CreateTeleSteamFX(unit)
    local totalBones = unit:GetBoneCount() - 1
    for _, v in EffectTemplate.UnitTeleportSteam01 do
        for bone = 1, totalBones do
            CreateAttachedEmitter(unit, bone, unit.Army, v)
        end
    end
end

function PlayTeleportInEffects(unit, EffectsBag)
    -- Fired when the unit is being teleported, just after the unit is taken from its original location
    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)
    local decalOrient = RandomFloat(0, 2 * math.pi)

    DoTeleportInDamage(unit)  -- Fire teleport weapon

    if bp.Display.TeleportEffects.PlayTeleportInFx ~= false then
        unit:PlayUnitSound('TeleportIn')
        if faction == 'UEF' then
            local templ = unit.TeleportInFxOverride or EffectTemplate.UEFTeleportIn01
            for _, v in templ do
                CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
            end

            CreateDecal(EntityGetPosition(unit), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, unit.Army)

            local fn = function(unit)
                local bp = unit.Blueprint
                local MeshExtentsY = (bp.Physics.MeshExtentsY or 1)

                CreateLightParticle(unit, -1, unit.Army, 4, 10, 'glow_03', 'ramp_yellow_01')
                DamageArea(unit, EntityGetPosition(unit), 9, 1, 'Force', true)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                CreateTeleSteamFX(unit)
            end
            local thread = unit:ForkThread(fn)
        elseif faction == 'Cybran' then
            if not unit.TeleportCybranSphere then
                local pos = TeleportLocationToSurface(table.copy(EntityGetPosition(unit)))
                pos[2] = pos[2] + Yoffset
                unit.TeleportCybranSphere = TeleportCreateCybranSphere(unit, pos)
            end

            local templ = unit.TeleportInFxOverride or EffectTemplate.CybranTeleportIn01
            local scale = unit.TeleportCybranSphereScale or 5
            for _, v in templ do
                CreateEmitterAtEntity(unit.TeleportCybranSphere, unit.Army, v):ScaleEmitter(scale)
            end

            CreateLightParticle(unit.TeleportCybranSphere, -1, unit.Army, 4, 10, 'glow_02', 'ramp_white_01')
            DamageArea(unit, EntityGetPosition(unit), 9, 1, 'Force', true)

            CreateDecal(EntityGetPosition(unit), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, unit.Army)

            local fn = function(unit)
                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds(0.8)

                if unit.TeleportCybranSphere then
                    unit.TeleportCybranSphere:Destroy()
                    unit.TeleportCybranSphere = false
                end

                CreateTeleSteamFX(unit)
            end
            local thread = unit:ForkThread(fn)
        elseif faction == 'Seraphim' then
            local fn = function(unit)

                local bp = unit.Blueprint
                local Yoffset = TeleportGetUnitYOffset(unit)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                local templ = unit.TeleportInFxOverride or EffectTemplate.SeraphimTeleportIn01
                for _, v in templ do
                    CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
                end

                CreateLightParticle(unit, -1, unit.Army, 4, 15, 'glow_05', 'ramp_jammer_01')
                DamageArea(unit, EntityGetPosition(unit), 9, 1, 'Force', true)

                local decalOrient = RandomFloat(0, 2 * math.pi)
                CreateDecal(EntityGetPosition(unit), decalOrient, 'crater01_albedo', '', 'Albedo', 4, 4, 200, 300, unit.Army)
                CreateDecal(EntityGetPosition(unit), decalOrient, 'crater01_normals', '', 'Normals', 4, 4, 200, 300, unit.Army)

                WaitSeconds (0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds (0.25)

                for _, v in EffectTemplate.SeraphimTeleportIn02 do
                    CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
                end

                CreateTeleSteamFX(unit)
            end

            local thread = unit:ForkThread(fn)
        else
            local templ = unit.TeleportInFxOverride or EffectTemplate.GenericTeleportIn01
            for _, v in templ do
                CreateEmitterAtEntity(unit, unit.Army, v):EffectOffsetEmitter(0, Yoffset, 0)
            end

            DamageArea(unit, EntityGetPosition(unit), 9, 1, 'Force', true)

            CreateDecal(EntityGetPosition(unit), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, unit.Army)

            CreateTeleSteamFX(unit)
        end
    end
end

function DestroyTeleportChargingEffects(unit, EffectsBag)
    -- Called when charging up is done because successful or cancelled
    if unit.TeleportChargeBag then
        for _, values in unit.TeleportChargeBag do
            values:Destroy()
        end
        unit.TeleportChargeBag = {}
    end
    if unit.TeleportDestChargeBag then
        for _, values in unit.TeleportDestChargeBag do
            values:Destroy()
        end
        unit.TeleportDestChargeBag = {}
    end
    if unit.TeleportSoundChargeBag then -- Emptying the sounds so they stop.
        for _, values in unit.TeleportSoundChargeBag do
            values:Destroy()
        end
        if unit.AmbientSounds then
            unit.AmbientSounds = {} -- For some reason we couldnt simply add this to trash so empyting it like this
        end
        unit.TeleportSoundChargeBag = {}
    end
    EffectsBag:Destroy()

    unit:StopUnitAmbientSound('TeleportChargingAtUnit')
    unit:StopUnitAmbientSound('TeleportChargingAtDestination')
end

function DestroyRemainingTeleportChargingEffects(unit, EffectsBag)
    -- Called when we're done teleporting (because succesfull or cancelled)
    if unit.TeleportCybranSphere then
        unit.TeleportCybranSphere:Destroy()
    end
end
