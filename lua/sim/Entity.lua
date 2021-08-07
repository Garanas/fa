#****************************************************************************
#**  File     :  /lua/sim/Entity.lua
#**  Summary  : The Entity lua module
#**
#**  Copyright � 2008 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************


-- create the tracker table for units
local identifier = "Entity"
local simModel = import("/mods/profiler/modules/sim/model.lua")
local tracker = simModel.Hooks[identifier] or { }
tracker.MohoFunctions = tracker.MohoFunctions or { }
tracker.Functions = tracker.Functions or { }
simModel.Hooks[identifier] = tracker

local ProfilerFunctions = {
    "AddManualScroller",
    "GetPosition",
    "AddPingPongScroller",
    "AddShooter",
    "AddThreadScroller",
    "AddWorldImpulse",
    "AdjustHealth",
    "AttachBoneTo",
    "AttachBoneToEntityBone",
    "AttachTo",
    "BeenDestroyed",
    "CreateProjectile",
    "CreateProjectileAtBone",
    "CreatePropAtBone",
    "Destroy",
    "DetachAll",
    "DetachFrom",
    "DisableIntel",
    "EnableIntel",
    "FallDown",
    "GetAIBrain",
    "GetArmy",
    "GetBlueprint",
    "GetBoneCount",
    "GetBoneDirection",
    "GetBoneName",
    "GetCollisionExtents",
    "GetEntityId",
    "GetFractionComplete",
    "GetHeading",
    "GetHealth",
    "GetIntelRadius",
    "GetMaxHealth",
    "GetOrientation",
    "GetParent",
    "GetPosition",
    "GetPositionXYZ",
    "GetScale",
    "InitIntel",
    "IsIntelEnabled",
    "IsValidBone",
    "Kill",
    "PlaySound",
    "PushOver",
    "ReachedMaxShooters",
    "RemoveScroller",
    "RemoveShooter",
    "RequestRefreshUI",
    "SetAmbientSound",
    "SetCollisionShape",
    "SetDrawScale",
    "SetHealth",
    "SetIntelRadius",
    "SetMaxHealth",
    "SetMesh",
    "SetOrientation",
    "SetParentOffset",
    "SetPosition",
    "SetScale",
    "SetVizToAllies",
    "SetVizToEnemies",
    "SetVizToFocusPlayer",
    "SetVizToNeutrals",
    "ShakeCamera"
}

local mohoTable = moho.entity_methods 
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

Entity = Class(mohoTable) {

    __init = function(self,spec)
        _c_CreateEntity(self,spec)
    end,

    __post_init = function(self,spec)
        self:OnCreate(spec)
    end,

    OnCreate = function(self,spec)
        self.Spec = spec
        self.EntityId = self:GetEntityId()
        self.Army = self:GetArmy()
    end,

    OnDestroy = function(self)

    end,
}