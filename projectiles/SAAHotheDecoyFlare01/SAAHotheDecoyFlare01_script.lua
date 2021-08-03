--****************************************************************************
--**
--**  File     :  /lua/SAAHotheDecoyFlare01/SAAHotheDecoyFlare01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  : Seraphim Hothe Decoy Flare
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Flare = import('/lua/defaultantiprojectile.lua').Flare
local SAAHotheFlareProjectile = import('/lua/seraphimprojectiles.lua').SAAHotheFlareProjectile

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetVelocity = ProjectileMethods.SetVelocity

local TrashAdd = TrashBag.Add

-- attach for CTRL + SHIFT F replacement

SAAHotheDecoyFlare01 = Class(SAAHotheFlareProjectile) {
    OnCreate = function(self)
        SAAHotheFlareProjectile.OnCreate(self)
        self.MyShield = Flare {
            Owner = self,
            Radius = self.Blueprint.Physics.FlareRadius,
        }
        TrashAdd(self.Trash, self.MyShield)
        ProjectileTrackTarget(self, false)
        ProjectileSetVelocity(self, 0, -1, 0)
    end,
}
TypeClass = SAAHotheDecoyFlare01

