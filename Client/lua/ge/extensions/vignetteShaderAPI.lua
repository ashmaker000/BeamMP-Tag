require("client/postFx/tagVignette")

local M = {}

local vignettePostFX = scenetree.findObject("TagVignettePostFX")

local enabled = false

local function setEnabled(state)
	enabled = state
	if not vignettePostFX then return end
	vignettePostFX.isEnabled = state
	if state then
		vignettePostFX.color = Point4F(0.0, 0.25, 0.5, 1)
	end
end

local function setDistance(distancecolor)
	if not vignettePostFX then return end
	local d = math.max(0, tonumber(distancecolor) or 0)
	vignettePostFX.innerRadius = 1 - d
	vignettePostFX.outerRadius = 2.1 - d
end

local function resetVignette()
	if not vignettePostFX then return end
	vignettePostFX.innerRadius = 0
	vignettePostFX.outerRadius = 0
	vignettePostFX.center = Point2F(0.5, 0.5)
	vignettePostFX.color = Point4F(0, 0.2, 0, 0)
	setEnabled(false)
end

local function setInnerRadius(value)
	vignettePostFX.innerRadius = value or 1
end
local function setOuterRadius(value)
	vignettePostFX.outerRadius = value or 1
end
local function setColor(color)
	vignettePostFX.color = color --Point4F(0, 0.2, 0, 0)
end

local function isEnabled()
	return enabled
end

M.setEnabled = setEnabled
M.isEnabled = isEnabled
M.setDistance = setDistance
M.resetVignette = resetVignette

M.setInnerRadius = setInnerRadius
M.setOuterRadius = setOuterRadius
M.setColor = setColor


M.onInit = function() setExtensionUnloadMode("vignetteShaderAPI", "manual") end

return M