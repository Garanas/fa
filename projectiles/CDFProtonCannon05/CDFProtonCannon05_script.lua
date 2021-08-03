--****************************************************************************
--**
--**  File     :  /data/projectiles/CDFProtonCannon05/CDFProtonCannon05_script.lua
--**  Author(s):  Gordon Duclos, Matt Vainio
--**
--**  Summary  :  Cybran Proton Artillery projectile script, XRL0403
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CDFHvyProtonCannonProjectile = import('/lua/cybranprojectiles.lua').CDFHvyProtonCannonProjectile

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera

CDFProtonCannon05 = Class(CDFHvyProtonCannonProjectile) {
	OnImpact = function(self, TargetType, TargetEntity) 
		ProjectileShakeCamera(self,  15, 0.25, 0, 0.2 )
		CDFHvyProtonCannonProjectile.OnImpact (self, TargetType, TargetEntity)
	end,
}

TypeClass = CDFProtonCannon05