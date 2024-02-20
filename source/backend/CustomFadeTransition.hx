package backend;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;

	public var duration:Float;
	public var isTransIn:Bool;
	public var scale:Float = 0;
	public var finished:Bool = false;

	var leTween:FlxTween;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	public function new(duration:Float = 0.7, isTransIn:Bool = false) {
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();

		transGradient = new FlxSprite().loadGraphic(getGradient());
		transGradient.scrollFactor.set();
		transGradient.flipY = isTransIn;
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		add(transBlack);

		updateHitbox();
	}

	override function create() {
		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		super.create();

		leTween = FlxTween.tween(this, {scale: 1}, duration, {
			onComplete: onComplete,
			ease: FlxEase.linear
		});
	}

	private function onComplete(_) {
		if (!finished && !isTransIn && finishCallback != null) finishCallback();
		finished = true;

		if (isTransIn) close();
	}

	private function updateHitbox() {
		var camera:FlxCamera = camera != null ? camera : FlxG.camera;
		var width = FlxG.width, height = FlxG.height;
		var scaleX:Float = 1, scaleY:Float = 1;

		if (camera != null) {
			width = camera.width;
			height = camera.height;
			scaleX = camera.scaleX;
			scaleY = camera.scaleY;
		}

		var gradWidth = Math.ceil(width / scaleX), gradHeight = Math.ceil(height / scaleY);

		transGradient.setGraphicSize(gradWidth, gradHeight);
		transGradient.updateHitbox();
		transGradient.y = FlxMath.remapToRange(scale, 0, 1, -gradHeight, gradHeight) -gradHeight + height;

		transBlack.setGraphicSize(gradWidth, gradHeight);
		transBlack.updateHitbox();
		transBlack.y = transGradient.y + (isTransIn ? gradHeight : -gradHeight);

		transGradient.x = transBlack.x = -gradWidth + width;
	}

	override function update(elapsed:Float) {
		updateHitbox();
		super.update(elapsed);
	}

	override function destroy() {
		if (leTween != null) leTween.cancel();
		finished = true;
		super.destroy();
	}

	private static var cachedGradient:FlxGraphic;
	private static function getGradient():FlxGraphic {
		@:privateAccess
		if (cachedGradient != null && cachedGradient.frameCollections != null) return cachedGradient;

		final key = "FadeTransitionGradient";
		var bitmap = openfl.utils.Assets.registerBitmapData(FlxGradient.createGradientBitmapData(1, 1024, [FlxColor.BLACK, 0x0]), key, false, true);
		(cachedGradient = FlxGraphic.fromBitmapData(bitmap, false, key)).persist = true;
		cachedGradient.destroyOnNoUse = false;

		Paths.excludeAsset(key);
		return cachedGradient;
	}
}