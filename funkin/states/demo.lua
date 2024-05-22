local DemoState = State:extend("DemoState")

function DemoState:enter()
	self.transIn = TransitionData(0.6)
	self.transOut = TransitionData(2)
	DemoState.super.enter(self)

	self:add(Sprite(550, 300, paths.getImage("menus/title/demoyeah")))

	local text = Text(0, 80, "Hey!", paths.getFont("continum.ttf", 52), Color.WHITE)
	text:screenCenter("x")
	self:add(text)

	local text = Text(100, 220,
		"This build is a demo of FNF: Vs Rodamrix Mod" ..
		"\nThe mod is still in development so a lot of things might change in the future!" ..
		"\nThis demo only included 2 WIP weeks and 3 songs in the mod" ..
		"\n\nHave fun playing this demo!"
	, paths.getFont("continum.ttf", 30), Color.WHITE)
	self:add(text)

	if love.system.getDevice() == "Mobile" then
		self:add(VirtualPad("return", 0, 0, game.width, game.height, false))
	end
end

function DemoState:update(dt)
	DemoState.super.update(self, dt)

	if not self.yeah and controls:pressed("accept") then
		self.yeah = true

		util.playSfx(paths.getSound("confirmMenu"), .6).persist = true
		game.camera:flash(Color.WHITE, 1, nil, true)

		game.save.data.seenDemo = true
		game.switchState(TitleState())
	end
end

return DemoState