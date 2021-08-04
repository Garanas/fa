
-- NOTE: the alternative DamageArea is only used for strategic missiles. It does not override the global DamageArea function.

-- imports because we need them
local GetDirectionVector = import('/lua/utilities.lua').GetDirectionVector

-- function that we're hooking
local oldDamageArea = DamageArea

-- globals as upvalues for performance
local Rect = Rect
local Damage = Damage
local IsProp = IsProp
local IsAlly = IsAlly
local VDist3Sq = VDist3Sq
local GetUnitsInRect = GetUnitsInRect

-- Trying to mimic DamageArea as good as possible, used for nukes to bypass the bubble damage absorbation of shields.
DamageArea = function(instigator, location, radius, damage, type, damageAllies, damageSelf, brain, army)
    local rect = Rect(location[1]-radius, location[3]-radius, location[1]+radius, location[3]+radius)
    local units = GetUnitsInRect(rect) or {}

    local squaredRadius = radius * radius

    -- find units to damage
    for _, u in units do

        -- bail out - not in range
        local position = u:GetPosition()
        if VDist3Sq(position, location) > squaredRadius then 
            continue 
        end

        -- exception because Damage can't damage itself (instigator = self)
        if instigator == u then
            if damageSelf then
                local vector = GetDirectionVector(location, position)
                instigator.OnDamage(instigator, instigator, damage, vector, type)
            end
        elseif damageAllies or not IsAlly(army, u.Army) then
            Damage(instigator, location, u, damage, type)
        end
    end

    -- find reclaim to damage
    local reclaim = GetReclaimablesInRect(rect) or {}
    for _, r in reclaim do
        local position = r:GetPosition()
        if IsProp(r) and VDist3Sq(position, location) <= squaredRadius then
            Damage(instigator, location, r, damage, type)
        end
    end

     -- Get rid of trees
     oldDamageArea(instigator, location, radius, 1, 'Force', false, false)
end