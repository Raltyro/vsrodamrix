function create()
	self.camZoom = 0.85
	self.ratingPos = {x = 1200, y = 150}

	self.boyfriendPos = {x = 1274, y = -168}
	self.gfPos = {x = 488, y = -223}
	self.dadPos = {x = 209, y = -153}

	self.boyfriendCam = {x = -120, y = -130}
	self.gfCam = {x = 184, y = 90}
	self.dadCam = {x = 166, y = -50}

	self.bg = Sprite(-293, -361, paths.getImage("stages/double-attack-bg"))
	self.bg:setScrollFactor(0.97, 0.97)
	self.bg:updateHitbox()
	self:add(self.bg)
end

function postCreate()
	state.gf:setScrollFactor(0.98, 0.98)
	close()
end