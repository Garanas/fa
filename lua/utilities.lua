-----------------------------------------------------------------
-- File     :  /lua/utilities.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Utility functions for scripts.
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- upvalues instead of globals

-- often used globals

local Rect = Rect
local Random = Random
local VDist3 = VDist3
local VDist3Sq = VDist3Sq

local EntityCategoryContains = EntityCategoryContains
local EntityCategoryFilterDown = EntityCategoryFilterDown

-- local GetUnitsInRect = GetUnitsInRect -- causes a crash

-- often used metatable functions

local EntityGetPosition = moho.entity_methods.GetPosition

--- Computes the distance between two entities. Use 'GetSquaredDistanceBetweenTwoEntities' when you
-- are only interested in comparing distances.
function GetDistanceBetweenTwoEntities(entity1, entity2)
    return VDist3(EntityGetPosition(entity1),EntityGetPosition(entity2))
end

--- Computes the squared distance between two entities. Use 'GetDistanceBetweenTwoEntities' if the
-- distance matters for the computation.
function GetSquaredDistanceBetweenTwoEntities(entity1, entity2)
    return VDist3Sq(EntityGetPosition(entity1),EntityGetPosition(entity2))
end

-- Function originally created to check if a Mass Storage can be queued in a location without overlapping
function CanBuildInSpot(originUnit, unitId, pos)
    local bp = __blueprints[unitId]
    local mySkirtX = bp.Physics.SkirtSizeX / 2
    local mySkirtZ = bp.Physics.SkirtSizeZ / 2

    -- Find the distance between my skirt and the skirt of a potential Quantum Gateway
    local xDiff = mySkirtX + 5 -- Using 5 because that's half the size of a Quantum Gateway, the largest stock structure
    local zDiff = mySkirtZ + 5

    -- Full extent of search rectangle
    local x1 = pos.x - xDiff
    local z1 = pos.z - zDiff
    local x2 = pos.x + xDiff
    local z2 = pos.z + zDiff

    -- Find all the units in that rectangle
    local units = GetUnitsInRect(Rect(x1, z1, x2, z2))

    -- Filter it down to structures and experimentals only
    units = EntityCategoryFilterDown(categories.STRUCTURE + categories.EXPERIMENTAL, units)

    -- Bail if there's nothing in range
    if not units[1] then return false end

    for _, struct in units do
        if struct ~= originUnit then
            local structPhysics = struct:GetBlueprint().Physics
            local structPos = EntityGetPosition(struct)

            -- These can be positive or negative, so we need to make them positive using math.abs
            local xDist = math.abs(pos.x - structPos.x)
            local zDist = math.abs(pos.z - structPos.z)

            local skirtDiffx = mySkirtX + (structPhysics.SkirtSizeX / 2)
            local skirtDiffz = mySkirtZ + (structPhysics.SkirtSizeZ / 2)

            -- Check if the axis difference is smaller than the combined skirt distance
            -- If it is, we overlap, and can't build here
            if xDist < skirtDiffx and zDist < skirtDiffz then
                return false
            end
        end
    end

    return true
end

--- Gets all units in a sphere that are not yours. It includes allied units. This is a 
-- gpg-original function and therefore we can not change its behavior.
function GetEnemyUnitsInSphere(unit, position, radius)

    -- find units in rectangle
    local x1 = position.x - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(Rect(x1, z1, x2, z2))

    -- check for empty rectangle
    if not UnitsinRec then
        return { }
    end

    -- checks whether they're not in our army and whether the unit is in the sphere
    local RadEntities = { }
    local RadEntitiesCount = 0
    for _, v in UnitsinRec do
        if unit.Army ~= v.Army then 
            local dist = VDist3Sq(position, EntityGetPosition(v))
            if dist <= radius then
                RadEntitiesCount = RadEntitiesCount + 1
                RadEntities[RadEntitiesCount] = v
            end
        end
    end

    return RadEntities, RadEntitiesCount
end

-- This function is like the one above, but filters out Allied units
function GetTrueEnemyUnitsInSphere(unit, position, radius, categories)

    -- find units in rectangle
    local x1 = position.x - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(Rect(x1, z1, x2, z2))

    -- check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    -- checks whether they're hostile units and whether the unit is in the sphere
    local RadEntities = { }
    local RadEntitiesCount = 0
    for _, v in UnitsinRec do
        local dist = VDist3Sq(position, EntityGetPosition(v))
        local vArmy = v.Army
        if unit.Army ~= vArmy and not IsAlly(unit.Army, vArmy) then 
            if categories and EntityCategoryContains(categories, v) then 
                if dist <= radius then
                    RadEntitiesCount = RadEntitiesCount + 1
                    RadEntities[RadEntitiesCount] = v
                end
            end
        end
    end

    return RadEntities, RadEntitiesCount
end

--- Computes the distance between two points. Use 'GetSquaredDistanceBetweenTwoPoints' when you
-- are only interested in comparing distances.
function GetDistanceBetweenTwoPoints(x1, y1, z1, x2, y2, z2)
    local x = (x1 - x2)
    local y = (y1 - y2)
    local z = (z1 - z2)
    return math.sqrt(x * x + y * y + z * z)
end

--- Computes the squared distance between two points. Use 'GetDistanceBetweenTwoPoints' if the
-- distance matters for the computation.
function GetSquaredDistanceBetweenTwoPoints(x1, y1, z1, x2, y2, z2)
    local x = (x1 - x2)
    local y = (y1 - y2)
    local z = (z1 - z2)
    return x * x + y * y + z * z
end

--- Computes the distance between two vectors. Use 'GetSquaredDistanceBetweenTwoVectors' when you
-- are only interested in comparing distances.
function GetDistanceBetweenTwoVectors(v1, v2)
    return VDist3(v1, v2)
end

--- Computes the squared distance between two vectors. Use 'GetDistanceBetweenTwoVectors' if the
-- distance matters for the computation.
function GetSquaredDistanceBetweenTwoVectors(v1, v2)
    return VDist3Sq(v1, v2)
end

--- Computes the XZ distance between two vectors. Use 'XZSquaredDistanceTwoVectors' when you
-- are only interested in comparing distances.
function XZDistanceTwoVectors(v1, v2)
    return VDist2(v1[1], v1[3], v2[1], v2[3])
end

--- Computes the squared distance between two vectors. Use 'XZDistanceTwoVectors' if the
-- distance matters for the computation.
function XZSquaredDistanceTwoVectors(v1, v2)
    return VDist2Sq(v1[1], v1[3], v2[1], v2[3])
end

--- Computes the length of a vector. Use 'GetVectorSquaredLength' when you
-- are only interested in comparing lengths.
function GetVectorLength(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

--- Computes the length of a vector. Use 'GetVectorLength' when the
-- length matters for the computation.
function GetVectorSquaredLength(v)
    return v.x * v.x + v.y * v.y + v.z * v.z
end

--- Returns the normalized vector.
function NormalizeVector(v)

    -- prevents hashing multiple times
    local x = v.x 
    local y = v.y
    local z = v.z

    -- normalize the vector
    local length = math.sqrt(x * x + y * y + z * z)
    if length > 0 then
        local invlength = 1 / length
        return Vector(invlength * x, invlength * y, invlength * z)
    else
        return Vector(0,0,0)
    end
end

--- Computes the vector that points from v1 to v2.
function GetDifferenceVector(v1, v2)
    return Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
end

--- Computes the normalized vector that points from v1 to v2.
function GetDirectionVector(v1, v2)

    -- prevents hashing multiple times
    local x = v1.x - v2.x
    local y = v1.y - v2.y
    local z = v1.z - v2.z

    -- normalize the vector
    local length = math.sqrt(x * x + y * y + z * z)
    if length > 0 then
        local invlength = 1 / length
        return Vector(invlength * x, invlength * y, invlength * z)
    else
        return Vector(0,0,0)
    end
end

--- Computes the normalized and then scaled vector that points from v1 to v2.
function GetScaledDirectionVector(v1, v2, scale)

    -- prevents hashing multiple times
    local x = v1.x - v2.x
    local y = v1.y - v2.y
    local z = v1.z - v2.z

    -- normalize the vector
    local length = math.sqrt(x * x + y * y + z * z)
    if length > 0 then
        local scaledInvLength = scale / length
        return Vector(scaledInvLength * x, scaledInvLength * y, scaledInvLength * z)
    else
        return Vector(0,0,0)
    end
end

--- Computes the vector in the center of two other vectors.
function GetMidPoint(v1, v2)
    return Vector(0.5 * (v1.x + v2.x), 0.5 * (v1.y + v2.y), 0.5 * (v1.z + v2.z))
end

--- Computes a random float within the boundaries. Do not use in critical code - instead, copy the body.
function GetRandomFloat(nmin, nmax)
    return Random() * (nmax - nmin) + nmin
end

--- Computes a random integer within the boundaries. Do not use in critical code - instead, copy the body.
function GetRandomInt(nmin, nmax)
    return Random(nmin, nmax)
end

--- Computes a random offset - often used for emitters.
function GetRandomOffset(sx, sy, sz, scalar)
    sx = sx * scalar
    sy = sy * scalar
    sz = sz * scalar
    local x = Random() * sx - (sx * 0.5)
    local y = Random() * sy
    local z = Random() * sz - (sz * 0.5)

    return x, y, z
end

--- Computes a random offset - often used for emitters.
function GetRandomOffset2(sx, sy, sz, scalar)
    sx = sx * scalar
    sy = sy * scalar
    sz = sz * scalar
    local x = (Random() * 2 - 1) * sx - (sx * 0.5)
    local y = (Random() * 2 - 1) * sy
    local z = (Random() * 2 - 1) * sz - (sz * 0.5)

    return x, y, z
end

--- Computes the closest vector from a list of vectors.
function GetClosestVector(vFrom, vToList, vToListCount)

    -- locals used during function
    local dist, cDist, retVec = 0

    -- compute initial state
    dist = VDist3Sq(vFrom, vToList[1])
    retVec = vToList[1]

    -- compute count if not provided
    vToListCount = vToListCount or table.getn(vToList)

    -- find closest vector
    for k = 2, vToListCount do 
        local element = vToList[k]
        cDist = VDist3Sq(vFrom, element)
        if dist > cDist then
            dist = cDist
            retVec = element
        end
    end

    return retVec
end

function Cross(v1, v2)
    return Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
end

function DotP(v1, v2)
    return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z)
end

function GetAngleInBetween(v1, v2)
    -- Normalize the vectors
    local vec1 = {}
    local vec2 = {}
    vec1 = NormalizeVector(v1)
    vec2 = NormalizeVector(v2)
    local dotp = DotP(vec1, vec2)

    return math.acos(dotp) * (360 / (math.pi * 2))
end

--- Computes the full angle between the two vectors in two dimensions: the y dimension is not taken into account. Angle
-- is computed in a counter clockwise direction: if the base is to the south ({0, 0, 1}) then the direction to the east ({1, 0, 0}) is 90 degrees.
-- @param base The base direction from which the angle will be computed in a counter clockwise fashion.
-- @param direction The direction from which we want to compute the angle given a base.
function GetAngleCCW(base, direction)

    local bn = NormalizeVector(base)
    local dn = NormalizeVector(direction)

    -- compute the orthogonal vector to determine if we need to take the inverse
    local ort = { bn[3], 0, -bn[1] }

    -- compute the radians, correct it accordingly
    local rads = math.acos(bn[1] * dn[1] + bn[3] * dn[3])
    if ort[1] * dn[1] + ort[3] * dn[3] < 0 then
        rads = 2 * math.pi - rads
    end

    -- convert to degrees
    return (180 / math.pi) * rads
end

function UserConRequest(string)
    if not Sync.UserConRequests then
        Sync.UserConRequests = {}
    end
    table.insert(Sync.UserConRequests, string)
end

-----------------------------------------------------------------
-- TableCat - Concatenates multiple tables into one single table
-----------------------------------------------------------------
function TableCat(...)
    local ret = {}
    for index = 1, table.getn(arg) do
        if arg[index] ~= nil then
            for k, v in arg[index] do
                table.insert(ret, v)
            end
        end
    end

    return ret
end
