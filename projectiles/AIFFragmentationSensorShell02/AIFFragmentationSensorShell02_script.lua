--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFFragmentationSensorShell02/AIFFragmentationSensorShell02_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script,XAB2307
--**				 Child Projectile after 1st split	
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile02
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- globals as upvalues for performance 
local CreateEmitterAtBone = CreateEmitterAtBone

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile

-- attach for CTRL + SHIFT F replacement

AIFFragmentationSensorShell02 = Class(AArtilleryFragmentationSensorShellProjectile) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        if TargetType != 'Shield' then
	        local FxFragEffect = EffectTemplate.Aeon_QuanticClusterFrag02 
            local bp = self.Blueprint.Physics
			local bpFragments = bp.Fragments 
			local bpFragmentId = bp.FragmentId

			local army = self.Army
			local damageData = self.DamageData
			local otherData = self.Data
	        
	        -- Split effects
	        for k, v in FxFragEffect do
	            CreateEmitterAtBone( self, -1, army, v )
	        end
	        
	        local vx, vy, vz = ProjectileGetVelocity(self)
	        local velocity = 12
	    
			-- One initial projectile following same directional path as the original
			local proj = ProjectileCreateChildProjectile(self, bpFragmentId)
			ProjectileSetVelocity(proj, vx,0.8*vy, vz)
			ProjectileSetVelocity(velocity)
			proj.PassDamageData(proj, damageData)
	   		
			-- Create several other projectiles in a dispersal pattern
            local numProjectiles = bpFragments - 1
            local angle = (2 * 3.141592) / numProjectiles
            local angleInitial = RandomFloat( 0, angle )
            
            -- Randomization of the spread
            local angleVariation = angle * 13 -- Adjusts angle variance spread
            local spreadMul = 0.4 -- Adjusts the width of the dispersal        
			               
	        local xVec = 0 
	        local yVec = vy*0.8
	        local zVec = 0
	
	        -- Launch projectiles at semi-random angles away from split location
	        for i = 0, numProjectiles - 1 do
	            xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
	            zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul 
                local proj = ProjectileCreateChildProjectile(self, bpFragmentId)
	            proj:SetVelocity(xVec,yVec,zVec)
	            proj:SetVelocity(velocity)
	            proj.PassDamageData(proj, damageData)                        
	        end

	        local pos = EntityGetPosition(self)
	        local spec = {
	            X = pos[1],
	            Z = pos[3],
	            Radius = otherData.Radius,
	            LifeTime = otherData.Lifetime,
	            Army = otherData.Army,
	            Omni = false,
	            WaterVision = false,
	        }
	        EntityDestroy(self)
		else
	        self:DoDamage( self, self.DamageData, TargetEntity)
	        self:OnImpactDestroy(TargetType, TargetEntity)
        end
    end,
}
TypeClass = AIFFragmentationSensorShell02