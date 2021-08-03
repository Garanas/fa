--------------------------------------------------------------------
-- File     :  /projectiles/ShieldCollider_script.lua
-- Author(s):  Exotic_Retard, made for Equilibrium Balance Mod
-- Summary  : Companion projectile enabling air units to hit shields
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------

local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

-- globals as upvalues for performance
local Warp = Warp 
local VDist2Sq = VDist2Sq
local Damage = Damage
local DamageArea = DamageArea
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateTrail = CreateTrail
local CreateDecal = CreateDecal
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateLightParticle = CreateLightParticle
local CreateEmitterOnEntity = CreateEmitterOnEntity

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 
local MathMin = _G.math.min 
local MathMax = _G.math.max 
local MathClamp = _G.math.clamp
local MathSqrt = _G.math.sqrt

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ
local EntityGetHealth = EntityMethods.GetHealth
local EntityPlaySound = EntityMethods.PlaySound
local EntityBeenDestroyed = EntityMethods.BeenDestroyed
local EntitySetMesh = EntityMethods.SetMesh
local EntityCreateProjectile = EntityMethods.CreateProjectile
local EntityGetOrientation = EntityMethods.GetOrientation
local EntityDetachAll = EntityMethods.DetachAll
local EntityGetMaxHealth = EntityMethods.GetMaxHealth

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileShakeCamera = ProjectileMethods.ShakeCamera
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileSetScaleVelocity = ProjectileMethods.SetScaleVelocity
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileSetStayUpRight = ProjectileMethods.SetStayUpRight
local ProjectileSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget
local ProjectileSetVelocityAlign = ProjectileMethods.SetVelocityAlign
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile
local ProjectileSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetLifetime = ProjectileMethods.SetLifetime
local ProjectileSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration
local ProjectileChangeMaxZigZag = ProjectileMethods.ChangeMaxZigZag
local ProjectileChangeZigZagFrequency = ProjectileMethods.ChangeZigZagFrequency
local ProjectileSetCollideSurface = ProjectileMethods.SetCollideSurface
local ProjectileSetCollision = ProjectileMethods.SetCollision

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

local TrashAdd = TrashBag.Add

-- attach for CTRL + SHIFT F replacement

local OnImpactExclusions = categories.EXPERIMENTAL + categories.TRANSPORTATION - categories.uea0203

ShieldCollider = Class(Projectile) {
    OnCreate = function(self)
        Projectile.OnCreate(self)

        self:SetVizToFocusPlayer('Never') -- Set to 'Always' to see a nice box
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetVizToEnemies('Never')
        ProjectileSetStayUpRight(self, false)
        ProjectileSetCollision(self, true)
    end,

    -- Shields only detect projectiles, so we attach one to keep track of the unit.
    Start = function(self, parent, bone)
        self.PlaneBone = bone
        self.Plane = parent
        self:StartFalling()
    end,

    StartFalling = function(self)
        local vx, vy, vz = ProjectileGetVelocity(self.Plane)

        -- For now we just follow the plane along, not attaching so it can rotate
        ProjectileSetVelocity(self, 10 * vx, 10 * vy, 10 * vz)
        Warp(self, EntityGetPosition(self.Plane, self.PlaneBone), EntityGetOrientation(self.Plane))
    end,

    OnCollisionCheck = function(self, other)
        -- We intercept this just incase the projectile collides with something it shouldn't
        WARN('Shield collision projectile checking collision! Fix me!')
        if IsUnit(other) then WARN('It was a unit!') return end

        Projectile.OnCollisionCheck(self, other)
    end,

    OnDestroy = function(self)
        self:DetachAll('anchor') -- If our projectile is getting destroyed we never want to have anything attached
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    -- Destroy the sinking unit when it hits the ground.
    OnImpact = function(self, targetType, targetEntity)
        local plane = self.Plane
        local planeBone = self.PlaneBone
        if self and not EntityBeenDestroyed(self) and plane and not EntityBeenDestroyed(plane) then
            if targetType == 'Terrain' or targetType == 'Water' then

                -- Here it should be noted that bone 0 IS NOT what the ground checks for, so if you have a projectile at that bone
                -- and the units centre is below it, then its below the ground and that can cause it to hit water instead.
                -- All this is just to prevent that, because falling planes are stupid.

                ProjectileSetVelocity(self, 0, 0, 0)
                if not plane.GroundImpacted then
                    plane:OnImpact(targetType)
                end
                EntityDestroy(self)

            elseif targetType == 'Shield' and targetEntity and not EntityBeenDestroyed(targetEntity) and targetEntity.ShieldType == 'Bubble' then
                if not self.ShieldImpacted and not plane.GroundImpacted then
                    self.ShieldImpacted = true -- Only impact once

                    -- Find the vector to the impact location, used for the impact ripple FX
                    local shieldImpactVector = VDiff(EntityGetPosition(targetEntity), EntityGetPosition(self)) -- Vector from mid of shield to impact point
                    if not EntityCategoryContains(OnImpactExclusions, plane) then -- Exclude experimentals and transports from momentum system, but not damage
                        Warp(self, EntityGetPosition(plane, planeBone), EntityGetOrientation(plane))

                        EntityDetachAll(self, 'anchor') -- Make sure to detach just in case, prior to trying to attach
                        EntityDetachAll(plane, planeBone)

                        plane:AttachBoneTo(planeBone, self, 'anchor') -- We attach our bone at the very last moment when we need it
                        plane.Detector = CreateCollisionDetector(plane)
                        plane.Detector:WatchBone(planeBone)
                        plane.Detector:EnableTerrainCheck(true)
                        plane.Detector:Enable()

                        -- If you try to deattach the plane, it has retarded game code that makes it continue falling in its original direction
                        self:ShieldBounce(targetEntity, shieldImpactVector) -- Calculate the appropriate change of velocity
                    end

                    if not plane.deathWep or not plane.DeathCrashDamage then -- Bail if stuff's missing.
                        WARN('ShieldCollider: did not find a deathWep on the plane! Is the weapon defined in the blueprint? - ' .. self.UnitId)
                        return
                    end

                    local initialDamage = plane.DeathCrashDamage
                    local deathWep = plane.deathWep

                    -- Calculate damage dealt, up to a maximum of 20% of the shield's maximum HP
                    local shieldDamageLimit = EntityGetMaxHealth(targetEntity) * 0.2

                    local mult = deathWep.DeathCrashShieldMult or 1 -- Allow a unit to be designated as dealing less than normal damage to shields on crash
                    local damage = initialDamage * mult

                    -- Damage the shield
                    local finalDamage = MathMin(shieldDamageLimit, damage)
                    targetEntity:ApplyDamage(plane, finalDamage, shieldImpactVector or {x = 0, y = 0, z = 0}, deathWep.DamageType, false)

                    -- Play an impact effect, but only if not bouncing. Also stop Exps, because it just looks very silly.
                    if not plane.Detector and not EntityCategoryContains(categories.EXPERIMENTAL, plane) then
                        plane:CreateDestructionEffects(self, self.OverKillRatio)
                    end

                    -- Update the unit's remaining crash damage
                    plane.DeathCrashDamage = initialDamage - finalDamage
                end
            elseif targetType ~= 'Shield' then -- Don't go through here for non-bubble shield collisions
                EntityDestroy(self)
            end
        end
    end,

    -- Lets do some maths that will make the units bounce off shields
    ShieldBounce = function(self, shield, vector)
        local bp = self.Plane.Blueprint
        local volume = bp.SizeX * bp.SizeY * bp.SizeZ -- We will use this to *guess* how much force to apply

        local spin = MathMin (4 / volume, 2) -- Less for larger planes; also 2 is a nice number
        self:SetLocalAngularVelocity(spin, spin, spin) -- Ideally I would just set this to whatever the plane had but I dont know how

        local vx, vy, vz = ProjectileGetVelocity(self.Plane) -- Current plane velocity
        local wx, wy, wz = vector.x, vector.y, vector.z

        -- Convert our speed values from units per tick to units per second
        vx = 10 * vx
        vy = 10 * vy
        vz = 10 * vz

        local speed = MathSqrt(vx * vx + vy * vy + vz * vz) -- The length of our vector
        local shieldMag = MathSqrt(wx * wx + wy * wy + wz * wz) -- The length of our other vector

        -- Normalizing all our shield vector, so we dont need to deal with scalar nonsense
        wx = wx / shieldMag
        wy = wy / shieldMag
        wz = wz / shieldMag

        -- Get our dot products going
        local dotProduct = vx * wx + vy * wy + vz * wz

        local ke = 0.5 * volume * speed * speed -- Our kinetic energy, used to scale the stoppingpower
        local stoppingPower = MathMin(50 / (ke * 0.5), 2) -- 2 is a perfect bounce, 0 is unaffected velocity

        local angleCos = 10 * dotProduct / (speed * shieldMag) -- We take our unit vectors and calculate the angle. That 10 is to convert speed back to its "proper" length
        angleCos = MathClamp(-1, angleCos, 1)

        -- Well, almost - its incredibly inaccurate at angles close to 0, but it doesnt matter since this is mostly a visual thing
        -- Angle = atan2(norm(cross(a,b)),dot(a,b)) -- This is the "correct" way, but we dont use atan because its a pain in the ass in lua
        -- So we just clamp it to make sure its ok and no more worries

        local forceScalar = 1 - 0.65 * angleCos * (stoppingPower / 2) -- Bounciness coefficient, set to taste; 1.0 is a 'perfect' bounce
        -- The more direct the hit the lower it is, down to a minimum of 1-0.5
        -- StoppingPower also affects this, so the more ke we have, the less our velocity is changed, and so the less our coefficient is affected.

        -- Applying our bounce velocity
        vx = -stoppingPower * wx * dotProduct + vx
        vy = -stoppingPower * wy * dotProduct + vy
        vz = -stoppingPower * wz * dotProduct + vz

        -- Sometimes absurd values pop up, probably due to rounding errors or something, so we prevent huge speeds here
        vx = MathClamp(vx, -7, 7)
        vy = MathClamp(vy, -4, 4) -- Less for y so we dont get planes flying into space
        vz = MathClamp(vz, -7, 7)

        ProjectileSetVelocity(self, forceScalar * vx, forceScalar * vy, forceScalar * vz)
    end,
}

TypeClass = ShieldCollider
