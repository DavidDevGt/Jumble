local Graphics = {}

Graphics.canvas = nil
Graphics.shader = nil
Graphics.font = nil

Graphics.color = {1, 1, 1, 1}
Graphics.backgroundColor = {0.1, 0.1, 0.1, 1}

Graphics.transform = {}

function Graphics.init()
    Graphics.setBackgroundColor(0.1, 0.1, 0.1)
end

function Graphics.clear(r, g, b, a)
    love.graphics.clear(r or Graphics.backgroundColor[1], 
                   g or Graphics.backgroundColor[2], 
                   b or Graphics.backgroundColor[3], 
                   a or Graphics.backgroundColor[4])
end

function Graphics.setBackgroundColor(r, g, b, a)
    if type(r) == "table" then
        Graphics.backgroundColor = r
    else
        Graphics.backgroundColor = {r or 0, g or 0, b or 0, a or 1}
    end
    love.graphics.setBackgroundColor(unpack(Graphics.backgroundColor))
end

function Graphics.setColor(r, g, b, a)
    if type(r) == "table" then
        Graphics.color = r
    else
        Graphics.color = {r or 1, g or 1, b or 1, a or 1}
    end
    love.graphics.setColor(unpack(Graphics.color))
end

function Graphics.getColor()
    return Graphics.color[1], Graphics.color[2], Graphics.color[3], Graphics.color[4]
end

function Graphics.setFont(font)
    Graphics.font = font
    love.graphics.setFont(font)
end

function Graphics.newFont(size, hinting)
    size = size or 12
    hinting = hinting or "normal"
    return love.graphics.newFont(size, hinting)
end

function Graphics.getFont()
    return love.graphics.getFont()
end

function Graphics.setCanvas(canvas)
    Graphics.canvas = canvas
    love.graphics.setCanvas(canvas)
end

function Graphics.getCanvas()
    return love.graphics.getCanvas()
end

function Graphics.setShader(shader)
    Graphics.shader = shader
    love.graphics.setShader(shader)
end

function Graphics.getShader()
    return love.graphics.getShader()
end

function Graphics.setBlendMode(mode, alphamode)
    love.graphics.setBlendMode(mode, alphamode)
end

function Graphics.getBlendMode()
    return love.graphics.getBlendMode()
end

function Graphics.setLineWidth(width)
    love.graphics.setLineWidth(width)
end

function Graphics.getLineWidth()
    return love.graphics.getLineWidth()
end

function Graphics.rectangle(mode, x, y, w, h)
    love.graphics.rectangle(mode, x, y, w, h)
end

function Graphics.circle(mode, x, y, r, segments)
    segments = segments or 25
    love.graphics.circle(mode, x, y, r, segments)
end

function Graphics.polygon(mode, ...)
    love.graphics.polygon(mode, ...)
end

function Graphics.line(...)
    love.graphics.line(...)
end

function Graphics.points(...)
    love.graphics.points(...)
end

function Graphics.arc(mode, arctype, x, y, r, angle1, angle2, segments)
    segments = segments or 25
    love.graphics.arc(mode, arctype or "pie", x, y, r, angle1, angle2, segments)
end

function Graphics.ellipse(mode, x, y, rx, ry, segments)
    segments = segments or 25
    love.graphics.ellipse(mode, x, y, rx, ry, segments)
end

function Graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
    return love.graphics.print(text, x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0)
end

function Graphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    return love.graphics.printf(text, x or 0, y or 0, limit or math.huge, align or "left", r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0)
end

function Graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    return love.graphics.draw(drawable, x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0)
end

function Graphics.push(stack)
    love.graphics.push(stack or "transform")
end

function Graphics.pop()
    love.graphics.pop()
end

function Graphics.origin()
    love.graphics.origin()
end

function Graphics.rotate(angle)
    love.graphics.rotate(angle)
end

function Graphics.scale(sx, sy)
    sx = sx or 1
    sy = sy or sx
    love.graphics.scale(sx, sy)
end

function Graphics.translate(dx, dy)
    love.graphics.translate(dx or 0, dy or 0)
end

function Graphics.shear(kx, ky)
    love.graphics.shear(kx or 0, ky or 0)
end

function Graphics.getDimensions()
    return love.graphics.getDimensions()
end

function Graphics.getWidth()
    return love.graphics.getWidth()
end

function Graphics.getHeight()
    return love.graphics.getHeight()
end

function Graphics.getPixelDimensions()
    return love.graphics.getPixelDimensions()
end

function Graphics.newImage(filename, settings)
    return love.graphics.newImage(filename, settings)
end

function Graphics.newCanvas(width, height, settings)
    width = width or love.graphics.getWidth()
    height = height or love.graphics.getHeight()
    return love.graphics.newCanvas(width, height, settings)
end

function Graphics.newQuad(x, y, w, h, sw, sh)
    return love.graphics.newQuad(x, y, w, h, sw, sh)
end

function Graphics.newSpriteBatch(image, maxsprites, usage)
    return love.graphics.newSpriteBatch(image, maxsprites or 1000, usage or "dynamic")
end

function Graphics.newParticleSystem(texture, buffer)
    return love.graphics.newParticleSystem(texture, buffer or 1000)
end

function Graphics.newMesh(vertices, mode, usage)
    return love.graphics.newMesh(vertices, mode or "fan", usage or "dynamic")
end

function Graphics.newText(font, textstring)
    return love.graphics.newText(font, textstring)
end

function Graphics.newShader(pixelcode, vertexcode)
    return love.graphics.newShader(pixelcode, vertexcode)
end

function Graphics.setWireframe(enable)
    love.graphics.setWireframe(enable)
end

function Graphics.isWireframe()
    return love.graphics.isWireframe()
end

function Graphics.setScissor(x, y, w, h)
    if x then love.graphics.setScissor(x, y, w, h) else love.graphics.setScissor() end
end

function Graphics.getScissor()
    return love.graphics.getScissor()
end

function Graphics.setStencilTest(comparemode, comparevalue)
    if comparemode then love.graphics.setStencilTest(comparemode, comparevalue) else love.graphics.setStencilTest() end
end

function Graphics.getStencilTest()
    return love.graphics.getStencilTest()
end

function Graphics.stencil(stencilfunction, action, value, keepvalues)
    love.graphics.stencil(stencilfunction, action or "replace", value or 1, keepvalues or false)
end

Graphics.BlendMode = {
    ALPHA = "alpha",
    REPLACE = "replace",
    SCREEN = "screen",
    ADD = "add",
    SUBTRACT = "subtract",
    MULTIPLY = "multiply",
    LIGHTEN = "lighten",
    DARKEN = "darken"
}

Graphics.AlignMode = {
    LEFT = "left",
    CENTER = "center",
    RIGHT = "right",
    JUSTIFY = "justify"
}

Graphics.DrawMode = {
    FILL = "fill",
    LINE = "line"
}

return Graphics