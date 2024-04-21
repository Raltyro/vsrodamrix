local stencilSprite, stencilX, stencilY = nil, 0, 0
local function stencil()
	if stencilSprite then
		love.graphics.push()
		love.graphics.translate(stencilX + stencilSprite.clipRect.x +
			stencilSprite.clipRect.width / 2,
			stencilY + stencilSprite.clipRect.y +
			stencilSprite.clipRect.height / 2)
		love.graphics.rotate(stencilSprite.angle)
		love.graphics.translate(-stencilSprite.clipRect.width / 2,
			-stencilSprite.clipRect.height / 2)
		love.graphics.rectangle("fill", -stencilSprite.width / 2,
			-stencilSprite.height / 2,
			stencilSprite.clipRect.width,
			stencilSprite.clipRect.height)
		love.graphics.pop()
	end
end

local Backdrop = Sprite:extend("Backdrop")

function Backdrop:new(texture, repeatAxes, spacingX, spacingY)
	Backdrop.super.new(self, 0, 0, texture)

	self.repeatAxes = repeatAxes or "xy"
	self.spacingX = spacingX or 0
	self.spacingY = spacingY or 0
end

local function modMin(value, step, min)
	return value - math.floor((value - min) / step) * step
end

local function modMax(value, step, max)
	return value - math.ceil((value - max) / step) * step
end

function Backdrop:_isOnScreen()
	return true
end

function Backdrop:_getBoundary()
	return 0, 0, 0, 0, 1, 1, 0, 0
end

function Backdrop:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local shader = self.shader and love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local min, mag, anisotropy, mode

	mode = self.antialiasing and "linear" or "nearest"
	min, mag, anisotropy = self.texture:getFilter()
	self.texture:setFilter(mode, mode, anisotropy)

	local f = self:getCurrentFrame()

	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = x + ox - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		y + oy - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	if f then ox, oy = ox + f.offset.x, oy + f.offset.y end

	local frameWidth, frameHeight = self:getFrameDimensions()
	local tilesX, tilesY, tileSizeX, tileSizeY = 1, 1, self.spacingX + frameWidth, self.spacingY + frameHeight

	if self.repeatAxes:find("x") then
		local left, right = modMin(x + frameWidth, tileSizeX, 0) - frameWidth,
			modMax(x, tileSizeX, camera.width) + tileSizeX

		tilesX, x = math.round((right - left) / tileSizeX), modMin(x + frameWidth, frameWidth + self.spacingX, 0) - frameWidth
	end

	if self.repeatAxes:find("y") then
		local top, bottom = modMin(y + frameHeight, tileSizeY, 0) - frameHeight,
			modMax(y, tileSizeY, camera.height) + tileSizeY

		tilesY, y = math.round((bottom - top) / tileSizeY), modMin(y + frameHeight, frameHeight + self.spacingY, 0) - frameHeight
	end

	love.graphics.setShader(self.shader); love.graphics.setBlendMode(self.blend)
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)

	for tileX = 0, tilesX do
		for tileY = 0, tilesY do
			local xx, yy = x + tileSizeX * tileX, y + tileSizeY * tileY
			if self.clipRect then
				stencilSprite, stencilX, stencilY = self, xx, yy
				love.graphics.stencil(stencil, "replace", 1, false)
				love.graphics.setStencilTest("greater", 0)
			end

			if f then love.graphics.draw(self.texture, f.quad, xx, yy, rad, sx, sy, ox, oy)
			else love.graphics.draw(self.texture, xx, yy, rad, sx, sy, ox, oy) end
		end
	end

	self.texture:setFilter(min, mag, anisotropy)

	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
	if shader then love.graphics.setShader(shader) end
	if self.clipRect then love.graphics.setStencilTest() end
end

return Backdrop