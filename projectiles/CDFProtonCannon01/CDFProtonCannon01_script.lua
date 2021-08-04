--
-- CDFProtonCannon01
--

local CDFProtonCannonProjectile = import('/lua/cybranprojectiles.lua').CDFProtonCannonProjectile

-- globals as upvalues for performance 
local ForkThread = ForkThread
local TrashAdd = TrashBag.Add
local WaitSeconds = WaitSeconds

local ImpactWaterThread = function(self)
    WaitSeconds(0.3)
    self.SetDestroyOnWater(self, true)
end

CDFProtonCannon01 = Class(CDFProtonCannonProjectile) {
    
    OnCreate = function(self)
        CDFProtonCannonProjectile.OnCreate(self)
        TrashAdd(self.Trash, ForkThread(ImpactWaterThread, self))
    end,
}
TypeClass = CDFProtonCannon01

