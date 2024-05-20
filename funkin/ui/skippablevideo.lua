local SkippableVideo = Video:extend("SkippableVideo")

function SkippableVideo:new(...)
	SkippableVideo.super.new(self, ...)

	self.label = Text(12, game.height - 33, "", paths.getFont("continum.ttf", 22), Color.WHITE)
	self.label.outline.width = 1

	self.text = "Press ACCEPT key to Skip the Video Cutscene"
end

function SkippableVideo:showText()
	if self.shownText then return end
	self.shownText = true

	self.textActive = true
	self.label.content = self.text
	self.label.alpha = 0
	Timer.tween(1, self.label, {alpha = 1}, "out-quad", function()
		if not self.textActive then return end
		Timer.after(3, function()
			if not self.textActive then return end
			Timer.tween(1, self.label, {alpha = 0}, "in-quad")
		end)
	end)

	game.bound:add(self.label)
end

function SkippableVideo:play(...)
	SkippableVideo.super.play(self)
	if self.__handle and self.parent then self:showText() end
end

function SkippableVideo:enter(parent)
	self.parent = parent
	if self:isPlaying() then self:showText() end
end

function SkippableVideo:leave()
	self.parent = nil
	if self.textActive then game.bound:remove(self.label) end
end

function SkippableVideo:reset(cleanup)
	SkippableVideo.super.reset(self, cleanup)
	if self.textActive then game.bound:remove(self.label) end
end

function SkippableVideo:update(dt)
	SkippableVideo.super.update(self, dt)

	if self:isPlaying() and controls:pressed("accept") then
		local onComplete = self.onComplete
		if self.autoDestroy then
			self:kill()
		else
			self:stop()
		end

		if onComplete then onComplete() end
	end
end

return SkippableVideo