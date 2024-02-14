package objects;

import backend.animation.PsychAnimationController;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.AssetType;
import openfl.utils.Assets;
import tjson.TJSON as Json;

import backend.Song;
import backend.Section;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false) {
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		switch (curCharacter) {
			//case 'your character name in case you want to hardcode them instead':

			default:
				var json:CharacterFile = getCharacterFile(character);
				if (json == null) { // If a character couldn't be found, change him to BF just to prevent a crash
					json = getCharacterFile(DEFAULT_CHARACTER);
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				try {
					loadCharacterFile(json);
				}
				catch(e:Dynamic) trace('Error loading character file of "$character": $e');
		}

		recalculateDanceIdle();
		dance();

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
	}

	public static function getCharacterFile(char:String):CharacterFile {
		var characterPath:String = 'characters/' + char + '.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) path = Paths.getSharedPath(characterPath);
		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!Assets.exists(path))
		#end
			return null;

		var rawJson = #if MODS_ALLOWED File.getContent #else Assets.getText #end(path);
		return cast Json.parse(rawJson);
	}

	public function loadCharacterFile(json:Dynamic) {
		scale.set(1, 1);
		updateHitbox();

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT, null, true);
		isAnimateAtlas = #if MODS_ALLOWED FileSystem.exists(animToFind); #else Assets.exists(animToFind); #end
		if (isAnimateAtlas) {
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try {
				Paths.loadAnimateAtlas(atlas, json.image);
			}
			catch(e:Dynamic) FlxG.log.warn('Could not load atlas ${json.image}: $e');
		}
		else
		#else
		isAnimateAtlas = false;
		#end
		frames = Paths.getAtlas(json.image);

		imageFile = json.image;
		jsonScale = json.scale;
		if (json.scale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;

				if (!isAnimateAtlas) {
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else {
					if (animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				if (anim.offsets != null && anim.offsets.length > 1) addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else addOffset(anim.anim, 0, 0);
			}
		}
		#if flxanimate
		if (isAnimateAtlas) copyAtlasValues();
		#end
		//trace('Loaded file to character ' + curCharacter);
	}

	public static function cacheCharacter(char:String, ?cacheIcon:Bool = true) {
		var json:CharacterFile = getCharacterFile(char);

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT, null, true);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) #else Assets.exists(animToFind) #end)
			Paths.loadAnimateAtlas(null, json.image);
		else
		#end
		Paths.getAtlas(json.image);

		if (cacheIcon) HealthIcon.getIcon(json.healthicon);
	}

	override function update(elapsed:Float) {
		if (debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && atlas.anim.curSymbol == null))
			return super.update(elapsed);

		if (isAnimateAtlas) atlas.update(elapsed);
		var rate:Float = PlayState.instance != null ? PlayState.instance.playbackRate : 1;

		if (heyTimer > 0) {
			heyTimer -= elapsed * rate;
			if (heyTimer <= 0) {
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer')) {
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished()) {
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished()) {
			dance();
			finishAnimation();
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if (isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 / rate) * singDuration) {
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && animOffsets.exists('$name-loop')) playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null);

	inline public function getAnimationName():String {
		if (isAnimationNull()) return '';
		@:privateAccess return #if flxanimate isAnimateAtlas ? atlas.anim.lastPlayedAnim : #end animation.curAnim.name;
	}

	public function isAnimationFinished():Bool {
		if (isAnimationNull()) return false;
		return #if flxanimate isAnimateAtlas ? atlas.anim.finished : #end animation.curAnim.finished;
	}

	public function finishAnimation():Void {
		if (isAnimationNull()) return;
		#if flxanimate
		if (isAnimateAtlas) atlas.anim.curFrame = atlas.anim.length - 1;
		else
		#end
			animation.curAnim.finish();
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool {
		if (isAnimationNull()) return false;
		return #if flxanimate isAnimateAtlas ? atlas.anim.isPlaying : #end animation.curAnim.paused;
	}
	private function set_animPaused(value:Bool):Bool {
		if (isAnimationNull()) return value;
		#if flxanimate
		if (isAnimateAtlas) {
			if (value) atlas.anim.pause();
			else atlas.anim.resume();
		}
		else
		#end
			animation.curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;
	public function dance() {
		if (debugMode || skipDance || specialAnim) return;

		// FOR GF DANCING SHIT
		if (danceIdle) {
			if (danced = !danced) playAnim('danceRight$idleSuffix');
			else playAnim('danceLeft$idleSuffix');
		}
		else if (animOffsets.exists('idle$idleSuffix'))
			playAnim('idle$idleSuffix');

	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		specialAnim = false;
		if (!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		else atlas.anim.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (daOffset != null) offset.set(daOffset[0], daOffset[1]);
		//else offset.set(0, 0);

		if (danceIdle) {
			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
			else if (AnimName.startsWith('sing'))
				danced = AnimName == 'singLEFT';
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	private var settingCharacterUp:Bool = true;
	public var danceEveryNumBeats:Int = 2;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft$idleSuffix') && animOffsets.exists('danceRight$idleSuffix'));

		if (settingCharacterUp) danceEveryNumBeats = danceIdle ? 1 : 2;
		else if (lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if (danceIdle) calc /= 2;
			else calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}

		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];

	public function quickAnimAdd(name:String, anim:String)
		animation.addByPrefix(name, anim, 24, false);

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;
	public override function draw() {
		if (isAnimateAtlas) {
			copyAtlasValues();
			atlas.draw();
			return;
		}
		super.draw();
	}

	public function copyAtlasValues() {
		@:privateAccess {
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy() {
		super.destroy();
		destroyAtlas();
	}

	public function destroyAtlas() {
		if (atlas != null)
			atlas = FlxDestroyUtil.destroy(atlas);
	}
	#end
}
