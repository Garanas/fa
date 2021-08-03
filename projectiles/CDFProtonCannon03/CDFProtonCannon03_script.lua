--
-- CDFProtonCannon03
--

local CDFProtonCannonProjectile = import('/lua/cybranprojectiles.lua').CDFProtonCannonProjectile
local CProtonCannonFXTrail02 = import('/lua/EffectTemplates.lua').CProtonCannonFXTrail02
local CProtonCannonPolyTrail02 = import('/lua/EffectTemplates.lua').CProtonCannonPolyTrail02

CDFProtonCannon03 = Class(CDFProtonCannonProjectile) {
    FxTrails = CProtonCannonFXTrail02,
    PolyTrail = CProtonCannonPolyTrail02,
}

TypeClass = CDFProtonCannon03

