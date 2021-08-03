--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
--**  Author(s):  Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Thuntho Artillery Shell Projectile script, XSL0103
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local EffectTemplate = import('/lua/EffectTemplates.lua')
local SThunthoArtilleryShell = import('/lua/seraphimprojectiles.lua').SThunthoArtilleryShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

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

-- attach for CTRL + SHIFT F replacement

SIFThunthoArtilleryShell01 = Class(SThunthoArtilleryShell) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        
        local FxFragEffect = EffectTemplate.SThunderStormCannonProjectileSplitFx 
        local army = self.Army
        local bp = self.Blueprint.Physics
        local bpFragments = bp.Fragments
        local bpFragmentId = bp.FragmentId
        local damageData = self.DamageData
              
        ------ Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity( self, army, v )
        end
        
        local vx, vy, vz = ProjectileGetVelocity(self)
        local velocity = 18
   		
		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bpFragments
        
        local angle = (2 * 3.141592) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        
        -- Randomization of the spread
        local angleVariation = angle * 0.8 -- Adjusts angle variance spread
        local spreadMul = 0.15 -- Adjusts the width of the dispersal        
        
        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do
            xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul 
            local proj = ProjectileCreateChildProjectile(self, bpFragmentId)
            ProjectileSetVelocity(proj, xVec,yVec,zVec)
            ProjectileSetVelocity(proj, velocity)
            proj.PassDamageData(proj, damageData)                        
        end
        
        DestroyEntity(self)
    end
}

TypeClass = SIFThunthoArtilleryShell01