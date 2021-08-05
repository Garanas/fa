#****************************************************************************
#**
#**  File     :  /cdimage/units/DAA0206/DAA0206_script.lua
#**  Author(s):  Dru Staltman, Eric Williamson, Gordon Duclos, Greg Kohne
#**
#**  Summary  :  Aeon Guided Missile Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtils = import('/lua/effectutilities.lua')

DAA0206 = Class(AAirUnit) {
    Weapons = {
        Suicide = Class(DefaultProjectileWeapon) {}
    },

    OnRunOutOfFuel = function(self)
        self.Kill(self)
    end,
    
    ProjectileFired = function(self)
        self.GetWeapon(self, 1).IdleState.Main = function(self) end
        self.PlayUnitSound(self, 'Killed')
		self.PlayUnitSound(self, 'Destroyed')
        self.Destroy(self)
    end,
}
TypeClass = DAA0206
