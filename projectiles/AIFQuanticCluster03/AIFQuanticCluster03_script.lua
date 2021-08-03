--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFQuanticCluster03/AIFQuanticCluster03_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Quantic Cluster Projectile script
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AQuantumCluster = import('/lua/aeonprojectiles.lua').AQuantumCluster
local EffectTemplate = import('/lua/EffectTemplates.lua')
local TFragmentationSensorShellTrail = EffectTemplate.TFragmentationSensorShellTrail
local TFragmentationSensorShellHit = EffectTemplate.TFragmentationSensorShellHit

AIFQuanticCluster03 = Class(AQuantumCluster) {
    FxTrails     = TFragmentationSensorShellTrail,
    FxImpactUnit = TFragmentationSensorShellHit,
    FxImpactLand = TFragmentationSensorShellHit,
}
TypeClass = AIFQuanticCluster03