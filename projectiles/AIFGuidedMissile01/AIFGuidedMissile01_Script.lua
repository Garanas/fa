--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFGuidedMissile01/AIFGuidedMissile01_script.lua
--**  Author(s):  Matt Vainio, Gordon Duclos
--**
--**  Summary  :  Aeon Guided Missile, DAA0206
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AGuidedMissileProjectile = import('/lua/aeonprojectiles.lua').AGuidedMissileProjectile
local RandF = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance 
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity

-- attach for CTRL + SHIFT F replacement

local ChildProjectileBP = '/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_proj.bp'    

AIFGuidedMissile = Class(AGuidedMissileProjectile) {
    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
        local launcher = self.Launcher
        if launcher and not launcher:IsDead() then
            launcher:ProjectileFired()
        end		
		ForkThread( self.SplitThread , self)
    end,

    SplitThread = function(self)
		
        ------Create/play the split effects.
        local army = self.Army
		for k,v in EffectTemplate.AMercyGuidedMissileSplit do
            CreateEmitterOnEntity(self, army, v)
        end
        
		WaitSeconds( 0.1 )
		-- Create several other projectiles in a dispersal pattern
        local vx, vy, vz = ProjectileGetVelocity(self)
        local velocity = 16		
        local numProjectiles = 8
        local angle = (2*3.141592) / numProjectiles
        local angleInitial = RandF( 0, angle )      
        local spreadMul = 0.4 -- Adjusts the width of the dispersal        
       
        local xVec = 0 
        local yVec = vy*0.8
        local zVec = 0
        
        -- Adjust damage by number of split projectiles
        self.DamageData.DamageAmount = self.DamageData.DamageAmount / numProjectiles

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles - 1) do
            xVec = vx + MathSin(angleInitial + (i*angle) ) * spreadMul * RandF( 0.6, 1.3 )
            zVec = vz + MathCos(angleInitial + (i*angle) ) * spreadMul * RandF( 0.6, 1.3 )
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            ProjectileSetVelocity(proj,  xVec, yVec, zVec )
            ProjectileSetVelocity(proj,  velocity * RandF( 0.8, 1.2 ) )
            proj.PassDamageData(proj, self.DamageData)                        
        end        
        EntityDestroy(self) 
    end,  
}
TypeClass = AIFGuidedMissile

