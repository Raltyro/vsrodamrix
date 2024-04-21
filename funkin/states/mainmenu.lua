local TransMenu = TransitionData:extend("TransMenu")
TransMenu.update, TransMenu.draw = __NULL__, __NULL__

function TransMenu:new(duration, tween)
	self.duration, self.tween = duration, tween
end

function TransMenu:start()
	if self.status == "in" then
		game.camera.scroll.y = game.height - 200
		Timer.tween(self.duration, game.camera.scroll, {y = 0}, "out-"..self.tween, function()self:finish()end)
	else
		Timer.tween(self.duration, game.camera.scroll, {y = game.height - 200}, "in-"..self.tween, function()self:finish()end)
	end
end

local MainMenuState = State:extend("MainMenuState")
MainMenuState.curSelected = 1

function MainMenuState:new(skipTrans)
	MainMenuState.super.new(self)

	self.skipTransIn = skipTrans
	--self.transIn = TransMenu(0.7, "quad")
	--self.transOut = TransMenu(1, "sine")
	self.optionShit = {'story_mode', 'freeplay', 'donate', 'options'}
	self.selectedSomethin = false
end

function MainMenuState:enter()
	MainMenuState.super.enter(self)

	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Main Menu"})
	end

	self:add(Graphic(0, 0, game.width, game.height, {0, 68 / 255, 153 / 255}))

	local bg = Backdrop(paths.getImage('menus/checker'))
	bg.velocity = {x = 50, y = 50}
	bg.scrollFactor = {x = .4, y = .4}
	bg.moves = true

	local blob = Sprite(0, 0, paths.getImage('menus/MainMenuBackBlob'))
	blob:screenCenter()
	blob.scrollFactor = {x = 0, y = .1}
	blob.alpha = 0.5
	blob.y = blob.y + 70

	local versionFormat = "Vs Rodamrix v%version\nFNF LÖVE v%engineVersion\nFriday Night Funkin' v0.2.8"
	local versionText = Text(12, 0, versionFormat:gsub("%%engineVersion", Project.engineVersion):gsub("%%version", Project.version),
		paths.getFont("continum.ttf", 18))
	versionText.y = game.height - versionText:getHeight() - 8
	versionText.antialiasing = false
	versionText.outline.width = 1
	versionText:setScrollFactor()

	self:add(bg)
	self:add(blob)
	self:add(versionText)

	if ClientPrefs.data.shader then
		self.wiggle = WiggleEffect(WiggleEffect.HEAT_WAVE_VERTICAL, 1.2, 30, .02)
		blob.shader = self.wiggle.shader
	end

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local down = VirtualPad("down", 0, game.height - w)
		local up = VirtualPad("up", 0, down.y - w)
		local mods = VirtualPad("6", game.width - w, 0)
		mods:screenCenter("y")

		local enter = VirtualPad("return", game.width - w, down.y)
		enter.color = Color.GREEN
		local back = VirtualPad("escape", enter.x - w, down.y)
		back.color = Color.RED

		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(mods)

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
	end

	util.playMenuMusic()
end

function MainMenuState:update(dt)
	if not self.selectedSomethin and self.throttles then
		if self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.down:check() then self:changeSelection(1) end

		if controls:pressed("back") then
			game.sound.play(paths.getSound('cancelMenu')).persist = true
			game.switchState(TitleState())
		end

		if controls:pressed("accept") then
			self:enterSelection(self.optionShit[MainMenuState.curSelected])
		end

		if controls:pressed("debug_1") then
			self:openEditorMenu()
		end

		if game.keys.justPressed.TAB then
			game.switchState(CreditsState())
		end
	end

	if self.wiggle then self.wiggle:update(dt) end

	MainMenuState.super.update(self, dt)
end


local triggerChoices = {
	story_mode = {true, function(self)
		game.switchState(StoryMenuState())
	end},
	freeplay = {true, function(self)
		game.switchState(FreeplayState())
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
	end},
	donate = {false, function(self)
		love.system.openURL('https://ninja-muffin24.itch.io/funkin')
		return true
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

	game.sound.play(paths.getSound('confirmMenu'))
	Flicker(self.magentaBg, switch[1] and 1.1 or 1, 0.15, false)

	for i, spr in ipairs(self.menuItems.members) do
		if MainMenuState.curSelected == spr.ID then
			Flicker(spr, 1, 0.05, not switch[1], false, function()
				self.selectedSomethin = not switch[2](self)
			end)
		elseif switch[1] then
			Timer.tween(0.4, spr, {alpha = 0}, 'out-quad', function()
				spr:destroy()
			end)
		end
	end
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