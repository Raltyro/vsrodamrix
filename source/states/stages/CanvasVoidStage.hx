package states.stages;

import openfl.display.BitmapData;

import flixel.addons.display.FlxParallaxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;

class CanvasVoidStage extends BaseStage {
	var shader:CanvasVoidPerspectiveShader;

	static var floorRoofKey:String = "CanvasVoidFloorRoof";
	inline function makeFloorRoofGraph():FlxGraphic {
		if (Paths.currentTrackedAssets.exists(floorRoofKey)) return Paths.currentTrackedAssets.get(floorRoofKey);

		var bitmap = new BitmapData(2000, 512, true, 0), gfx = FlxSpriteUtil.flashGfx, step = 200;
		bitmap.lock();

		gfx.clear();
		for (i in 1...Std.int(2000 / step)) {
			var x = i * step;
			gfx.lineStyle(8, 0x9BB8D4);
			gfx.moveTo(x, 0);
			gfx.lineTo(x, 799);
			gfx.endFill();
		}
		bitmap.draw(FlxSpriteUtil.flashGfxSprite);

		bitmap.unlock();
		return Paths.cacheBitmap("CanvasVoidFloorRoof", bitmap, true);
	}

	static var gradientKey:String = "CanvasVoidGradient";
	inline function makeGradientFloorRoof():FlxGraphic {
		if (Paths.currentTrackedAssets.exists(gradientKey)) return Paths.currentTrackedAssets.get(gradientKey);

		var bitmap = FlxGradient.createGradientBitmapData(1024, 1, [0xFFB8D6E6, FlxColor.WHITE, 0xFFB8D6E6], 1, 0);
		return Paths.cacheBitmap(gradientKey, bitmap, true);
	}

	override function create() {
		var gradientGraph = makeGradientFloorRoof();
		var floorRoofGraph = makeFloorRoofGraph();

		var floor = new FlxSprite(0, 480, floorRoofGraph);
		floor.scale.set(1.2, 1.2);
		floor.updateHitbox();
		floor.screenCenter(X);
		floor.scrollFactor.set(.82, .82);

		var floorgrad = new FlxSprite(0, 480, gradientGraph);
		floorgrad.setGraphicSize(floor.width, 1024);
		floorgrad.updateHitbox();
		floorgrad.screenCenter(X);
		floorgrad.scrollFactor.set(.82, .82);

		add(floorgrad);
		add(floor);

		var door = new BGSprite("doorte", -230, -15, .7, .7);
		add(door);

		var se = new BGSprite("selecttool", 400, -34, .56, .56);
		add(se);

		var fill = new BGSprite("filltool", 1265, -15, .6, .6);
		add(fill);

		var pick = new BGSprite("pickertool", 1123, 233, .5, .5);
		add(pick);

		if (ClientPrefs.data.shaders) shader = new CanvasVoidPerspectiveShader();
	}

	override function createPost() {
		camGame.bgColor = 0xFFF5FFFF;
		if (shader != null) camGame.filters = [new openfl.filters.ShaderFilter(shader)];

		gf.scrollFactor.set(.82, .82);

		var pick = new BGSprite("rubbertool", 362, 730, 1.4, 1.4);
		pick.scale.set(1.1, 1.1);
		add(pick);

		camGame.zoom -= .06;
	}
}

class CanvasVoidPerspectiveShader extends flixel.system.FlxAssets.FlxShader {
	@:glFragmentSource('
		#pragma header

		vec2 coord = openfl_TextureCoordv;
		#define PI 3.1415926538
		#define PI2 1.5707963267948966

		float fakesin(float v) {
		    v /= PI;
		    v = 2.0 * fract(v / 2.0);
		    return v <= 1.0 ? -4.0 * v * (v - 1.0) : 4.0 * (v - 1.0) * (v - 2.0);
		}

		void main() {
			coord.xy -= .5;
			coord.xy *= vec2(fakesin(coord.y + PI2) / 2. + .5, fakesin(coord.x + PI2) / 2. + .5);

			gl_FragColor = flixel_texture2D(bitmap, coord + vec2(.5));
			for (float i = 0.; i < 4; i++) { 
				coord.xy *= vec2(fakesin(coord.y + PI2) / 20. + .95, fakesin(coord.x + PI2) / 20. + .95);
				vec4 tex = flixel_texture2D(bitmap, coord + vec2(.5));

				gl_FragColor += vec4(tex.rgb * vec3(1, -i / 20. + 1.05, i / 10. + .9), tex.a);
			}

			gl_FragColor /= 5.;
		}')

	public function new() {super();}
}