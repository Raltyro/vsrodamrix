function create()
	self.camZoom = 1

	self.ratingPos = {x = 450, y = 500}

	self.boyfriendPos = {x = 611, y = 120}
	self.gfPos = {x = 1154, y = 437}
	self.dadPos = {x = 12, y = 196}

	self.boyfriendCam = {x = -110, y = -1}
	self.gfCam = {x = -300, y = -97}
	self.dadCam = {x = 190, y = 6}

	self.bg = Sprite(-150, -103, paths.getImage(SCRIPT_PATH .. "bg"))
	self.bg.antialiasing = true
	self.bg:setScrollFactor(0.7, 0.7)
	self.bg:updateHitbox()
	self:add(self.bg)
end

function postCreate()
	state.judgeSprites.scale.x, state.judgeSprites.scale.y = .88, .88

	self.table = Sprite(-202, 547, paths.getImage(SCRIPT_PATH .. 'table'))
	self.table.antialiasing = true
	self.table:setScrollFactor(1.08, 1.08)
	self.table:updateHitbox()
	self:add(self.table, true)

	state:remove(state.gf)
	self:add(state.gf, true)

	self.viewbarrier = Sprite(552, -34); self.viewbarrier:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'line'))
	self.viewbarrier.antialiasing = true
	self.viewbarrier:updateHitbox()
	self:add(self.viewbarrier, true)

	self.viewbarrier:addAnimByPrefix("idle", "viewbarrier instance 1", 24, true)
	self.viewbarrier:play("idle", true)

	close()
end