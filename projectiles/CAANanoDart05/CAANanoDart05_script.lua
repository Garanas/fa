--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile03

-- globals as upvalues for performance 
local CreateEmitterOnEntity = CreateEmitterOnEntity

CAANanoDart02 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)

        local army = self.Army
        local FxTrails = self.FxTrails
        for k, v in FxTrails do
            CreateEmitterOnEntity(self, army, v)
        end
   end,
}

TypeClass = CAANanoDart02
