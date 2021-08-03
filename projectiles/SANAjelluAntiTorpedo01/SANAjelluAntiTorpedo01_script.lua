--****************************************************************************
--**
--**  File     :  /data/projectiles/SANAjelluAntiTorpedo01/SANAjelluAntiTorpedo01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Seraphim Ajellu Torpedo Defense Projectile script, XSS0201, XSS0203, XSB2205
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAnjelluTorpedoDefenseProjectile = import('/lua/seraphimprojectiles.lua').SAnjelluTorpedoDefenseProjectile

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileSetLifetime = ProjectileMethods.SetLifetime

SANAjelluAntiTorpedo01 = Class(SAnjelluTorpedoDefenseProjectile) {
	OnLostTarget = function(self)
        ProjectileSetAcceleration(self, -3.6)
        ProjectileSetLifetime(self, 0.5)
    end,
}
TypeClass = SANAjelluAntiTorpedo01