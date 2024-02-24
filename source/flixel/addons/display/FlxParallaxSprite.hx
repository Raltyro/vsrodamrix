package flixel.addons.display;

import flixel.FlxStrip;

class FlxParallaxSprite extends FlxStrip {
	/*public var
	self.offsetBack = {x = 0, y = 0}
	self.offsetFront = {x = 0, y = 0}

	self.scrollFactorBack = {x = 1, y = 1}
	self.scrollFactorFront = {x = 1, y = 1}

	self.scaleBack = 1
	self.scaleFront = 1
	*/

	@:noCompletion
	override function initVars():Void {
		super.initVars();
	}

	// TODO
	override public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		return super.getScreenBounds(newRect, camera);
	}
}