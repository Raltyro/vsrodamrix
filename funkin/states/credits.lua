local CreditsState = State:extend("CreditsState")
local CreditSectionSubstate = Substate:extend("CreditSectionSubstate")

-- Title, Variable, Description, Color
CreditsState.titles = {
	{'Rodamrix Discord',		'discordroda',		'Rodamrix Discord Community Server\n(Not This FNF Mod Server)', 'discord.gg/rodamrix', {75, 92, 150}},
	{''},
	{'Credits Sections'},
	{"Rodabeanz Team",			'rodabeanz',		'Developers of Vs Rodamrix',						{0, 68, 153}},
	{'FNF LOVE2D Engine Team',	'fnflove',			'Developers of FNF Love2D Engine',					{214, 184, 192}},
	{"Funkin' Crew",			'funkin',			'The only cool kickers of Friday Night Funkin\'',	{253, 64, 171}},
	{''}
}

-- Name - Icon name - Description - Link - BG Color
CreditsState.rodabeanz = {
	{'Director'},
	{'Qski',				'qski',				'Lead Director, Lead Artist, Spriter of Vs Rodamrix',		"twitter.com/The_Qski_Guy",		{76, 85, 111}},
	{'Crystalline',			'crystal',			'Assistant Director, Lead Musician of Vs Rodamrix',			"twitter.com/crystal1ine",		{134, 197, 216}},
	{''},
	{'Rodabeanz Team'},
	{'N3okto',				'n3okto',			'Artist, Cutscene Animator of Vs Rodamrix',					'twitter.com/N3okto',			{208, 212, 232}},
	{'Zyflx',				'zyflx',			'Lead Charter of Vs Rodamrix',								'twitter.com/zyflx',			{65, 122, 70}},
	{'Raltyro',				'raltyro',			'Lazy ass, Programmer of Vs Rodamrix',						'twitter.com/raltyro',			{122, 57, 67}},
	{''},
	{'Former Members'},
	{'Ralsi',				'ralsin',			'Ex-Programmer, Ex-Charter of Vs Rodamrix',					'twitter.com/ralsi_',			{206, 206, 119}}
}

CreditsState.fnflove = {
	{'Maintainer'},
	{'Stilic',				'stilic',			'Maintainer of FNF LOVE2D Engine',							'twitter.com/stilic',			{255, 202, 69}},
	{'Fellyn',				'fellyn',			'Maintainer of FNF LOVE2D Engine (Main Programmer)',		'twitter.com/FellynnLol_',		{228, 156, 250}},
	{''},
	{'Developers'},
	{'Victor Kaoy',			'vickaoy',			'Assistant Programmer of FNF LOVE2D Engine',				'twitter.com/vk15_',			{209, 121, 77}},
	{'Raltyro',				'raltyro',			'Assistant Programmer of FNF LOVE2D Engine, help',			'twitter.com/raltyro',			{122, 57, 67}},
	{''},
	{'Contributors'},
	{'BlueColorSin',		'bluecolorsin',		'Ex-Assistant Programmer of FNF LOVE2D Engine',				'twitter.com/BlueColorSin',		{43, 86, 255}},
	{'Ralsi',				'ralsin',			'Couple of fixes to the Codebase',							'twitter.com/ralsi_',			{206, 206, 119}}
}

CreditsState.funkin = {
	{"Funkin' Crew"},
	{'ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",						'twitter.com/ninja_muffin99',	{247, 56, 56}},
	{'PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",							'twitter.com/PhantomArcade3K',	{255, 187, 27}},
	{'evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",							'twitter.com/evilsk8r',			{83, 229, 44}},
	{'kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",							'twitter.com/kawaisprite',		{100, 117, 243}},
}

function CreditsState:enter()
	CreditsState.super.enter(self)

	self.colorBG = {0, 68 / 255, 153 / 255}
	self.bg = Graphic(0, 0, game.width, game.height, table.clone(self.colorBG))
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.tiles = Backdrop(paths.getImage('menus/checker'))
	self.tiles.velocity = {x = 50, y = 40}
	self.tiles:setScrollFactor(.4, .4)
	self.tiles.moves = true
	self:add(self.tiles)

	local blob = Sprite(0, 0, paths.getImage('menus/MainMenuBackBlob'))
	blob:screenCenter()
	blob:setScrollFactor(0, .1)
	blob.alpha = 0.5
	blob.y = blob.y + 70
	self:add(blob)

	if ClientPrefs.data.shader then
		self.wiggle = WiggleEffect(WiggleEffect.HEAT_WAVE_VERTICAL, 1.2, 30, .02)
		blob.shader = self.wiggle.shader
	end

	self.grpOptions = Group(); self:add(self.grpOptions)
	self.grpImgs = Group(); self:add(self.grpImgs)

	local curSelect
	for i, title in ipairs(CreditsState.titles) do
		local label = Alphabet(0, 335, title[1], true)
		label.isMenuItem = true
		label.forceX = math.floor(game.width / 2)
		label.yMult = label.yMult / 1.2
		label.ID = i - 1

		label.isSelectable = #title > 1
		label.hasLink = #title == 5
		if label.isSelectable then
			if curSelect == nil then curSelect = i end

			label.descText = title[3]
			label.link = title[label.hasLink and 4 or 2]
			label.colorBG = Color.convert(title[label.hasLink and 5 or 4])

			if label.hasLink then
				label.img = HealthIcon(title[2])
			else
				label.img = Sprite(0, 0, paths.getImage("menus/credits/" .. title[2]))
				label.img.antialiasing = false
				label.img.scale = {x = 4, y = 4}
				label.img:updateHitbox()
			end

			self.grpImgs:add(label.img)
			label.img:setPosition(label.x - label.width / 2 - label.img.width / 2 - 16, label.y - label.img.height / 2)
		else
			label.yAdd = label.yAdd - 47
		end

		label.offset.y = label.offset.y - 38
		label.offset.x = label.offset.x - (label.width - (label.img and label.img.width + 8 or 0)) / 2

		label:update(99999)
		self.grpOptions:add(label)
	end

	self.descBG = Graphic(0, 0, 0, 0, Color.BLACK)
	self:add(self.descBG)

	self.descText = Text(0, 0, "", paths.getFont("continum.ttf", 32), Color.WHITE, 'center')
	self:add(self.descText)

	self.persistentUpdate = true
	self.curSelect = curSelect or 1
	self.inSection = false

	self:changeSelection()

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"}, .1, .4)
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"}, .1, .4)

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
end

function CreditsState:closeSubstate()
	CreditsState.super.closeSubstate(self)
	if self.buttons then self.buttons:enable() end

	self.descText.visible = true
	self.descBG.visible = true

	self.inSection = false
	self:changeSelection()
end

function CreditsState:update(dt)
	if self.wiggle then self.wiggle:update(dt) end
	if self.inSection then
		self.tiles:update(dt)
		return
	end

	if not self.selectedSomethin and self.throttles then
		if self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.down:check() then self:changeSelection(1) end

		if controls:pressed("back") then
			self.selectedSomethin = true
			util.playSfx(paths.getSound('cancelMenu')).persist = true
			game.switchState(MainMenuState())
		elseif controls:pressed("accept") then
			local selected = self.grpOptions.members[self.curSelect]
			if selected.hasLink then
				love.system.openURL("https://" .. selected.link)
			else
				if self.buttons then self.buttons:disable() end
				self.inSection = true

				for _, label in ipairs(self.grpOptions.members) do
					label.alpha = 0.2 if label.img then label.img.alpha = 0.2 end
				end

				self.descText.visible = false
				self.descBG.visible = false

				util.playSfx(paths.getSound('scrollMenu'))
				self:openSubstate(CreditSectionSubstate(selected.link))
			end
		end
	end

	self.bg.color = Color.lerpDelta(self.bg.color, self.colorBG, 3, dt)

	self.descText.y = util.coolLerp(self.descText.y, game.height - self.descText.height - 34, 8, dt)
	self.descBG:setPosition(self.descText.x - 8, self.descText.y - 8)
	self.descBG:setGraphicSize(self.descText.width + 16, self.descText.height + 16)
	self.descBG:updateHitbox()

	CreditsState.super.update(self, dt)

	for _, label in ipairs(self.grpOptions.members) do
		local img = label.img
		if img then img:setPosition(label.x - label.width / 2 - img.width / 2 - 16, label.y - img.height / 2) end
	end
end

function CreditsState:changeSelection(add)
	local curSelect = self.curSelect
	repeat curSelect = math.wrap(curSelect + (add or 0), 1, #self.grpOptions.members + 1)
	until self.grpOptions.members[curSelect].isSelectable
	self.curSelect = curSelect

	local curLabel
	for _, label in ipairs(self.grpOptions.members) do
		label.targetY = label.ID - curSelect + 1
		if label.targetY == 0 then
			label.alpha = 1
			curLabel = label
		else
			label.alpha = 0.8
		end
		if label.img then label.img.alpha = 1 end
	end

	if curLabel then
		self.colorBG = curLabel.colorBG

		self.descText.content = curLabel.descText
		self.descText:screenCenter('x')

		self.descText.y = game.height - self.descText.height - 40
	end

	if add ~= 0 and add ~= nil then util.playSfx(paths.getSound('scrollMenu')) end
end

function CreditsState:leave()
	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil
end

CreditsState.CreditSectionSubstate = CreditSectionSubstate
function CreditSectionSubstate:new(section)
	CreditSectionSubstate.super.new(self)

	self.section = CreditsState[section] or section
	print(section)
end

function CreditSectionSubstate:enter(state)
	CreditSectionSubstate.super.enter(self)
	if self.section == nil then error("CreditSectionSubstate don't have any section to read") end

	self.colorBG = {0, 0, 0}
	self.bg = state.bg

	self.grpOptions = Group(); self:add(self.grpOptions)
	self.grpIcons = Group(); self:add(self.grpIcons)

	local curSelect
	for i, peep in ipairs(self.section) do
		local label = Alphabet(0, 335, peep[1], true)
		label.isMenuItem = true
		label.forceX = math.floor(game.width / 2)
		label.yMult = label.yMult / 1.2
		label.ID = i - 1

		label.isSelectable = #peep > 1
		if label.isSelectable then
			if curSelect == nil then curSelect = i end

			label.descText = peep[3]
			label.link = peep[4]
			label.colorBG = Color.convert(peep[5])

			label.icon = HealthIcon(peep[2])
			self.grpIcons:add(label.icon)

			label.icon:setPosition(label.x - label.width / 2 - label.icon.width / 2 - 16, label.y - label.icon.height / 2)
		else
			label.yAdd = label.yAdd - 47
		end

		label.offset.y = label.offset.y - 38
		label.offset.x = label.offset.x - (label.width - (label.icon and label.icon.width + 8 or 0)) / 2

		label:update(99999)
		self.grpOptions:add(label)
	end

	self.descBG = Graphic(0, 0, 0, 0, Color.BLACK)
	self:add(self.descBG)

	self.descText = Text(0, 0, "", paths.getFont("continum.ttf", 32), Color.WHITE, 'center')
	self:add(self.descText)

	self.curSelect = curSelect or 1
	self:changeSelection()

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"}, .1, .4)
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"}, .1, .4)

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
end

function CreditSectionSubstate:update(dt)
	if self.throttles then
		if self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.down:check() then self:changeSelection(1) end

		if controls:pressed("back") then
			util.playSfx(paths.getSound('cancelMenu'))
			self:close()
		elseif controls:pressed("accept") then
			if love.system.getDevice() ~= "Mobile" then
				love.system.openURL("https://" .. self.grpOptions.members[self.curSelect].link)
			end
		end
	end

	if self.bg then
		self.bg.color = Color.lerpDelta(self.bg.color, self.colorBG, 3, dt)
	end

	self.descText.y = util.coolLerp(self.descText.y, game.height - self.descText.height - 34, 8, dt)
	self.descBG:setPosition(self.descText.x - 8, self.descText.y - 8)
	self.descBG:setGraphicSize(self.descText.width + 16, self.descText.height + 16)
	self.descBG:updateHitbox()

	CreditSectionSubstate.super.update(self, dt)

	for _, label in ipairs(self.grpOptions.members) do
		local icon = label.icon
		if icon then icon:setPosition(label.x - label.width / 2 - icon.width / 2 - 16, label.y - icon.height / 2) end
	end
end

function CreditSectionSubstate:changeSelection(add)
	local curSelect = self.curSelect
	repeat curSelect = math.wrap(curSelect + (add or 0), 1, #self.grpOptions.members + 1)
	until self.grpOptions.members[curSelect].isSelectable
	self.curSelect = curSelect

	local curLabel
	for _, label in ipairs(self.grpOptions.members) do
		label.targetY = label.ID - curSelect + 1
		if label.targetY == 0 then
			label.alpha = 1
			curLabel = label
		else
			label.alpha = 0.8
		end
	end

	if curLabel then
		self.colorBG = curLabel.colorBG

		self.descText.content = curLabel.descText
		self.descText:screenCenter('x')

		self.descText.y = game.height - self.descText.height - 40
	end

	if add ~= 0 and add ~= nil then util.playSfx(paths.getSound('scrollMenu')) end
end

function CreditSectionSubstate:leave()
	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil
end

return CreditsState