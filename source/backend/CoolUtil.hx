package backend;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class CoolUtil {
	inline public static function getSavePath(folder:String = '', prefix:String = 'ZelRakker/VsRodamrix'):String
		return folder != '' ? '$prefix/$folder' : prefix;

	inline public static function quantize(f:Float, snap:Float):Float { // changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String):String
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String> {
		#if sys
		if (FileSystem.exists(path)) return listFromString(File.getContent(path.substr(path.indexOf(':') + 1)));
		#else
		if (Assets.exists(path)) return listFromString(Assets.getText(path));
		#end
		return [];
	}

	inline public static function colorFromString(color:String):FlxColor {
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function listFromString(string:String):Array<String> {
		var daList:Array<String> = string.split('\n');
		for (i in 0...daList.length) daList[i] = daList[i].trim();

		return daList;
	}

	inline public static function floorDecimal(value:Float, decimals:Int):Float
		return truncateFloat(value, decimals);

	public static function truncateFloat(value:Float, decimals:Int = 2, round:Bool = false):Float {
		var p = Math.pow(10, decimals);
		return (round ? Math.round : Math.floor)(decimals > 0 ? p * value : value) / (decimals > 0 ? p : 1);
	}
	
	inline public static function dominantColor(sprite:flixel.FlxSprite):Int {
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel != 0){
					if(countByColor.exists(colorOfThisPixel)){
						countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
					}
					else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function numberArray(max:Int, min:Int = 0):Array<Int> {
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	public static function setTextBorderFromString(text:FlxText, border:String) {
		switch(border.toLowerCase().trim()) {
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	inline public static function flKeyToFlx(keyCode:Int):FlxKey
		@:privateAccess return FlxKey.toStringMap.get(keyCode);

	inline public static function playMenuMusic() {
		if (FlxG.sound.music == null) FlxG.sound.playMusic(Paths.music('colorSplash'), 0.9);
		FlxG.sound.music.loopTime = 182857.14285714;
		FlxG.sound.music.endTime = 368000;
	}
}