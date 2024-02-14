package;

import lime.app.Application;

import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.display.FPS;
import openfl.events.KeyboardEvent;
import openfl.events.Event;
import openfl.Lib;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxGame;

import backend.ClientPrefs;
import debug.FPSCounter;
import states.TitleState;

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

#if linux
import lime.graphics.Image;

@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite {
	var game = {
		width: 1280, height: 720,
		initialState: TitleState,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var args:Array<String>;

	public static var current:Main;
	public static var fpsVar:FPSCounter;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var fullscreenKeys:Array<FlxKey> = [FlxKey.F11];
	public static var screenshotKeys:Array<FlxKey> = [FlxKey.PRINTSCREEN];
	public static var focused:Bool = true;

	public static function changeFramerate(framerate:Float):Void {
		var _framerate:Int = Std.int(framerate);
		if (_framerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = _framerate;
			FlxG.drawFramerate = _framerate;
		}
		else {
			FlxG.drawFramerate = _framerate;
			FlxG.updateFramerate = _framerate;
		}
	}

	public static function main():Void {
		args = Sys.args();
		Lib.current.addChild(current = new Main());
	}
	
	// FlxG.stage Prevention
	public function new() {
		super();

		if (stage != null) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void {
		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKey);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		FlxG.signals.postGameReset.add(onGameReset);
		FlxG.signals.focusGained.add(onFocus);
		FlxG.signals.focusLost.add(onFocusLost);

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		fpsVar = new FPSCounter(3, 3, 0xFFFFFF);
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") 1, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		addChild(fpsVar);

		//ScreenShotPlugin.screenshotKeys = screenshotKeys;
		//FlxG.plugins.add(new ScreenShotPlugin());

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null) resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null) resetSpriteCache(FlxG.game);
		});
	}

	inline static function resetSpriteCache(sprite:Sprite):Void @:privateAccess {
		sprite.__cacheBitmap = null;
		sprite.__cacheBitmapData = null;
	}

	private function handleKey(evt:KeyboardEvent) {
		if (fullscreenKeys.contains(CoolUtil.flKeyToFlx(evt.keyCode))) FlxG.fullscreen = !FlxG.fullscreen;
	}

	private function onGameReset() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		ClientPrefs.loadPrefs();
		backend.Highscore.load();

		if (FlxG.save.data != null) {
			if (FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if (FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 8;
		FlxG.keys.preventDefaultKeys = [TAB];

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
	}

	private function onFocus() {
		focused = true;
		Paths.gc();
	}

	private function onFocusLost() {
		focused = false;
		Paths.gc(4);
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void {
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		//errMsg += "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";
		errMsg += "\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/")) FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}