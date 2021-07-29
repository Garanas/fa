
-- core findings:
-- GetPositionLocal16: 0.25212
-- GetPositionUpvalue16: 0.25020
-- GetPositionSelf16: 0.27827

-- Using the self version of a function is the slowest approach. Having it as an upvalue 
-- (and manually adding in the self) has a significant difference: a 10% improvement.
-- Especially because we didn't change anything but redirecting the call. Localizing the 
-- function in the function itself is less useful - the overhead of adding the local
-- to the stack and releasing it costs too much.

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.01842

function GetPositionLocal01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.03558

function GetPositionLocal02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.05161

function GetPositionLocal03()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.06641

function GetPositionLocal04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.12932

function GetPositionLocal08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.25212

function GetPositionLocal16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.016006

local GetPosition = moho.entity_methods.GetPosition

function GetPositionUpvalue01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.03297

function GetPositionUpvalue02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.048435

function GetPositionUpvalue03()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.06446

function GetPositionUpvalue04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.12593

function GetPositionUpvalue08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.25020

function GetPositionUpvalue16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end


-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.01792

function GetPositionSelf01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.03367

function GetPositionSelf02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.05424

function GetPositionSelf03()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.07101

function GetPositionSelf04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.13999

function GetPositionSelf08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.27827

function GetPositionSelf16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end