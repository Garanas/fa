--****************************************************************************
--**
--**  File     :  /data/projectiles/SBOVortexTacticalBomb02/SBOVortexTacticalBomb02_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Inferno Experimental Stragetic Bomb, XSA0402
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SExperimentalStrategicBomb = import('/lua/seraphimprojectiles.lua').SExperimentalStrategicBomb

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityPlaySound = EntityMethods.PlaySound
local EntityCreateProjectile = EntityMethods.CreateProjectile

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetCollision = ProjectileMethods.SetCollision

-- attach for CTRL + SHIFT F replacement

SBOInfernoExperimentalStrategicBomb01 = Class(SExperimentalStrategicBomb) {

    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            -- Play the explosion sound
            local myBlueprint = self.Blueprint
            if myBlueprint.Audio.Explosion then
                EntityPlaySound(self, myBlueprint.Audio.Explosion)
            end
    
            local pos = EntityGetPosition(self)
            nukeProjectile = EntityCreateProjectile(self, '/effects/entities/SeraphimNukeEffectController01/SeraphimNukeEffectController01_proj.bp', pos[1], pos[2] + 20, pos[3], nil, nil, nil)
            ProjectileSetCollision(nukeProjectile, false)

            -- pos[2] = pos[2] + 20
            -- Warp( nukeProjectile, pos)

            nukeProjectile.PassData(nukeProjectile, self.Data)
        end
        SExperimentalStrategicBomb.OnImpact(self, TargetType, TargetEntity)
    end,

}
TypeClass = SBOInfernoExperimentalStrategicBomb01