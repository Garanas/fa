--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFInainoStrategicMissileEffect01/SIFInainoStrategicMissileEffect01_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos
--**
--**  Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SIFInainoPlumeFxTrails01 = import('/lua/EffectTemplates.lua').SIFInainoPlumeFxTrails01
local EmitterProjectile = import('/lua/sim/defaultprojectiles.lua').EmitterProjectile

SBOOhwalliBombESIFInainoStrategicMissileEffect01ffect01 = Class(EmitterProjectile) {
	FxTrails = SIFInainoPlumeFxTrails01,
}
TypeClass = SIFInainoStrategicMissileEffect01
