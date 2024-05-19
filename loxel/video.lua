local Video = Object:extend("Video")

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

function Video:new(video, autoDestroy, onComplete)
	Video.super.new(self)

	self.clipRect = nil

	self.__volume = 1
	self.__duration = 0
	self.__wasPlaying = nil

	self.width, self.height = 0, 0
	self.__width, self.__height = 0, 0

	if video then self:load(video, autoDestroy, onComplete) end
end

function Video:reset(cleanup)
	if cleanup then self:cleanup()
	elseif self.__handle ~= nil then self:stop() end
	self.autoDestroy = false
end

function Video:cleanup()
	self.active = false
	self.onComplete = nil

	if self.__handle ~= nil then
		self:stop()
		self.__handle:release()
	end
	self.__paused = true
	self.__isFinished = false
	self.__handle = nil
end

function Video:destroy()
	Video.super.destroy(self)
	self:cleanup()
end

function Video:kill()
	Video.super.kill(self)
	self:reset(self.autoDestroy)
end

function Video:load(video, autoDestroy, onComplete)
	if self.__handle then self.__handle:release() end
	self:cleanup()

	self.__handle = type(video) == "string" and love.graphics.newVideo(file, {audio = true}) or video
	self.width, self.height = self:getFrameDimensions()
	self.__width, self.__height = self.width, self.height

	return self:init(autoDestroy, onComplete)
end

function Video:init(autoDestroy, onComplete)
	if autoDestroy ~= nil then self.autoDestroy = autoDestroy end
	if onComplete ~= nil then self.onComplete = onComplete end

	self.active = true

	local source = self.__handle:getSource()
	if source then self.__duration = source:getDuration() end

	return self
end

function Video:play(volume, restart)
	if not self.active or not self.__handle then return self end

	if restart then
		pcall(self.__handle.stop, self.__handle)
	elseif self:isPlaying() then
		return self
	end

	self.__paused = false
	self.__isFinished = false
	self:setVolume(volume)
	pcall(self.__handle.play, self.__handle)
	return self
end

function Video:pause()
	self.__paused = true
	if self.__handle then pcall(self.__handle.pause, self.__handle) end
	return self
end

function Video:stop()
	self.__paused = true
	if self.__handle then pcall(self.__handle.stop, self.__handle) end
	return self
end

function Video:update(dt)
	if self.__width ~= self.width or self.__height ~= self.height then
		self:setGraphicSize(self.width, self.height)
		self.__width, self.__height = self.width, self.height
	end

	local isFinished = self:isFinished()
	if isFinished and not self.__isFinished then
		local onComplete = self.onComplete
		if self.autoDestroy then
			self:kill()
		else
			self:stop()
		end

		if onComplete then onComplete() end
	end

	self.__isFinished = isFinished

	if self.moves then
		self.velocity.x = self.velocity.x + self.acceleration.x * dt
		self.velocity.y = self.velocity.y + self.acceleration.y * dt

		self.x = self.x + self.velocity.x * dt
		self.y = self.y + self.velocity.y * dt
	end
end

function Video:focus(focus)
	if love.autoPause and self.active and not self:isFinished() then
		if focus then
			if self.__wasPlaying ~= nil and self.__wasPlaying then
				self.__wasPlaying = nil
				self:play()
			end
		else
			self.__wasPlaying = self:isPlaying()
			if self.__wasPlaying then
				self:pause()
			end
		end
	end
end

function Video:isPlaying()
	if not self.__handle then return false end

	local success, playing = pcall(self.__handle.isPlaying, self.__handle)
	return success and playing
end

function Video:isFinished()
	return self.active and not self.__paused and not self:isPlaying()
end

function Video:tell()
	if not self.__handle then return 0 end

	local success, position = pcall(self.__handle.tell, self.__handle)
	return success and position or 0
end

function Video:seek(position)
	if not self.__handle then return false end
	return pcall(self.__handle.seek, self.__handle, position)
end

function Video:getDuration()
	if not self.__handle then return -1 end
	return self.__duration
end

function Video:setVolume(volume)
	self.__volume = volume or self.__volume
	if not self.__handle then return false end
	return pcall(self.__handle.setVolume, self.__handle, self:getActualVolume())
end

function Video:getActualVolume()
	return self.__volume * (game.sound.__mute and 0 or 1) * (game.sound.__volume or 1)
end

function Sound:getVolume() return self.__volume end

function Video:getFrameWidth()
	return self.__handle and self.__handle:getWidth()
end

function Video:getFrameHeight()
	return self.__handle and self.__handle:getHeight()
end

function Video:getFrameDimensions()
	if not self.__handle then return end
	return self.__handle:getDimensions()
end

function Video:fitToScreen()
	local scale = math.min(game.width / self:getFrameWidth(), game.height / self:getFrameHeight())
	self.scale.x, self.scale.y = scale, scale

	self:screenCenter()
	self:updateHitbox()
	return self
end

Video.getGraphicMidpoint = Sprite.getGraphicMidpoint
Video.setGraphicSize = Sprite.setGraphicSize
Video.updateHitbox = Sprite.updateHitbox
Video.centerOffsets = Sprite.centerOffsets
Video.fixOffsets = Sprite.fixOffsets
Video.centerOrigin = Sprite.centerOrigin

function Video:_canDraw()
	return self.__handle ~= nil and (self.width ~= 0 or self.height ~= 0) and
		Video.super._canDraw(self)
end

function Video:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local shader = self.shader and love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local min, mag, anisotropy, mode

	mode = self.antialiasing and "linear" or "nearest"
	min, mag, anisotropy = self.__handle:getFilter()
	self.__handle:setFilter(mode, mode, anisotropy)

	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = x + ox - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		y + oy - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	love.graphics.setShader(self.shader); love.graphics.setBlendMode(self.blend)
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)

	if self.clipRect then
		stencilSprite, stencilX, stencilY = self, x, y
		love.graphics.stencil(stencil, "replace", 1, false)
		love.graphics.setStencilTest("greater", 0)
	end

	love.graphics.draw(self.__handle, x, y, rad, sx, sy, ox, oy)

	self.__handle:setFilter(min, mag, anisotropy)

	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
	if shader then love.graphics.setShader(shader) end
	if self.clipRect then love.graphics.setStencilTest() end
end

return Video