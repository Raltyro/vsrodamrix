local TitleState = State:extend("TitleState")

TitleState.initialized = false

function TitleState:new()
	TitleState.super.new(self)
	self.skipTransIn = true
	self.skippedIntro = false
	self.danceLeft = false
	self.confirmed = false
	self.sickSteps = 0
end

function TitleState:enter()
	TitleState.super.enter(self)

	self.curWacky = self:getIntroTextShit()
	self.bbg = Graphic(0, 0, game.width, game.height, {0, 68, 153})

	local blob = Sprite():loadTexture(paths.getImage('menus/MainMenuBackBlob')); self.blob = blob
	blob:screenCenter()
	blob.scrollFactor = {x = 0, y = .1}
	blob.alpha = 0.5
	blob.y = blob.y + 30

	self.borderTop = Graphic(0, -game.height, game.width, game.height + 120, Color.BLACK)
	self.borderTop:updateHitbox()

	self.borderBottom = Graphic(0, game.height - 119, game.width, 120, Color.BLACK)
	self.borderBottom:updateHitbox()

	local logoBl = Sprite(); self.logoBl = logoBl
	logoBl:setFrames(paths.getSparrowAtlas("menus/logoBumpin"))
	logoBl:addAnimByPrefix("bump", "logo bumpin", 24, false)
	logoBl:play("bump")
	logoBl:updateHitbox()
	logoBl:screenCenter()
	logoBl.scrollFactor = {x = 1.2, y = 1.2}

	local titleText = Sprite(game.width / 2 - 500, game.height - 100); self.titleText = titleText
	titleText:setFrames(paths.getSparrowAtlas("menus/title/titleEnter"))
	titleText:addAnimByPrefix("idle", "ENTER IDLE", 24)
	titleText:addAnimByPrefix("press", "ENTER PRESSED", 24)
	titleText:updateHitbox()
	titleText:play("idle")
	titleText.colors = {{50, 60, 205}, {50, 255, 255}}

	self.ngSpr = Sprite(0, game.height * 0.48):loadTexture(paths.getImage('menus/title/newgrounds_logo'))
	self.ngSpr:setGraphicSize(math.floor(self.ngSpr.width * 0.8))
	self.ngSpr:updateHitbox()
	self.ngSpr:screenCenter("x")

	self.textGroup = Group()
	self:add(self.textGroup)

	if TitleState.initialized then
		self:skipIntro()
	else
		TitleState.initialized = true
	end

	self.conductor = Conductor(105)
	self.conductor.onStep = bind(self, self.step)
	self.conductor.onBeat = bind(self, self.beat)
	util.playMenuMusic()

	if love.system.getDevice() == "Mobile" then
		self:add(VirtualPad("return", 0, 0, game.width, game.height, false))
	end
end

function TitleState:getIntroTextShit()
	local fullText = paths.getText('introText')
	local firstArray = fullText:split('\n')
	local swagGoodArray = firstArray[love.math.random(1, #firstArray)]

	return swagGoodArray:split('--')
end

function TitleState:customTransitionOut()
	
end

function TitleState:update(dt)
	self.conductor.time = self.conductor.time + dt * 1000
	self.conductor:update()

	if love.system.getDevice() == "Mobile" and game.keys.justPressed.ESCAPE then
		local name = love.window.getTitle()
		if #name == 0 or name == "Untitled" then name = "Game" end

		local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", {"OK", "Cancel"})
		if pressed == 1 then love.event.push("quit") end
	end

	local pressedEnter = controls:pressed("accept")

	if pressedEnter and not self.confirmed and self.skippedIntro then
		self.confirmed = true
		self.titleText:play("press")
		util.playSfx(paths.getSound("confirmMenu"))
		game.camera:flash(Color.WHITE, 1)
		Timer.after(0.2, function() self:customTransitionOut() end)
	end
	self:updateEnterColor()

	if pressedEnter and not self.skippedIntro and TitleState.initialized then
		self:skipIntro()
	end
	TitleState.super.update(self, dt)
end

function TitleState:updateEnterColor()
	local color = self.titleText.colors
	local time = love.timer.getTime()
	local t = (math.sin(time * 2 * math.pi / 5) + 1) / 2

	local alpha = 0.8
	if t <= 0.5 then
		t = t * 2
		self.titleText.color = Color.convert(Color.lerp(color[2], color[1], t))
		self.titleText.alpha = math.lerp(alpha, 0.5, t)
	else
		t = (t - 0.5) * 2
		self.titleText.color = Color.convert(Color.lerp(color[1], color[2], t))
		self.titleText.alpha = math.lerp(0.5, alpha, t)
	end

	if self.confirmed then
		self.titleText.color = Color.WHITE
		self.titleText.alpha = 1
	end
end

function TitleState:createCoolText(textTable, offset)
	for _, v in ipairs(textTable) do self:addMoreText(v, offset) end
end

function TitleState:addMoreText(text, offset)
	local coolText = Alphabet(0, 0, text, true, false)
	coolText:screenCenter("x")
	coolText.y = coolText.y + (#self.textGroup.members * 60) + 200 + (offset or 0)

	self.textGroup:add(coolText)
end

function TitleState:deleteCoolText()
	while #self.textGroup.members > 0 do self.textGroup:pop() end
end

function TitleState:step(s)
	if game.sound.music ~= nil then self.conductor.time = game.sound.music:tell() * 1000 end

	if self.skippedIntro or self.confirmed then return end
	while self.sickSteps < s do
		self:nextStep()
	end
end

function TitleState:beat()
	if TitleState.initialized then
		self.logoBl:play("bump", true)
	end
end

function TitleState:nextStep()
	self.sickSteps = self.sickSteps + 1

	switch(self.sickSteps, {
		[1] = function() self:addMoreText('Rodabeanz team', -40) end,
		[6] = function()
			self:addMoreText('Qski', 14)
			self:addMoreText('The Rainbow Bubble', 14)
			self:addMoreText('N3okto', 14)
		end,
		[8] = function() self:addMoreText('and more!', 14) end,
		[16] = function() self:deleteCoolText() end,
		[20] = function() self:addMoreText('Not associated', -70) end,
		[22] = function() self:addMoreText('with', -70) end,
		[24] = function()
			self:addMoreText('newgrounds', -70)
			self:add(self.ngSpr)
		end,
		[32] = function()
			self:deleteCoolText()
			self:remove(self.ngSpr)
		end,
		[36] = function() self:addMoreText(self.curWacky[1], 70) end,
		[40] = function() self:addMoreText(self.curWacky[2], 78) end,
		[48] = function() self:deleteCoolText() end,
		[52] = function() self:addMoreText('FNF', 30) end,
		[56] = function() self:addMoreText('Vs', 30) end,
		[60] = function() self:addMoreText('RODAMRIX', 30) end,
		[64] = function() self:skipIntro() end
	})
end

function TitleState:skipIntro()
	if self.skippedIntro then return end
	game.camera:flash(Color.WHITE, 3)
	self.skippedIntro = true

	self:add(self.bbg)
	--self:add(self.bg)
	self:add(self.blob)
	self:add(self.borderTop)
	self:add(self.borderBottom)
	self:add(self.titleText)
	self:add(self.logoBl)
	self:remove(self.ngSpr)
	self:remove(self.textGroup)
	self:deleteCoolText()
end

return TitleState
