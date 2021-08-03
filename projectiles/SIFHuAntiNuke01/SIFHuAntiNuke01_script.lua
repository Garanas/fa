--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFHuAntiNuke01/SIFHuAntiNuke01_script.lua
--**  Author(s):  Greg Kohne, Matt Vainio
--**
--**  Summary  : Seraphim Anti Nuke Missile
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************



local SKhuAntiNukeHit = import('/lua/EffectTemplates.lua').SKhuAntiNukeHit
local SIFHuAntiNuke = import('/lua/seraphimprojectiles.lua').SIFHuAntiNuke
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local RandomInt = import('/lua/utilities.lua').GetRandomInt

-- globals as upvalues for performance 
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile
local ProjectileSetLifetime = ProjectileMethods.SetLifetime
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

-- attach for CTRL + SHIFT F replacement

SIFHuAntiNuke01 = Class(SIFHuAntiNuke) {

     ------This is a custom impact to maeke the seraphim hit look really good, like some kind of tendrilled explosion.
     OnImpact = function(self, TargetType, TargetEntity) 

        local LargeTendrilProjectile = '/effects/Entities/SIFHuAntiNuke02/SIFHuAntiNuke02_proj.bp'  
        local SmallTendrilProjectile = '/effects/Entities/SIFHuAntiNuke03/SIFHuAntiNuke03_proj.bp'  
        
       
        ------Play the hit effect for the core explosion on the anti nuke.
        local FxHitEffect = SKhuAntiNukeHit 
        for k, v in FxHitEffect do
            CreateEmitterAtEntity( self, self.Army, v )
        end
    
        local velocity = 19
    
		-- Create several other projectiles in a dispersal pattern
        local num_projectiles = 5
        local horizontal_angle = (2*3.141592) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )
        
        -- Randomization of the spread
        local angleVariation = horizontal_angle * 0.25  --Adjusts horizontal_angle variance spread
        local spreadMul = 0.15  ------Adjusts the width of the dispersal        
        
        local xVec
        local yVec
        local zVec
        
        ------------------------------------------------------------------------------------------
        ------------Create LARGE TENDRIL proj*ectiles--------------
        for i = 0, (num_projectiles -1) do
            xVec = (MathSin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            yVec =  RandomFloat(-3,33)
            zVec = (MathCos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)

            local proj = ProjectileCreateChildProjectile(self, LargeTendrilProjectile):
            ProjectileSetLifetime(proj, RandomFloat(0.4,0.65) ) 
            ProjectileSetVelocity(proj, velocity)
            ProjectileSetBallisticAcceleration(proj, 0,-89.92,0)
            ProjectileSetVelocity(proj, xVec,yVec,zVec)
        end
        
        ------Ensure that the number of smaller tendrils is more.
        num_projectiles= RandomInt((num_projectiles + 3),(num_projectiles*2 + 3) )
        horizontal_angle = (2*3.141592) / num_projectiles
        
        ------------------------------------------------------------------------------------------
        ------------Create SMALL TENDRILS projectiles------------

        local vx, vy, vz = ProjectileGetVelocity(self)
        for i = 0, (num_projectiles -1) do
            xVec = vx + (MathSin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            yVec = RandomFloat(-3,33)
            zVec = vz + (MathCos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            local proj = ProjectileCreateChildProjectile(self, SmallTendrilProjectile):
            ProjectileSetLifetime(proj, RandomFloat(0.25,0.35)):
            ProjectileSetVelocity(proj, xVec,yVec,zVec):
            ProjectileSetVelocity(proj, velocity)
            ProjectileSetBallisticAcceleration(proj, 0,-89.92,0)
                                   
        end
        
        SIFHuAntiNuke.OnImpact(self, TargetType, TargetEntity)
    end,
     
}
TypeClass = SIFHuAntiNuke01

