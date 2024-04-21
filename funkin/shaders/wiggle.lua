local WiggleEffect = Classic:extend("WiggleEffect")
WiggleEffect.code = [[
	uniform int effectType; uniform float uTime;
	uniform float uSpeed; uniform float uFrequency; uniform float uWaveAmplitude;

	#define EFFECT_TYPE_DREAMY 0
	#define EFFECT_TYPE_WAVY 1
	#define EFFECT_TYPE_HEAT_WAVE_HORIZONTAL 2
	#define EFFECT_TYPE_HEAT_WAVE_VERTICAL 3
	#define EFFECT_TYPE_FLAG 4

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
		vec2 pt = texture_coords;
		float x = 0.;
		float y = 0.;

		if (effectType == EFFECT_TYPE_DREAMY)  {
			float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
			pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
		}
		else if (effectType == EFFECT_TYPE_WAVY)  {
			float offsetY = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
			pt.y += offsetY; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
		}
		else if (effectType == EFFECT_TYPE_HEAT_WAVE_HORIZONTAL) {
			x = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
		}
		else if (effectType == EFFECT_TYPE_HEAT_WAVE_VERTICAL) {
			y = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
		}
		else if (effectType == EFFECT_TYPE_FLAG) {
			y = sin(pt.y * uFrequency + 10.0 * pt.x + uTime * uSpeed) * uWaveAmplitude;
			x = sin(pt.x * uFrequency + 5.0 * pt.y + uTime * uSpeed) * uWaveAmplitude;
		}

		return Texel(texture, vec2(pt.x + x, pt.y + y)) * color;
	}
]]

WiggleEffect.DREAMY = 0
WiggleEffect.WAVY = 1
WiggleEffect.HEAT_WAVE_HORIZONTAL = 2
WiggleEffect.HEAT_WAVE_VERTICAL = 3
WiggleEffect.FLAG = 4

function WiggleEffect:new(effectType, waveSpeed, waveFrequency, waveAmplitude)
	self.shader = love.graphics.newShader(WiggleEffect.code)

	self:setType(effectType or WiggleEffect.DREAMY)
	self:set(waveSpeed or 0, waveFrequency or 0, waveAmplitude or 0, 0)
end

function WiggleEffect:update(dt)
	self:setTime(self.time + dt)
end

function WiggleEffect:setType(effectType) self.shader:send("effectType", effectType); self.type = effectType end
function WiggleEffect:setSpeed(waveSpeed) self.shader:send("uSpeed", waveSpeed); self.speed = waveSpeed end
function WiggleEffect:setFrequency(waveFrequency) self.shader:send("uFrequency", waveFrequency); self.frequency = waveFrequency end
function WiggleEffect:setAmplitude(waveAmplitude) self.shader:send("uAmplitude", waveAmplitude); self.amplitude = waveAmplitude end
function WiggleEffect:setTime(time) self.shader:send("uTime", time); self.time = time end

function WiggleEffect:set(waveSpeed, waveFrequency, waveAmplitude, time)
	if waveSpeed then self.shader:send("uSpeed", waveSpeed); self.speed = waveSpeed end
	if waveFrequency then self.shader:send("uFrequency", waveFrequency); self.frequency = waveFrequency end
	if waveAmplitude then self.shader:send("uWaveAmplitude", waveAmplitude); self.amplitude = waveAmplitude end
	if time then self.shader:send("uTime", time); self.time = time end
end

function WiggleEffect:destroy()
	if self.shader then self.shader:release() end
	self.shader = nil
end

return WiggleEffect