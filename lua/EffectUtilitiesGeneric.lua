


-- cache globals for performance
local Random = Random
local CreateBoneEffects = CreateBoneEffects
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- cache moho functions for performance
local EmitterOffsetEmitter = moho.IEffect.OffsetEmitter

--- Creates a bunch of effects at the core bone of the entity. 
-- Effects are typically defined in EffectTemplates.lua.
-- @param entity The entity to attach the effects to.
-- @param army The army that the effects belong to.
-- @param blueprints A table with emitter blueprints.
-- @param cache Optional argument - effects are appended to the cache or allocates a new cache if not provided.
-- @param cacheHead Optional argument - the number of elements in the cache + 1.
function CreateEffects(entity, army, blueprints, cache, cacheHead)
    -- attempt to use the cache
    cache = cache or {}
    cacheHead = cacheHead or 1

    -- add the emitters to the cache
    for _, v in blueprints do
        cache[cacheHead] = CreateEmitterAtEntity(entity, army, v)
        cacheHead = cacheHead + 1
    end

    -- return the cache
    return cache, cacheHead
end

--- Creates a bunch of effects with an offset to the core bone of the entity entity. 
-- Effects are typically defined in EffectTemplates.lua.
-- @param entity The entity to attach the effects to.
-- @param army The army that the effects belong to.
-- @param blueprints A table with emitter blueprints.
-- @param x The offset on the x-axis (on the plane).
-- @param y The offset on the y-axis (up / down).
-- @param z The offset on the z-axis (on the plane).
-- @param cache Optional argument - effects are appended to the cache or allocates a new cache if not provided.
-- @param cacheHead Optional argument - the number of elements in the cache + 1.
function CreateEffectsWithOffset(entity, army, blueprints, x, y, z, cache, cacheHead)

    local effect = false

    -- attempt to use the cache
    cache = cache or {}
    cacheHead = cacheHead or 1

    -- add the emitters to the cache
    for _, v in blueprints  do
        effect = CreateEmitterAtEntity(entity, army, v)
        EmitterOffsetEmitter(effect, x, y, z)

        cache[cacheHead] = effect 
        cacheHead = cacheHead + 1
    end

    -- return the cache
    return cache, cacheHead
end

--- Creates a bunch of effects with a a random offset to the core bone of the entity. 
-- Effects are typically defined in EffectTemplates.lua.
-- @param entity The entity to attach the effects to.
-- @param army The army that the effects belong to.
-- @param blueprints A table with emitter blueprints.
-- @param xRange The range of the offset on the x-axis (on the plane).
-- @param yRange The range of the offset on the y-axis (up / down).
-- @param zRange The range of the offset on the z-axis (on the plane).
-- @param cache Optional argument - effects are appended to the cache or allocates a new cache if not provided.
-- @param cacheHead Optional argument - the number of elements in the cache + 1.
function CreateEffectsWithRandomOffset(entity, army, blueprints, xRange, yRange, zRange, cache, cacheHead)

    local effect = false
    local x, y, z = false, false, false

    -- attempt to use the cache
    cache = cache or {}
    cacheHead = cacheHead or 1

    -- add the emitters to the cache
    for _, v in blueprints  do

        -- compute a random offset
        x = Random() * xRange - (0.5 * xRange)
        y = Random() * yRange - (0.5 * yRange)
        z = Random() * zRange - (0.5 * zRange)

        effect = CreateEmitterAtEntity(entity, army, v)
        EmitterOffsetEmitter(effect, x, y, z)

        cache[cacheHead] = effect 
        cacheHead = cacheHead + 1
    end

    -- return the cache
    return cache, cacheHead
end

--- Creates a bunch of effects on the bone of the entity. 
-- Effects are typically defined in EffectTemplates.lua.
-- @param entity The entity to attach the effects to.
-- @param bone The bone of the entity to attach the effects to.
-- @param army The army that the effects belong to.
-- @param blueprints A table with emitter blueprints.
-- @param cache Optional argument - effects are appended to the cache or allocates a new cache if not provided.
-- @param cacheHead Optional argument - the number of elements in the cache + 1.
function CreateBoneEffects(entity, bone, army, blueprints, cache, cacheHead)

    -- attempt to use the cache
    cache = cache or {}
    cacheHead = cacheHead or 1

    -- add the emitters to the cache
    for _, v in blueprints do
        cache[cacheHead] = CreateEmitterAtBone(entity, bone, army, v)
        cacheHead = cacheHead + 1
    end

    -- return the cache
    return cache, cacheHead
end

-- @param entity The entity to attach the effects to.
-- @param bone The bone of the entity to attach the effects to.
-- @param army The army that the effects belong to.
-- @param blueprints A table with emitter blueprints.
-- @param x The offset on the x-axis (on the plane).
-- @param y The offset on the y-axis (up / down).
-- @param z The offset on the z-axis (on the plane).
-- @param cache Optional argument - effects are appended to the cache or allocates a new cache if not provided.
-- @param cacheHead Optional argument - the number of elements in the cache + 1.
function CreateBoneEffectsOffset(entity, bone, army, blueprints, x, y, z, cache, cacheHead)

    local effect = false

    -- attempt to use the cache
    cache = cache or {}
    cacheHead = cacheHead or 1

    -- add the emitters to the cache
    for _, v in blueprints do
        effect = CreateEmitterAtBone(entity, bone, army, v)
        EmitterOffsetEmitter(effect, x, y, z)

        cache[cacheHead] = effect 
        cacheHead = cacheHead + 1
    end

    -- return the cache
    return cache, cacheHead
end

--- Creates a bunch of effects on the bone of the entity. 
-- Effects are typically defined in EffectTemplates.lua.
-- @param entity The entity to attach the effects to.
-- @param bones The bones of the entity to attach the effects to.
-- @param army The army that the effects belong to.
-- @param blueprints A table with emitter blueprints.
-- @param cache Optional argument - effects are appended to the cache or allocates a new cache if not provided.
-- @param cacheHead Optional argument - the number of elements in the cache + 1.
function CreateBoneTableEffects(entity, bones, army, blueprints, cache, cacheHead)

    local effect = false

    -- attempt to use the cache
    cache = cache or {}
    cacheHead = cacheHead or 1

    -- add the emitters to the cache
    for _, vBone in bones do
        for _, vEffect in blueprints do
            cache[cacheHead] = CreateEmitterAtBone(entity, vBone, army, vEffect) 
            cacheHead = cacheHead + 1
        end
    end

    -- return the cache
    return cache, cacheHead
end

function CreateBoneTableRangedScaleEffects(entity, BoneTable, blueprints, army, ScaleMin, ScaleMax)
    for _, vBone in BoneTable do
        for _, vEffect in blueprints do
            CreateEmitterAtBone(entity, vBone, army, vEffect):ScaleEmitter(util.GetRandomFloat(ScaleMin, ScaleMax))
        end
    end
end

function CreateRandomEffects(entity, army, blueprints, NumEffects)
    local NumTableEntries = table.getn(blueprints)
    local emitters = {}
    for i = 1, NumEffects do
        table.insert(emitters, CreateEmitterOnEntity(entity, army, blueprints[util.GetRandomInt(1, NumTableEntries)]))
    end
    return emitters
end

function ScaleEmittersParam(Emitters, param, minRange, maxRange)
    for _, v in Emitters do
        v:SetEmitterParam(param, util.GetRandomFloat(minRange, maxRange))
    end
end
