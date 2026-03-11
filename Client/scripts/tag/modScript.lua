log("I", "BeamMP-Tag", "Loading /scripts/tag/modScript.lua")

-- Load client GE extensions early so rounds don't miss startup events.
load("tagVignetteAPI")
load("tag")

setExtensionUnloadMode("tagVignetteAPI", "manual")
setExtensionUnloadMode("tag", "manual")

log("I", "BeamMP-Tag", "Loaded tag + tagVignetteAPI via modScript")
