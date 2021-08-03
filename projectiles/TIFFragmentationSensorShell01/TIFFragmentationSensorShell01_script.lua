--
-- Terran Fragmentation/Sensor Shells
--
local EffectTemplate = import('/lua/EffectTemplates.lua')
local TArtilleryProjectile = import('/lua/terranprojectiles.lua').TArtilleryProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

-- globals as upvalues for performance 
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntityGetPosition = EntityMethods.GetPosition

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile

-- attach for CTRL + SHIFT F replacement

TIFFragmentationSensorShell01 = Class(TArtilleryProjectile) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        
        local bp = self.Blueprint.Physics
        local bpFragmentId = bp.FragmentId
        local bpFragments = bp.Fragments
        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag 
        local damageData = self.DamageData
        local otherdata = self.Data

        -- Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity( self, self.Army, v )
        end
        
        local vx, vy, vz = ProjectileGetVelocity(self)
        local velocity = 6
    
		-- One initial projectile following same directional path as the original
        local proj = ProjectileCreateChildProjectile(self, bpFragmentId)
        ProjectileSetVelocity(proj, vx, vy, vz)
        ProjectileSetVelocity(proj, velocity)
        proj.PassDamageData(proj, damageData)
   		
		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bpFragments - 1
        local angle = (2 * 3.141592) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        
        -- Randomization of the spread
        local angleVariation = angle * 0.35 -- Adjusts angle variance spread
        local spreadMul = 0.5 -- Adjusts the width of the dispersal        
        
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
        local pos = EntityGetPosition(self)
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = otherdata.Radius,
            LifeTime = otherdata.Lifetime,
            Army = otherdata.Army,
            Omni = false,
            WaterVision = false,
        }
        local vizEntity = VizMarker(spec)
        EntityDestroy(self)

    end,
    
    

}

TypeClass = TIFFragmentationSensorShell01