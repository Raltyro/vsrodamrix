local shader = [[
	#define PI 3.141592653589793
	#define PI2 1.5707963267948966

	float fakesin(float v) {
		v /= PI;
		v = 2.0 * fract(v / 2.0);
		return v <= 1.0 ? -4.0 * v * (v - 1.0) : 4.0 * (v - 1.0) * (v - 2.0);
	}

	vec4 effect(vec4 color, Image tex, vec2 coord, vec2 screen_coords) {
		coord.xy -= .5;
		coord.xy *= vec2(fakesin(coord.y + PI2) / 2. + .5, fakesin(coord.x + PI2) / 2. + .5);

		vec4 frag = Texel(tex, coord + vec2(.5));
		for (float i = 0.; i < 4; i++) { 
			coord.xy *= vec2(fakesin(coord.y + PI2) / 20. + .95, fakesin(coord.x + PI2) / 20. + .95);
			vec4 c = Texel(tex, coord + vec2(.5));

			frag += vec4(c.rgb * vec3(1, -i / 20. + 1.05, i / 10. + .9), c.a);
		}

		return frag / 5.;
	}
]]

function create()
	game.camera.bgColor = {245 / 255, 1, 1}
	if ClientPrefs.data.shader then
		shader = love.graphics.newShader(shader)
		game.camera.shader = shader
	else shader = nil
	end

	self.camZoom = .75

	self.boyfriendPos = {x = 979, y = -10}
	self.gfPos = {x = 420, y = 60}
	self.dadPos = {x = -106, y = -10}

	self.boyfriendCam = {x = -160, y = -50}
	self.gfCam = {x = 0, y = 0}
	self.dadCam = {x = 180, y = -50}

	self.floor = Sprite(-600, 456, paths.getImage(SCRIPT_PATH .. "floorgrad"))
	self.floor:setGraphicSize(game.width * 2, 400)
	self.floor:setScrollFactor(0, 0.3)
	self.floor:updateHitbox()
	self:add(self.floor)

	local tiles = paths.getImage(SCRIPT_PATH .. "floortiles")
	self.tiley = ActorSprite(580, 725, 0, tiles)
	self.tiley.scale.y, self.tiley.scale.x = 8000, 2
	self.tiley.rotation.x, self.tiley.rotation.y = 90, 90
	Note.updateHitbox(self.tiley)
	self:add(self.tiley)

	self.tilex = ActorSprite(580, 725, 512, tiles)
	self.tilex.scale.y, self.tilex.scale.x = 1024, 2
	self.tilex.rotation.x = 90
	Note.updateHitbox(self.tilex)
	self:add(self.tilex)

	self.door = Sprite(-180, -15, paths.getImage(SCRIPT_PATH .. "doorte"))
	self.door:setScrollFactor(.7, .7); self.door:updateHitbox()
	self:add(self.door)

	self.se = Sprite(430, -34, paths.getImage(SCRIPT_PATH .. "selecttool"))
	self.se:setScrollFactor(.56, .56); self.se:updateHitbox()
	self:add(self.se)

	self.fill = Sprite(1187, -15, paths.getImage(SCRIPT_PATH .. "filltool"))
	self.fill:setScrollFactor(.6, .6); self.se:updateHitbox()
	self:add(self.fill)

	self.pick = Sprite(1076, 233, paths.getImage(SCRIPT_PATH .. "pickertool"))
	self.pick:setScrollFactor(.5, .5); self.se:updateHitbox()
	self:add(self.pick)

	self.rub = Sprite(362, 730, paths.getImage(SCRIPT_PATH .. "rubbertool"))
	self.rub:setScrollFactor(1.5, 1.5);
	self.rub.scale.x, self.rub.scale.y = 1.1, 1.1; self.rub:updateHitbox()
	self.foreground:add(self.rub)

	self.floatyTime, self.floatyIncrement = 0, 0
	self.floaty = {}
	function self:putFloaty(...)
		for _, obj in ipairs({...}) do
			table.insert(self.floaty, obj)
			obj.ogX, obj.ogY, obj.ogAngle, obj.floaty = obj.x, obj.y, obj.angle, self.floatyIncrement
			self.floatyIncrement = self.floatyIncrement + 1
		end
	end

	function self:removeFloaty(...)
		for _, obj in ipairs({...}) do
			table.remove(self.floaty, obj)
			obj.x, obj.y, obj.angle = obj.ogX, obj.ogY, obj.ogAngle
		end
	end

	self:putFloaty(self.door, self.se, self.fill, self.pick, self.rub)
end

function postCreate()
	state.gf:setScrollFactor(0.82, 0.82)
end

function update(dt)
	local floatyTime = self.floatyTime + dt
	self.floatyTime = floatyTime

	for _, obj in ipairs(self.floaty) do
		local factor = obj.scrollFactor.x
		obj.x, obj.y, obj.angle =
			obj.ogX + (math.noise(floatyTime / 4, obj.floaty) + math.cos(obj.floaty + floatyTime / 3.2)) * factor * 6,
			obj.ogY + (math.noise(obj.floaty, floatyTime) / 2 + math.sin(obj.floaty + floatyTime * 1.4)) * factor * 43,
			obj.ogAngle + (math.noise(0, obj.floaty, floatyTime / 2) + math.cos(floatyTime / 2 - obj.floaty)) * 15
	end
end

function leave()
	if shader then
		game.camera.shader = nil
		shader:release()
	end
	close()
end