# Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#

# This is the user-side session specific top-level lua initialization
# file.  It is loaded into a fresh lua state when a new session is
# initialized.

LOG("FIRST!")
local Unit = import("/lua/sim/unit.lua").Unit
LOG(Unit)

-- do 
--     LOG("Adjusting unit classes")

--     local Unit = import("/lua/sim/unit.lua")
--     local HookUtils = import('/mods/profiler/modules/sim/hookUtils.lua')

--     -- create the tracker table for units
--     local identifier = "Unit"
--     local simModel = import("/mods/profiler/modules/sim/model.lua")
--     local tracker = { }
--     tracker.Functions = { }
--     simModel.Hooks[identifier] = tracker

--     -- metatables we wish to exclude
--     local TableExceptions = { }

--     -- individual identifiers we wish to exclude
--     local HookExceptions = { }

--     -- attach profiler information
--     for k, element in Unit do 
--         -- make sure we can use k as an index, in some rare occasions it is a cfunction
--         local typeK = type(k)
--         if not (typeK == "string" or typeK == "number") then 
--             LOG("Profiler: Skipping unknown type of k: " .. typeK)
--             continue
--         end

--         -- make sure this element is relevant
--         if HookUtils.CheckSkip(TableExceptions, HookExceptions, k) then 
--             continue 
--         end

--         -- localize for loop variables so that they can be reliably uplifted
--         local lK = k 
--         local lElement = element 

--         -- make sure we're dealing with a (c)function
--         typeElement = type(lElement)
--         if typeElement == "function" or typeElement == "cfunction" then 
--             tracker.Functions[lK] = 0

--             -- hook function
--             local old = Unit[lK]
--             Unit[lK] = function(...)
--                 -- keep track how often we called this function
--                 tracker.Functions[lK] = tracker.Functions[lK] + 1

--                 -- call the old function
--                 return old(unpack(arg))
--             end
--         end
--     end
-- end

# Do global init
doscript '/lua/userInit.lua'

# Add UI-only mods to the list of mods to use
for i,m in ipairs(import('/lua/Mods.lua').GetUiMods()) do
    table.insert(__active_mods, m)
end

LOG('Active mods in session: ',repr(__active_mods))

doscript '/lua/UserSync.lua'
