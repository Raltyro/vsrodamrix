package states;

import lime.app.Application;

import flixel.addons.transition.FlxTransitionableState;
import states.editors.MasterEditorMenu;
import flixel.effects.FlxFlicker;
import flixel.FlxObject;

import options.OptionsState;
import shaders.WiggleEffect;

class MainMenuState extends MusicBeatState {
	public static var psychEngineVersion:String = '0.7.3';
	public static var curSelected:Int = 0;
	static var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'options',
		'credits'
	];

	public var wasTitleState:Bool = false;

	override function create() {
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;
		make();

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.setFormat(Paths.font("continum.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		psychVer.scrollFactor.set();
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "FNF Vs Rodamrix v" + Application.current.meta.get('version'), 12);
		fnfVer.setFormat(Paths.font("continum.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.scrollFactor.set();
		add(fnfVer);

		add(borderTransition);

		#if ACHIEVEMENTS_ALLOWED // Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		if (wasTitleState) FlxTransitionableState.skipNextTransOut = true;
		super.create();
		FlxG.camera.bgColor = 0xFF004499;
		if (wasTitleState) fromTitleState();

		changeItem();
		updateMenuItems(true);
		imageItems.x = -curSelected * FlxG.width;
	}

	var bg:FlxSprite;
	var blob:FlxSprite;
	var border:FlxSprite;
	var wiggleShader:WiggleEffect;
	var borderTransition:FlxSprite;

	var menuItems:FlxSpriteGroup;
	var imageItems:FlxSpriteGroup;
	var arrowLeft:FlxSprite;
	var arrowRight:FlxSprite;
	var arrowWidth:Int;

	function make() {
		var antialiasing = ClientPrefs.data.antialiasing;

		bg = new FlxBackdrop(Paths.image('mainmenu/checker'));
		bg.antialiasing = antialiasing;
		bg.velocity.set(50, 50);
		bg.scrollFactor.set(.4, .4);

		blob = new FlxSprite(Paths.image('mainmenu/MainMenuBackBlob'));
		blob.antialiasing = antialiasing;
	    blob.scrollFactor.set(0, .1);
	    blob.screenCenter();
		blob.alpha = 0.5;
		blob.y += 70;

		border = new FlxSprite(0, FlxG.height - 199).makeGraphic(1, 1, 0xFF000000);
		border.antialiasing = antialiasing;
		border.scrollFactor.set(0, 1);
		border.scale.set(FlxG.width, 250);
		border.updateHitbox();
		border.alpha = .6;

		borderTransition = new FlxSprite(0, FlxG.height + 50).makeGraphic(1, 1, 0xFF000000);
		borderTransition.antialiasing = antialiasing;
		borderTransition.scrollFactor.set(0, 1.2);
		borderTransition.scale.set(FlxG.width, FlxG.height);
		borderTransition.updateHitbox();

		var arrowAtlas = Paths.getSparrowAtlas('mainmenu/arrows');
		var arrowY = Std.int(border.y + (200 - (185 * .8)) / 2);

		arrowLeft = new FlxSprite(0, arrowY);
		arrowLeft.antialiasing = antialiasing;
		arrowLeft.frames = arrowAtlas;
		arrowLeft.animation.addByPrefix('idle', 'ArrowIdle', 12, true, false);
		arrowLeft.animation.addByPrefix('pressed', 'ArrowPressed', 12, true, false);
		arrowLeft.animation.play('idle');
		arrowLeft.scale.set(.8, .8);
		arrowLeft.updateHitbox();
		arrowLeft.screenCenter(X);
		arrowLeft.scrollFactor.set(0.5, 0.5);
		arrowWidth = Std.int(arrowLeft.width);

		arrowRight = new FlxSprite(0, arrowY);
		arrowRight.antialiasing = antialiasing;
		arrowRight.frames = arrowAtlas;
		arrowRight.animation.addByPrefix('idle', 'ArrowIdle', 12, true, false);
		arrowRight.animation.addByPrefix('pressed', 'ArrowPressed', 12, true, false);
		arrowRight.animation.play('idle');
		arrowRight.scale.set(.8, .8);
		arrowRight.updateHitbox();
		arrowRight.screenCenter(X);
		arrowRight.scrollFactor.set(0.5, 0.5);
		arrowRight.flipX = true;

		menuItems = new FlxSpriteGroup();
		imageItems = new FlxSpriteGroup();

		var imageAtlas = Paths.getSparrowAtlas('mainmenu/MenuImages');
		var length = optionShit.length;
		for (i in 0...length) { //for (i in (-2)...(length + 2)) {
			var shit = optionShit[i];//optionShit[i < 0 ? length + i : i % length];
			var image = new FlxSprite(Std.int((i + 0.5) * FlxG.width));
			image.antialiasing = antialiasing;
			image.frames = imageAtlas;
			image.animation.addByPrefix('idle', shit, 0);
			image.animation.play('idle');
			image.updateHitbox();
			image.x -= Std.int(image.width / 2);
			image.y = Std.int((FlxG.height - 200 - image.height) / 2);
			imageItems.add(image);

			//if (i >= 0 && i < length) {
				var menu = new FlxSprite();
				menu.antialiasing = antialiasing;
				menu.frames = Paths.getSparrowAtlas('mainmenu/menu_$shit');
				menu.animation.addByPrefix('idle', '$shit basic', 12);
				menu.animation.addByPrefix('selected', '$shit white', 12);
				menu.animation.play('idle');
				menu.scale.set(.8, .8);
				menu.updateHitbox();
				menu.y = Std.int(border.y + (200 - menu.height) / 2);

				menuItems.add(menu);
			//}
		}

		imageItems.scrollFactor.set(0.5, 0.5);
		menuItems.scrollFactor.set(0.5, 0.5);

		add(bg);
		add(blob);
		add(imageItems);
		add(border);
		add(menuItems);
		add(arrowLeft);
		add(arrowRight);

		if (ClientPrefs.data.shaders) {
			wiggleShader = new WiggleEffect();
			wiggleShader.effectType = HEAT_WAVE_VERTICAL;
			wiggleShader.waveSpeed = 1.2;
			wiggleShader.waveFrequency = 30;
			wiggleShader.waveAmplitude = .02;

			blob.shader = wiggleShader.shader;
		}
	}

	private function fromTitleState(?_) {
		FlxG.camera.scroll.y = FlxG.height - 200;
		border.alpha = 1;

		FlxTween.tween(FlxG.camera.scroll, {y: 0}, 0.57, {ease: FlxEase.quadOut});
		FlxTween.tween(border, {alpha: 0.6}, 0.57);
	}

	private function toTitleState(?_) {
		FlxTween.tween(FlxG.camera.scroll, {y: FlxG.height - 200}, 0.7, {ease: FlxEase.sineIn, onComplete: (_) -> {
			FlxTransitionableState.skipNextTransIn = true;
			MusicBeatState.switchState(new TitleState());
		}});
		FlxTween.tween(border, {alpha: 1}, 0.7);
	}

	override function destroy() {
		FlxG.camera.bgColor = 0xFF000000;
		super.destroy();
	}

	var selectedSomethin:Bool = false;
	override function update(elapsed:Float) {
		var music = FlxG.sound.music;
		if (music != null && music.volume < 0.8) {
			music.volume = Math.min(music.volume + (0.5 * elapsed), 0.8);
			if (FreeplayState.vocals != null) FreeplayState.vocals.volume = music.volume;
		}

		if (wiggleShader != null) wiggleShader.update(elapsed);
		if (!selectedSomethin) {
			if (controls.UI_LEFT_P || controls.UI_UP_P) {
				arrowLeft.animation.play('pressed');
				arrowLeft.updateHitbox();
				changeItem(-1);
			}
			else if (controls.UI_LEFT_R || controls.UI_UP_R) {
				arrowLeft.animation.play('idle');
				arrowLeft.updateHitbox();
				arrowLeft.screenCenter(X);
				arrowLeft.x -= Std.int((menuItems.members[curSelected].width + arrowLeft.width) / 2 + 8);
			}

			if (controls.UI_RIGHT_P || controls.UI_DOWN_P) {
				arrowRight.animation.play('pressed');
				arrowRight.updateHitbox();
				changeItem(1);
			}
			else if (controls.UI_RIGHT_R || controls.UI_DOWN_R) {
				arrowRight.animation.play('idle');
				arrowRight.updateHitbox();
				arrowRight.screenCenter(X);
				arrowRight.x += Std.int((menuItems.members[curSelected].width + arrowRight.width) / 2 + 8);
			}

			if (controls.BACK) {
				selectedSomethin = true;
				toTitleState();
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.7).persist = true;
			}
			else if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7).persist = true;
				FlxFlicker.flicker(menuItems.members[curSelected], 0.3, 0.06, true, false, (?_) -> selectSomethin(curSelected));
				for (i in 0...menuItems.length) {
					if (i == curSelected) continue;
					FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
				}
			}
			#if desktop
			else if (controls.justPressed('debug_1')) {
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		imageItems.x = FlxMath.lerp(-curSelected * FlxG.width, imageItems.x, Math.exp(-elapsed * 9));
		updateMenuItems(elapsed);

		super.update(elapsed);
	}

	function selectSomethin(select:Int) {
		switch (optionShit[select]) {
			case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay': MusicBeatState.switchState(new FreeplayState());
			#if ACHIEVEMENTS_ALLOWED
			case 'awards': MusicBeatState.switchState(new AchievementsMenuState());
			#end
			case 'credits': MusicBeatState.switchState(new CreditsState());
			case 'options':
				MusicBeatState.switchState(new OptionsState());
				OptionsState.onPlayState = false;
				if (PlayState.SONG != null) {
					PlayState.SONG.arrowSkin = null;
					PlayState.SONG.splashSkin = null;
					PlayState.stageUI = 'normal';
				}
		}
	}

	function updateMenuItems(?force:Bool = false, elapsed:Float = 0) {
		var lerp = force ? 0 : Math.exp(-elapsed * 9);

		var firstMenu = menuItems.members[curSelected], firstX = (FlxG.width - firstMenu.width) / 2;
		firstMenu.x = FlxMath.lerp(firstX, firstMenu.x, lerp);
		if (!selectedSomethin) firstMenu.alpha = 1;

		var x = firstX - arrowWidth - 16, i = curSelected, total = 0, menu;
		while (--i >= total) {
			menu = menuItems.members[i];
			if (!selectedSomethin) menu.alpha = 1 - (Math.abs(curSelected - i) / 4);
			menu.x = FlxMath.lerp(x -= menu.width, menu.x, lerp);
			x -= 4;
		}

		x = firstX + firstMenu.width + arrowWidth + 16;
		i = curSelected;
		total = menuItems.length;
		while (++i < total) {
			menu = menuItems.members[i];
			if (!selectedSomethin) menu.alpha = 1 - (Math.abs(curSelected - i) / 4);
			menu.x = FlxMath.lerp(x, menu.x, lerp);
			x += menu.width + 4;
		}
	}

	function changeItem(huh:Int = 0) {
		var length = optionShit.length, prev = curSelected, sound = Paths.sound('cancelMenu');

		curSelected += huh;
		if (curSelected >= length) {
			curSelected = length - 1;
			updateMenuItems(true);
			menuItems.x -= 30;
		}
		else if (curSelected < 0) {
			curSelected = 0;
			updateMenuItems(true);
			menuItems.x += 30;
		}
		else sound = Paths.sound('scrollMenu');
		FlxG.sound.play(sound, 0.7);

		if (prev != curSelected) {
			var menu = menuItems.members[prev];
			menu.animation.play('idle');
			menu.updateHitbox();
			menu.y = Std.int(border.y + (200 - menu.height) / 2);
		}

		/*
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
		if (curSelected >= length) {
			curSelected = 1;
			updateMenuItems(true);
			curSelected--;
			imageItems.x += length * FlxG.width;
		}
		else if (curSelected < 0) {
			curSelected = length - 2;
			updateMenuItems(true);
			curSelected++;
			imageItems.x -= length * FlxG.width;
		}*/

		var menu = menuItems.members[curSelected];
		menu.animation.play('selected');
		menu.updateHitbox();
		menu.y = Std.int(border.y + (200 - menu.height) / 2);

		arrowLeft.screenCenter(X);
		arrowLeft.x -= Std.int((menu.width + arrowLeft.width) / 2 + 8);
		arrowLeft.color = curSelected > 0 ? 0xFFFFFF : 0x808080;

		arrowRight.screenCenter(X);
		arrowRight.x += Std.int((menu.width + arrowRight.width) / 2 + 8);
		arrowRight.color = curSelected < length - 1 ? 0xFFFFFF : 0x808080;
	}
}