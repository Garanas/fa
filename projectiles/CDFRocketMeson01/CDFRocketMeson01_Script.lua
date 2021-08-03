
local CRocketProjectile = import('/lua/cybranprojectiles.lua').CRocketProjectile



-- globals as upvalues for performance 
local ForkThread = ForkThreadeA
local WaitSeconds = WaitSeconds
local CreateTrail = CreateTrail

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntitySetMesh = EntityMethods.SetMesh

local EmitterMethods = _G.moho.IEffect
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

local TrashAdd = TrashBag.Add

local UpdateThread = function(self)

    WaitSeconds(0.15)
    EntitySetMesh(self, '/projectiles/CDFRocketMeson01/CDFRocketMesonUnPacked01_mesh')

    -- Polytrails offset to wing tips
    local army = self.Army
    local polyTrail = self.PolyTrail
    EmitterOffsetEmitter(CreateTrail(self, -1, army, polyTrail), 0.075, -0.05, 0.25)
    EmitterOffsetEmitter(CreateTrail(self, -1, army, polyTrail), -0.085, -0.055, 0.25)
    EmitterOffsetEmitter(CreateTrail(self, -1, army, polyTrail), 0, 0.09, 0.25)
end

CDFRocketMeson01 = Class(CRocketProjectile) {

   PolyTrail = '/effects/emitters/default_polytrail_06_emit.bp',

   OnCreate = function(self)
        CRocketProjectile.OnCreate(self)
        TrashAdd(self.Trash, ForkThread(UpdateThread, self))
   end,
}

TypeClass = CDFRocketMeson01
