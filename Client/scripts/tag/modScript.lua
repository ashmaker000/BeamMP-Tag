log("I", "BeamMP-Tag", "Loading /scripts/tag/modScript.lua")

-- Load client GE extensions early so rounds don't miss startup events.
load("vignetteShaderAPI")
load("tag")

setExtensionUnloadMode("vignetteShaderAPI", "manual")
setExtensionUnloadMode("tag", "manual")

log("I", "BeamMP-Tag", "Loaded tag + vignetteShaderAPI via modScript")
