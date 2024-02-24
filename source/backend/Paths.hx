package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;

import lime.utils.Assets;

import tjson.TJSON as Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#end

@:allow(Main)
class Paths {
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var dumpExclusions:Array<Dynamic> = [];
	public static var keyExclusions:Array<String> = [
		'music/ambience.$SOUND_EXT',
		'music/colorSplash.$SOUND_EXT'
	];

	public static function excludeAsset(asset:Dynamic) {
		if ((asset is String)) {
			var key:String = asset;
			for (v in keyExclusions) if (key.endsWith(v)) return;
			keyExclusions.push(key);
			return;
		}
		if (!dumpExclusions.contains(asset)) dumpExclusions.push(asset);
	}

	public static function unexcludeAsset(asset:Dynamic) {
		if ((asset is String)) {
			var key:String = asset;
			for (v in keyExclusions) if (key.endsWith(v)) keyExclusions.remove(v);
			return;
		}
		dumpExclusions.remove(asset);
	}

	public static function assetExcluded(asset:Dynamic):Bool {
		if ((asset is String)) {
			var key:String = asset;
			for (v in keyExclusions) if (key.endsWith(v)) return true;
			return false;
		}
		for (v in dumpExclusions) if (v == asset) return true;
		return false;
	}

	@:noCompletion inline private static function _gc() {
		#if cpp Gc.run(true);
		#elseif hl Gc.major(); #end
	}

	@:noCompletion inline public static function compress() {
		#if cpp Gc.run(true); Gc.compact();
		#elseif hl Gc.major(); #end
	}

	inline public static function gc(repeat:Int = 1) {
		while (repeat-- > 0) _gc();
	}

	private static var assetCompressTrack:Int = 0;
	@:noCompletion private static function stepAssetCompress():Void {
		assetCompressTrack++;
		if (assetCompressTrack > 6) {
			assetCompressTrack = 0;
			gc();
		}
	}

	public static function decacheGraphic(key:String) @:privateAccess {
		var obj = currentTrackedAssets.get(key);

		if (assetExcluded(obj)) return;
		currentTrackedAssets.remove(key);

		if (obj == null) return;
		FlxG.bitmap._cache.remove(key);
		OpenFlAssets.cache.removeBitmapData(key);
		OpenFlAssets.cache.clear(key);

		var bitmap = obj.bitmap;
		if (bitmap != null) {
			if (bitmap.__texture != null) bitmap.__texture.dispose();
			if (bitmap.image != null && bitmap.image.data != null) bitmap.image.data = null;
			bitmap.image = null;
			bitmap.disposeImage();
			bitmap.dispose();
			bitmap.unlock();
		}

		obj.persist = false; // make sure the garbage collector actually clears it up
		obj.destroyOnNoUse = true;
		obj.destroy();
	}

	public static function decacheSound(key:String) @:privateAccess {
		var obj = currentTrackedSounds.get(key);
		currentTrackedSounds.remove(key);

		if (obj == null && OpenFlAssets.cache.hasSound(key)) obj = OpenFlAssets.cache.getSound(key);
		if (obj == null || assetExcluded(obj)) return;

		OpenFlAssets.cache.removeSound(key);
		OpenFlAssets.cache.clear(key);
		Assets.cache.clear(key);

		if (obj.__buffer != null) {
			obj.__buffer.dispose();
			obj.__buffer = null;
		}
		obj = null;
	}

	public static function clearUnusedMemory() {
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !assetExcluded(key))
				decacheGraphic(key);
		}

		compress();
	}

	public static function clearStoredMemory() {
		for (key in @:privateAccess FlxG.bitmap._cache.keys()) {
			if (key != null && !currentTrackedAssets.exists(key) && !assetExcluded(key))
				decacheGraphic(key);
		}

		for (key in currentTrackedSounds.keys()) {
			if (key != null && !localTrackedAssets.contains(key) && !assetExcluded(key))
				decacheSound(key);
		}

		localTrackedAssets = [];
		#if !html5 OpenFlAssets.cache.clear("songs"); #end
		gc();
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:String, ?modsAllowed:Bool = false):String {
		#if MODS_ALLOWED
		if (modsAllowed) {
			var modded:String = modFolders(library != null ? '$library/$file' : file);
			if (FileSystem.exists(modded)) return modded;
		}
		#end

		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath:String = '';
			if (currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, 'week_assets', currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}
		}

		return getSharedPath(file);
	}

	static public function getLibraryPath(file:String, library = "shared")
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String, ?level:String) {
		if (level == null) level = library;
		return '$library:assets/$level/$file';
	}

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	inline static public function shaderFragment(key:String, ?library:String)
		return getPath('shaders/$key.frag', TEXT, library);

	inline static public function shaderVertex(key:String, ?library:String)
		return getPath('shaders/$key.vert', TEXT, library);

	inline static public function lua(key:String, ?library:String)
		return getPath('$key.lua', TEXT, library);

	inline static public function formatToSongPath(path:String):String {
		var invalidChars = ~/[~&\\;:<>#]+/g;
		var hideChars = ~/[.,'"%?!]+/g;

		var path:String = invalidChars.split(path.replace(' ', '-')).join('-');
		return hideChars.split(path).join('').toLowerCase();
	}

	#if (!MODS_ALLOWED) inline #end static public function video(key:String) {
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	#if (!MODS_ALLOWED) inline #end static public function sound(key:String, ?library:String):Sound
		return returnSound('sounds', key, library, false);

	#if (!MODS_ALLOWED) inline #end static public function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
		return sound(key + FlxG.random.int(min, max), library);

	#if (!MODS_ALLOWED) inline #end static public function music(key:String, ?library:String, stream:Bool = true):Sound {
		return returnSound('music', key, library,
			stream//stream != null ? stream : (!MusicBeatState.inState(PlayState) || ClientPrefs.data.streamMusic)
		);
	}

	#if (!MODS_ALLOWED) inline #end static public function inst(song:String, stream:Bool = true):Sound
		return returnSound(null, '${formatToSongPath(song)}/Inst', 'songs', stream);

	#if (!MODS_ALLOWED) inline #end static public function voices(song:String, ?postfix:String, stream:Bool = true):Sound {
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postfix != null) songKey += '-' + postfix;
		return returnSound(null, songKey, 'songs', stream);
	}

	#if (!MODS_ALLOWED) inline #end static public function voicesSuffix(song:String, suffix:String, stream:Bool = true):Sound
		return returnSound(null, '${formatToSongPath(song)}/Voices-${suffix}', 'songs', stream);

	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false):String {
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getSharedPath(key)))
			return File.getContent(getSharedPath(key));

		if (currentLevel != null) {
			var levelPath:String = '';
			if (currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, 'week_assets', currentLevel);
				if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
			}
		}
		#end

		var path:String = getPath(key, TEXT);
		if (#if sys FileSystem.exists(path) || #end OpenFlAssets.exists(path, TEXT)) return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String):String {
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if (FileSystem.exists(file)) return file;
		#end
		return 'assets/fonts/$key';
	}

	#if (!MODS_ALLOWED) inline #end public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String, ?onlyMods:Bool = false):Bool {
		#if MODS_ALLOWED
		if (!ignoreMods) {
			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key'))) return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;
		}
		#end

		return !onlyMods && (
			#if sys
			FileSystem.exists(getPath(key, type, false)) ||
			#end
			OpenFlAssets.exists(getPath(key, type, library, false), type)
			);
	}

	// less optimized but automatic handling
	public static function getAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, library, true);
		if (OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, library, true);
			if (OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, library, allowGPU);
	}

	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		#if MODS_ALLOWED
		var xmlExists:Bool = false;
		var xml:String = modsXml(key);
		if (FileSystem.exists(xml) || FileSystem.exists(xml = getPath('images/$key.xml', library))) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(image(key, library, allowGPU), (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library, allowGPU), getPath('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		var txt:String = modsTxt(key);
		if (FileSystem.exists(txt) || FileSystem.exists(txt = getPath('images/$key.txt', library))) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, allowGPU), (txtExists ? File.getContent(txt) : getPath('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, allowGPU), getPath('images/$key.txt', library));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if (FileSystem.exists(json) || FileSystem.exists(json = getPath('images/$key.json', library))) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath('images/$key.json', library)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath('images/$key.json', library));
		#end
	}

	public static function image(key:String, ?library:String, ?allowGPU:Bool = true):FlxGraphic {
		var modExists:Bool = true, file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file)) {
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (!FileSystem.exists(file))
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			modExists = false;
			if (currentTrackedAssets.exists(file)) {
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (#if sys !FileSystem.exists(file) && #end !OpenFlAssets.exists(file, IMAGE)) {
				trace('no such image $file exists');
				return null;
			}
		}

		#if sys
		var bitmap = OpenFlAssets.getBitmapData(file, false, allowGPU && ClientPrefs.data.cacheOnGPU);
		if (bitmap != null) {
			stepAssetCompress();
			return cacheBitmap(file, bitmap, false);
		}
		#end

		var bitmap = _getBitmap(file, modExists);
		if (bitmap != null) return cacheBitmap(file, bitmap, allowGPU);

		trace('oh no its returning null NOOOO ($file)');
		return null;
	}

	public static function cacheBitmap(file:String, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic {
		if (bitmap == null) if ((bitmap = getBitmap(file, true)) == null) return null;
		bitmap = OpenFlAssets.registerBitmapData(bitmap, file, false, allowGPU && ClientPrefs.data.cacheOnGPU);

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(file, graph);
		localTrackedAssets.push(file);
		return graph;
	}

	private static function _getBitmap(path:String, sys:Bool):BitmapData {
		stepAssetCompress();
		if (!sys) return OpenFlAssets.getRawBitmapData(path);
		#if sys else return BitmapData.fromFile(path); #end
	}

	public static function getBitmap(path:String, sys:Bool = true):BitmapData {
		#if sys if (FileSystem.exists(path)) return _getBitmap(path, true); #end
		if (OpenFlAssets.exists(path, IMAGE)) return _getBitmap(path, false);
		return null;
	}

	public static function returnSound(path:Null<String>, key:String, ?library:String, stream:Bool = false) {
		var modExists:Bool = false;

		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null) modLibPath = '$library/';
		if (path != null) modLibPath += '$path';
		var file:String = modsSounds(modLibPath, key);
		if (!(modExists = FileSystem.exists(file)))
		#else
		var file:String;
		#end
		{
			file = (path != null ? '$path/' : '') + '$key.$SOUND_EXT';
			file = getPath(file, SOUND, library);
		}
		var track:String = file.substr(file.indexOf(':') + 1);

		if (#if MODS_ALLOWED modExists || #end #if sys FileSystem.exists(track) || #end OpenFlAssets.exists(file, SOUND)) {
			var sound:Sound = currentTrackedSounds.get(track);
			localTrackedAssets.push(track);

			// if no stream and sound is stream, fuck it, load one that arent stream
			stream = stream && ClientPrefs.data.streamMusic;
			@:privateAccess if (!stream && sound != null && sound.__buffer != null && sound.__buffer.__srcVorbisFile != null) {
				decacheSound(track);
				sound = null;
			}
			if (sound == null)
				currentTrackedSounds.set(track, sound = _regSound(#if MODS_ALLOWED track #else file #end, stream, #if MODS_ALLOWED true #else false #end));

			if (sound != null) return sound;
		}

		trace('oh no its returning "sound" null NOOOO: $file');
		return null;
	}

	private static function _regSound(key:String, stream:Bool, sys:Bool):Sound {
		stepAssetCompress();
		return OpenFlAssets.getRawSound(key, false/*stream*/, sys);
	}

	public static function regSound(key:String, stream:Bool = false):Sound {
		#if sys if (FileSystem.exists(key)) return _regSound(key, stream, true); #end
		if (OpenFlAssets.exists(key, SOUND)) return _regSound(key, stream, false);
		return null;
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsFont(key:String)
		return modFolders('fonts/' + key);

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String) {
		var file;
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			file = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(file)) return file;
		}

		for (mod in Mods.getGlobalMods()) {
			file = mods(mod + '/' + key);
			if (FileSystem.exists(file)) return file;
		}
		return mods(key);
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(?spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if (spriteJson != null) {
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if (animationJson != null)  {
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if (Std.isOfType(folderOrImg, String)) {
			var originalPath:String = folderOrImg;
			for (i in 0...10) {
				var st:String = '$i';
				if (i == 0) st = '';

				if (!changedAtlasJson) {
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if (spriteJson != null) {
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = Paths.image('$originalPath/spritemap$st');
						break;
					}
				}
				else if (Paths.fileExists('images/$originalPath/spritemap$st.png', IMAGE)) {
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = Paths.image('$originalPath/spritemap$st');
					break;
				}
			}

			if (!changedImage) {
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = Paths.image(originalPath);
			}

			if (!changedAnimJson) {
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		if (spr != null) spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}