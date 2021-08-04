local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

-- globals as upvalues for performance 
local Warp = Warp
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local GetTerrainHeight = GetTerrainHeight
local GetTerrainTypeOffset = GetTerrainTypeOffset

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntityGetPosition = EntityMethods.GetPosition
local EntityBeenDestroyed = EntityMethods.BeenDestroyed
local EntityAttachBoneTo = EntityMethods.AttachBoneTo

local EntitySetVizToFocusPlayer = EntityMethods.SetVizToFocusPlayer
local EntitySetVizToAllies = EntityMethods.SetVizToAllies
local EntitySetVizToNeutrals = EntityMethods.SetVizToNeutrals

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetStayUpRight = ProjectileMethods.SetStayUpright
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

local TrashAdd = TrashBag.Add

-- attach for CTRL + SHIFT F replacement

local StartSinking = function(self, targetEntity, targetBone)
    local pos = EntityGetPosition(targetEntity, targetBone)
    local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
    if pos[2] <= seafloor then
        EntityDestroy(self)
        TrashAdd(self.Trash, ForkThread(self.callback))
        return
    end

    Warp(self, pos, targetEntity:GetOrientation())
    EntityAttachBoneTo(targetEntity, targetBone, self, 'anchor')

    if not EntityBeenDestroyed(targetEntity) then
        local acc = -self.Blueprint.Physics.SinkSpeed
        ProjectileSetBallisticAcceleration(self, acc + GetRandomFloat(-0.02, 0.02))
    end
end

Sinker = Class(Projectile) {
    OnCreate = function(self)
        Projectile.OnCreate(self)

        EntitySetVizToFocusPlayer(self, 'Never')
        EntitySetVizToAllies(self, 'Never')
        EntitySetVizToNeutrals(self, 'Never')
        ProjectileSetStayUpRight(self, false)
    end,

    --- Start the sinking after the given delay for the given entity/bone.
    -- Invokes sunkCallback when the unit reaches the bottom of the ocean.
    Start = function(self, delay, targEntity, targBone, sunkCallback)
        self.callback = sunkCallback
        if delay > 0 then
            -- Closure copies. Woot.
            local targetEntity = targEntity
            local targetBone = targBone
            local sinker = self
            local wait = delay

            TrashAdd(self.Trash, ForkThread(
                function()
                    WaitTicks(wait)
                    StartSinking(sinker, targetEntity, targetBone)
                end
            ))
        else
            StartSinking(self, targEntity, targBone)
        end
    end,

    --- Destroy the sinking unit when it hits the bottom of the ocean.
    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' then
            EntityDestroy(self)
            if self.callback then
                TrashAdd(self.Trash, ForkThread(self.callback))
            end    
        end
    end,
}
TypeClass = Sinker
