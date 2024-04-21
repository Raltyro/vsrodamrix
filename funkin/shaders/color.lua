local ColorShader = {cache = {}}
ColorShader.code = [[
	uniform float h; uniform float s; uniform float b;

	vec3 rgb2hsv(vec3 c) {
		const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
		vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

		float d = q.x - min(q.w, q.y);
		float e = 1.0e-10;
		return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}

	vec3 hsv2rgb(vec3 c) {
		vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
	}

	vec4 effect(vec4 adjcolor, Image texture, vec2 texture_coords, vec2 screen_coords) {
		vec4 color = Texel(texture, texture_coords);
		color = vec4(rgb2hsv(color.rgb), color.a);
		color.x += h;
		color.y += s;
		color.z *= 1. + b;

		if (color.y < 0.) color.y = 0.;
		else if (color.y > 1.) color.y = 1.;

		return vec4(hsv2rgb(vec3(color.x, color.y, color.z)), color.a) * adjcolor;
	}
]]

function ColorShader.set(shader, h, s, b)
	if h then shader:send("h", h) end
	if s then shader:send("s", s) end
	if b then shader:send("b", b) end
	return shader
end

function ColorShader.getKey(h, s, b)
	return
		table.concat(h) .. "_" ..
		table.concat(s) .. "_" ..
		table.concat(b)
end

function ColorShader.create(h, s, b, unique)
	if h == true then return ColorShader.set(love.graphics.newShader(ColorShader.code), 0, 0, 0) end
	h, s, b = h or 0, s or 0, b or 0

	local key = ColorShader.getKey(h, s, b)
	local shader = ColorShader.cache[key]
	if shader == nil or unique then
		shader = ColorShader.set(love.graphics.newShader(ColorShader.code), h, s, b)
		if not unique then ColorShader.cache[key] = shader end
	end

	return shader
end

function ColorShader.reset()
	for key, shader in pairs(ColorShader.cache) do
		shader:release()
		ColorShader.cache[key] = nil
	end
end

return ColorShader
