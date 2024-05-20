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

local function makeTiles(tex, angle, size, y, x, z, x2, z2)
	for x = x, x + x2 * size, size do
		for z = z, z + z2 * size, size do
			local tile = ActorSprite(x, y, z, tex)
			tile:setGraphicSize(size, size)
			Note.updateHitbox(tile)
			tile.rotation.x, tile.rotation.y = 90, angle

			self:add(tile)
			table.insert(self.tiles, tile)
		end
	end
end

function create()
	game.camera.bgColor = {245 / 255, 1, 1}
	--game.camera.bgColor = {.2, .2, .2}
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

	self.floor = Sprite(0, 0, paths.getImage(SCRIPT_PATH .. "floorgrad"))
	self.floor:setScrollFactor(0, 0)
	self.floor.antialiasing = true
	self.floor.alpha = .7
	self:add(self.floor)

	self.tiles = {}
	local texTile = paths.getImage(SCRIPT_PATH .. "floortiles")
	--local texTile = "silly.png"--paths.getImage("characters/ralt-gf")
	makeTiles(texTile, 0, 4096, 725, -6000, 1200, 3, 2); makeTiles(texTile, 90, 4096, 725, -6000, 1200, 3, 2)
	makeTiles(texTile, 0, 4096, -600, -6000, 2300, 3, 2); makeTiles(texTile, 90, 4096, -600, -6000, 2300, 3, 2)

	self.grad1 = Sprite(-1700, 330, paths.getImage(SCRIPT_PATH .. "grad"))
	self.grad1:setScrollFactor(0, 0.2)
	self.grad1:setGraphicSize(4000, 500)
	self.grad1:updateHitbox()
	--self.grad1.blend = "add"
	self.grad1.antialiasing = true
	self:add(self.grad1)

	self.grad2 = Sprite(-1700, 330 - 500, paths.getImage(SCRIPT_PATH .. "grad"))
	self.grad2:setScrollFactor(0, 0.2)
	self.grad2:setGraphicSize(4000, 500)
	self.grad2:updateHitbox()
	self.grad2.antialiasing = true
	self.grad2.flipY = true
	--self.grad2.blend = "add"
	self:add(self.grad2)

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

function draw()
	self.floor:setGraphicSize(game.width / game.camera.__zoom.x, game.height / game.camera.__zoom.y)
	self.floor:updateHitbox(); self.floor:screenCenter()
end

function leave()
	if shader then
		game.camera.shader = nil
		shader:release()
	end
	close()
end