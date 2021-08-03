-- ****************************************************************************
-- **
-- **  File     :  /data/projectiles/ADFShieldDisruptor01/ADFShieldDisruptor01_script.lua
-- **  Author(s):  Matt Vainio
-- **
-- **  Summary  :  Aeon Shield Disruptor Projectile, DAL0310
-- **
-- **  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
local ADisruptorProjectile = import('/lua/aeonprojectiles.lua').AShieldDisruptorProjectile

-- globals as upvalues for performance 
local Damage = Damage

-- math functions as upvalues for performance
local MathMin = _G.math.min 
local MathMax = _G.math.max 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetHealth = EntityMethods.GetHealth

-- attach for CTRL + SHIFT F replacement

ADFShieldDisruptor01 = Class(ADisruptorProjectile) {
    OnImpact = function(self, TargetType, TargetEntity)
        ADisruptorProjectile.OnImpact(self, TargetType, TargetEntity)
        if TargetType ~= 'Shield' then
            TargetEntity = TargetEntity.MyShield
        end

        if not TargetEntity then return end

        -- Never cause overspill damage to the unit, 1 min to avoid logspam with 0 declared damage
        local damage = MathMax(MathMin(self.Data, EntityGetHealth(TargetEntity)), 1)
        Damage(self, {0,0,0}, TargetEntity, damage, 'Normal')
    end,
}

TypeClass = ADFShieldDisruptor01
