local MainMenuState = State:extend("MainMenuState")
MainMenuState.curSelected = 1

function MainMenuState:new(trans)
	MainMenuState.super.new(self)

	self.skipTransIn = trans
	self.doTransfromTitle = trans
	self.optionShit = {'story_mode', 'freeplay', 'credits', 'options'}
	self.selectedSomethin = false
end

function MainMenuState:enter()
	MainMenuState.super.enter(self)

	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Main Menu"})
	end

	local wa = Graphic(0, 0, game.width, game.height, {0, 68 / 255, 153 / 255})
	wa:setScrollFactor()
	self:add(wa)

	local bg = Backdrop(paths.getImage('menus/checker'))
	bg.velocity = {x = 50, y = 40}
	bg:setScrollFactor(.4, .4)
	bg.moves = true
	self:add(bg)

	local blob = Sprite(0, 0, paths.getImage('menus/MainMenuBackBlob'))
	blob:screenCenter()
	blob:setScrollFactor(0, .1)
	blob.alpha = 0.5
	blob.y = blob.y + 70
	self:add(blob)

	self.border = Graphic(0, game.height - 199, game.width, 200, Color.BLACK)
	self.border:setScrollFactor(0, 1)
	self.border:updateHitbox()
	self.border.alpha = .6

	self.imageItems = SpriteGroup(); self.imageItems:setScrollFactor(.5, .5)
	self.menuItems = SpriteGroup(); self.menuItems:setScrollFactor(.5, .5)
	self:add(self.imageItems)

	local imageAtlas = paths.getSparrowAtlas('menus/mainmenu/MenuImages')
	for i, v in ipairs(self.optionShit) do
		local image = Sprite(math.floor((i + .5) * game.width)); image:setFrames(imageAtlas)
		image:addAnimByPrefix('nya~', v, 0)
		image:play("nya~")
		image:updateHitbox()
		image.x, image.y = image.x - math.floor(image:getFrameWidth() / 2), math.floor((game.height - 200 - image:getFrameHeight()) / 2)
		self.imageItems:add(image)

		local menu = Sprite(); menu:setFrames(paths.getSparrowAtlas('menus/mainmenu/menu_'..v))
		menu:addAnimByPrefix('idle', v..' basic', 12)
		menu:addAnimByPrefix('selected', v..' white', 12)
		menu:play('idle')
		menu.scale = {x = .8, y = .8}
		menu:updateHitbox()
		menu.y, menu.ID = math.floor(self.border.y + (200 - menu.height) / 2), i
		self.menuItems:add(menu)
	end

	self:add(self.border)
	self:add(self.menuItems)

	local arrowAtlas = paths.getSparrowAtlas('menus/arrows')
	local arrowY = math.floor(self.border.y + (200 - (185 * .8)) / 2)

	local arrowLeft = Sprite(0, arrowY); self.arrowLeft = arrowLeft
	arrowLeft:setFrames(arrowAtlas)
	arrowLeft:addAnimByPrefix('idle', 'ArrowIdle', 12, true)
	arrowLeft:addAnimByPrefix('pressed', 'ArrowPressed', 12, true)
	arrowLeft:play('idle')
	arrowLeft.scale = {x = .8, y = .8}
	arrowLeft:updateHitbox()
	arrowLeft:screenCenter("x")
	arrowLeft:setScrollFactor(0.5, 0.5)
	self.arrowWidth = math.floor(arrowLeft:getFrameWidth())
	self:add(arrowLeft)

	local arrowRight = Sprite(0, arrowY); self.arrowRight = arrowRight
	arrowRight:setFrames(arrowAtlas)
	arrowRight:addAnimByPrefix('idle', 'ArrowIdle', 12, true)
	arrowRight:addAnimByPrefix('pressed', 'ArrowPressed', 12, true)
	arrowRight:play('idle')
	arrowRight.scale = {x = .8, y = .8}
	arrowRight:updateHitbox()
	arrowRight:screenCenter("x")
	arrowRight:setScrollFactor(0.5, 0.5)
	arrowRight.flipX = true
	self:add(arrowRight)

	local versionFormat = "FNF LÖVE v%engineVersion\nFNF: Vs Rodamrix v%version"
	local versionText = Text(12, 0, versionFormat:gsub("%%engineVersion", Project.engineVersion):gsub("%%version", Project.version),
		paths.getFont("continum.ttf", 18))
	versionText.y = self.border.y - versionText:getHeight() - 8
	versionText.antialiasing = false
	versionText.outline.width = 1
	versionText:setScrollFactor(0, 0.4)
	self:add(versionText)

	local borderTransition = Graphic(0, game.height, game.width, game.height, Color.BLACK)
	borderTransition:setScrollFactor(0, 1.2)
	borderTransition:updateHitbox()
	self:add(borderTransition)

	if ClientPrefs.data.shader then
		self.wiggle = WiggleEffect(WiggleEffect.HEAT_WAVE_VERTICAL, 1.2, 30, .02)
		blob.shader = self.wiggle.shader
	end

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"}, .1, .4)
	self.throttles.left = Throttle:make({controls.down, controls, "ui_left"}, .1, .4)
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"}, .1, .4)
	self.throttles.right = Throttle:make({controls.down, controls, "ui_right"}, .1, .4)

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local left = VirtualPad("left", 0, game.height - w)
		local right = VirtualPad("right", w, left.y)
		--local mods = VirtualPad("6", game.width - w, 0)
		--mods:screenCenter("y")

		local enter = VirtualPad("return", game.width - w, left.y)
		enter.color = Color.GREEN
		local back = VirtualPad("escape", enter.x - w, left.y)
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(right)
		--self.buttons:add(mods)

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
	end

	self.imageItems.x = -MainMenuState.curSelected * game.width

	util.playMenuMusic()
	self:changeSelection()
	self:updateMenuItems(99999)

	if self.doTransfromTitle then
		game.camera.scroll.y = game.height - 200
		self.border.alpha = 1

		Timer.tween(0.57, game.camera.scroll, {y = 0}, "out-quad")
		Timer.tween(0.57, self.border, {alpha = .6}, "out-quad")
	end
end

function MainMenuState:update(dt)
	if not self.selectedSomethin and self.throttles then
		if self.throttles.left:check() or self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.right:check() or self.throttles.down:check() then self:changeSelection(1) end

		if controls:pressed("back") then
			util.playSfx(paths.getSound('cancelMenu')).persist = true
			Timer.tween(0.7, self.border, {alpha = 1}, "in-sine")
			Timer.tween(0.7, game.camera.scroll, {y = game.height - 200}, "in-sine", function()
				self.skipTransOut = true
				game.switchState(TitleState())
			end)
		end

		if controls:pressed("accept") then
			self:enterSelection(self.optionShit[MainMenuState.curSelected])
		end
	end

	if self.wiggle then self.wiggle:update(dt) end
	self:updateMenuItems(dt)
	self.imageItems.x = util.coolLerp(self.imageItems.x, -MainMenuState.curSelected * game.width, 9, dt)

	MainMenuState.super.update(self, dt)
end

function MainMenuState:updateMenuItems(dt)
	local curSelected, menuItems = MainMenuState.curSelected, self.menuItems.members
	local firstMenu = menuItems[curSelected]; local firstX = (game.width - firstMenu.width) / 2
	firstMenu.x = util.coolLerp(firstMenu.x, firstX, 9, dt)

	if not self.selectedSomethin then firstMenu.alpha = 1 end

	local x, i, total, menu = firstX - self.arrowWidth - 16, curSelected - 1, 1
	while i >= total do
		menu = menuItems[i]; x = x - menu.width
		if not self.selectedSomethin then menu.alpha = 1 - (math.abs(curSelected - i) / 4) end

		menu.x, x, i = util.coolLerp(menu.x, x, 9, dt), x - 4, i - 1
	end
	
	x, i, total = firstX + firstMenu.width + self.arrowWidth + 16, curSelected + 1, #menuItems
	while i <= total do
		menu = menuItems[i]
		if not self.selectedSomethin then menu.alpha = 1 - (math.abs(curSelected - i) / 4) end

		menu.x, x, i = util.coolLerp(menu.x, x, 9, dt), x + menu.width + 4, i + 1
	end
end

local triggerChoices = {
	story_mode = {true, function(self)
		--local trans = self.transOut or self.defaultTransOut
		--Timer.tween(trans.duration, game.camera.scroll, {y = -game.height}, "in-sine")
		game.switchState(StoryMenuState())
	end},
	freeplay = {true, function(self)
		game.switchState(FreeplayState())
	end},
	credits = {true, function(self)
		game.switchState(CreditsState())
	end},
	options = {false, function(self)
		if self.buttons then
			self.buttons:disable()
		end
		self.optionsUI = self.optionsUI or Options(true, function()
			self.selectedSomethin = false

			if Discord then
				Discord.changePresence({details = "In the Menus", state = "Main Menu"})
			end
			if self.buttons then
				self.buttons:enable()
			end
		end)
		self.optionsUI.applySettings = bind(self, self.onSettingChange)
		self.optionsUI:setScrollFactor()
		self.optionsUI:screenCenter()
		self:add(self.optionsUI)
		return false
	end}
}

function MainMenuState:onSettingChange(setting, option)
	if setting == "gameplay" and option == "menuMusicVolume" then
		game.sound.music:fade(1, game.sound.music:getVolume(), ClientPrefs.data.menuMusicVolume / 100)
	end
end

function MainMenuState:openEditorMenu()
	self.selectedSomethin = true
	self.editorUI = self.editorUI or EditorMenu(function()
		self.selectedSomethin = false
	end)
	self.editorUI:setScrollFactor()
	self.editorUI:screenCenter()
	self:add(self.editorUI)
end

function MainMenuState:enterSelection(choice)
	local switch = triggerChoices[choice]
	self.selectedSomethin = true

	util.playSfx(paths.getSound('confirmMenu')).persist = true

	for _, spr in ipairs(self.menuItems.members) do
		if MainMenuState.curSelected == spr.ID then
			Flicker(spr, 1, 0.05, true, false, function()
				self.selectedSomethin = not switch[2](self)
			end)
		elseif switch[1] then
			Timer.tween(0.4, spr, {alpha = 0}, 'out-quad', function()
				spr:destroy()
			end)
		end
	end
end

function MainMenuState:changeSelection(add)
	local curSelected, length = MainMenuState.curSelected, #self.optionShit
	if add ~= nil then
		local snd = paths.getSound('cancelMenu')

		curSelected = curSelected + add
		if curSelected > length then
			curSelected = length; self:updateMenuItems(99999)
			for _, m in ipairs(self.menuItems.members) do m.x = m.x - 30 end
		elseif curSelected < 1 then
			curSelected = 1; self:updateMenuItems(99999)
			for _, m in ipairs(self.menuItems.members) do m.x = m.x + 30 end
		else
			snd = paths.getSound('scrollMenu')
		end

		if MainMenuState.curSelected ~= curSelected then
			local menu = self.menuItems.members[MainMenuState.curSelected]
			if menu then
				menu:play('idle'); menu:updateHitbox()
				menu.y = math.floor(self.border.y + (200 - menu.height) / 2)
			end
		end
		MainMenuState.curSelected = curSelected; util.playSfx(snd)
	end

	local menu = self.menuItems.members[curSelected]
	menu:play("selected")
	menu:updateHitbox()
	menu.y = math.floor(self.border.y + (200 - menu.height) / 2)

	self.arrowLeft:screenCenter("x")
	self.arrowLeft.x = self.arrowLeft.x - math.floor((menu.width + self.arrowLeft:getFrameWidth()) / 2 + 8)
	self.arrowLeft.color = curSelected > 1 and Color.WHITE or Color.GRAY

	self.arrowRight:screenCenter("x")
	self.arrowRight.x = self.arrowRight.x + math.floor((menu.width + self.arrowRight:getFrameWidth()) / 2 + 8)
	self.arrowRight.color = curSelected < length and Color.WHITE or Color.GRAY
end

function MainMenuState:leave()
	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil

	if self.editorUI then self.editorUI:destroy() end
	self.editorUI = nil

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil
end

return MainMenuState