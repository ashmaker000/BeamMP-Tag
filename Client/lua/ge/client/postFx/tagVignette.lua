local tagVignettePostFXCallbacks = {}

tagVignettePostFXCallbacks.onAdd = function()
    local tagVignettePostFX = scenetree.findObject("TagVignettePostFX")
    if tagVignettePostFX then
        tagVignettePostFX.innerRadius = 0
        tagVignettePostFX.outerRadius = 1
        tagVignettePostFX.center = Point2F(0.5, 0.5)
        tagVignettePostFX.color = Point4F(0, 0, 0, 0.5)
    end
end

tagVignettePostFXCallbacks.setShaderConsts = function()
    local tagVignettePostFX = scenetree.findObject("TagVignettePostFX")
    if tagVignettePostFX then
        tagVignettePostFX:setShaderConst("$innerRadius", tagVignettePostFX.innerRadius)
        tagVignettePostFX:setShaderConst("$outerRadius", tagVignettePostFX.outerRadius)
        local center = tagVignettePostFX.center
        tagVignettePostFX:setShaderConst("$center", center.x and string.format("%g %g", center.x, center.y) or center)
        local color = tagVignettePostFX.color
        tagVignettePostFX:setShaderConst("$color", color.x and string.format("%g %g %g %g", color.x, color.y, color.z, color.w) or color)
    end
end
rawset(_G, "TagVignettePostFXCallbacks", tagVignettePostFXCallbacks)

local tagVignetteShader = scenetree.findObject("TagVignetteShader")
if not tagVignetteShader then
    tagVignetteShader = createObject("ShaderData")
    tagVignetteShader.DXVertexShaderFile = "shaders/common/postFx/tagVignette/tagVignetteP.hlsl"
    tagVignetteShader.DXPixelShaderFile  = "shaders/common/postFx/tagVignette/tagVignetteP.hlsl"
    tagVignetteShader.pixVersion = 5.0
    tagVignetteShader:registerObject("TagVignetteShader")
end

local tagVignettePostFX = scenetree.findObject("TagVignettePostFX")
if not tagVignettePostFX then
    tagVignettePostFX = createObject("PostEffect")
    tagVignettePostFX.isEnabled = false
    tagVignettePostFX.allowReflectPass = false
    tagVignettePostFX:setField("renderTime", 0, "PFXBeforeBin")
    tagVignettePostFX:setField("renderBin", 0, "AfterPostFX")
    --tagVignettePostFX.renderPriority = 9999;

    tagVignettePostFX:setField("shader", 0, "TagVignetteShader")
    tagVignettePostFX:setField("stateBlock", 0, "PFX_DefaultStateBlock")
    tagVignettePostFX:setField("texture", 0, "$backBuffer")

    tagVignettePostFX:registerObject("TagVignettePostFX")
end
