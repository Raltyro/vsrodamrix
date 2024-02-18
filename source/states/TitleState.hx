package states;

import openfl.Assets;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;

import states.MainMenuState;

import shaders.ColorSwap;
import shaders.WiggleEffect;

class TitleState extends MusicBeatState {
	public static var closedState:Bool = false;
	public static var initialized:Bool = false;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var curWacky:Array<String> = [];

	override public function create() {
		Paths.clearStoredMemory();

		Mods.pushGlobalMods();
		Mods.loadTopMod();

		FlxTransitionableState.skipNextTransOut = true;
		FlxG.mouse.visible = false;

		super.create();

		if (FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else {
			if (initialized) startIntro();
			else {
				curWacky = FlxG.random.getObject(getIntroTextShit());
				new FlxTimer().start(1, (tmr:FlxTimer) -> startIntro());
			}
		}
	}

	var skippedIntro:Bool = false;

	var bg:FlxSprite;
	var blob:FlxSprite;
	var borderTop:FlxSprite;
	var borderBottom:FlxSprite;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;
	var swagShader:ColorSwap;
	var wiggleShader:WiggleEffect;

	function startIntro() {
		FlxG.camera.bgColor = 0xFF00000;
		Conductor.bpm = 105;
		persistentUpdate = true;

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
		blob.y += 30;

		borderTop = new FlxSprite(0, -FlxG.height).makeGraphic(1, 1, 0xFF000000);
		borderTop.antialiasing = antialiasing;
		borderTop.scale.set(FlxG.width, FlxG.height + 120);
		borderTop.updateHitbox();

		borderBottom = new FlxSprite(0, FlxG.height - 119).makeGraphic(1, 1, 0xFF000000);
		borderBottom.antialiasing = antialiasing;
		borderBottom.scale.set(FlxG.width, 120);
		borderBottom.updateHitbox();

		logoBl = new FlxSprite();
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.antialiasing = antialiasing;
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		logoBl.screenCenter();
		logoBl.scrollFactor.set(1.2, 1.2);

		titleText = new FlxSprite(FlxG.width * .5 - 500, FlxG.height - 100);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
		titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		titleText.antialiasing = antialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();

		textGroup = new FlxGroup();
		add(textGroup);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.antialiasing = antialiasing;
		ngSpr.scale.set(0.8, 0.8);
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);

		if (ClientPrefs.data.shaders) {
			swagShader = new ColorSwap();
			wiggleShader = new WiggleEffect();
			wiggleShader.effectType = HEAT_WAVE_VERTICAL;
			wiggleShader.waveSpeed = 1.2;
			wiggleShader.waveFrequency = 30;
			wiggleShader.waveAmplitude = .02;

			logoBl.shader = swagShader.shader;
			blob.shader = wiggleShader.shader;
		}
		FlxTween.tween(logoBl, {y: logoBl.y-20}, 2, {ease: FlxEase.sineInOut, type: PINGPONG});

		if (initialized) customTransitionOut();
		else {
			if (FlxG.sound.music == null) CoolUtil.playMenuMusic();
			initialized = true;
			curStep = -1;
			updateMusicBeat();
		}
	}

	private function customTransitionIn(?_) {
		FlxTween.tween(FlxG.camera.scroll, {y: -FlxG.height}, 1, {ease: FlxEase.sineIn, onComplete: (_) -> {
			FlxTransitionableState.skipNextTransIn = true;
			var state = new MainMenuState();
			state.wasTitleState = true;

			MusicBeatState.switchState(state);
			FlxG.camera.bgColor = 0xFF00000;
		}});
	}

	private function customTransitionOut(?_) {
		FlxG.camera.scroll.y = -FlxG.height;
		FlxG.camera.bgColor = 0xFF004499;
		skippedIntro = true;

		add(bg);
		add(blob);
		add(borderTop);
		add(borderBottom);
		add(titleText);
		add(logoBl);
		remove(ngSpr);
		remove(textGroup);
		deleteCoolText();

		FlxTween.tween(FlxG.camera.scroll, {y: 0}, 0.7, {ease: FlxEase.quadOut});
	}

	var transitioning:Bool = false;
	var titleTimer:Float = 0;
	override function update(elapsed:Float) {
		if (initialized) Conductor.songPosition += elapsed * 1000;
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list) if (touch.justPressed) pressedEnter = true;
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null) {
			if (gamepad.justPressed.START) pressedEnter = true;
			#if switch
			if (gamepad.justPressed.B) pressedEnter = true;
			#end
		}

		titleTimer += FlxMath.bound(elapsed, 0, 1);
		if (titleTimer > 2) titleTimer -= 2;

		if (initialized && skippedIntro && !transitioning) {
			if (pressedEnter) {
				closedState = transitioning = true;

				titleText.animation.play('press');
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7).persist = true;

				new FlxTimer().start(0.2, customTransitionIn);
			}
			else {
				var timer:Float = titleTimer;
				if (timer >= 1) timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
		}
		if (initialized && pressedEnter && !skippedIntro) skipIntro();

		if (swagShader != null) {
			if (controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}
		if (wiggleShader != null) wiggleShader.update(elapsed);

		super.update(elapsed);
	}

	function getIntroTextShit():Array<Array<String>>
		return [for (i in Assets.getText(Paths.txt('introText')).split('\n')) i.split('--')];

	function createCoolText(textArray:Array<String>, ?offset:Float = 0) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, i * 60 + 200 + offset, textArray[i], true);
			money.screenCenter(X);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String, ?offset:Float = 0) {
		var money:Alphabet = new Alphabet(0, textGroup.length * 60 + 200 + offset, text, true);
		money.screenCenter(X);
		textGroup.add(money);
	}

	function deleteCoolText()
		while (textGroup.members.length > 0) textGroup.remove(textGroup.members[0], true);

	private var sickSteps:Int = 0;
	override function stepHit() {
		super.stepHit();
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		if (initialized && curStep % 4 == 0)
			logoBl.animation.play('bump', true);

		if (skippedIntro || closedState) return;
		while (sickSteps < curStep) nextStep();
	}

	private function nextStep() {
		switch (++sickSteps) {
			case 1: addMoreText('Rodabeanz team', -40);
			case 6:
				addMoreText('Qski', 14);
				addMoreText('The Rainbow Bubble', 14);
				addMoreText('N3okto', 14);
			case 8: addMoreText('and more!', 14);
			case 16: deleteCoolText();
			case 20: addMoreText('Not associated', -40);
			case 22: addMoreText('with', -40);
			case 24:
				addMoreText('newgrounds', -40);
				add(ngSpr);
			case 32:
				deleteCoolText();
				remove(ngSpr);
			case 36: addMoreText(curWacky[0]);
			case 40: addMoreText(curWacky[1]);
			case 48: deleteCoolText();
			case 52: addMoreText('FNF');
			case 56: addMoreText('Vs');
			case 60: addMoreText('RODAMRIX');
			case 64: skipIntro();
		}
	}

	function skipIntro() {
		if (skippedIntro) return;
		FlxG.camera.flash(FlxColor.WHITE, 3);
		FlxG.camera.bgColor = 0xFF004499;
		skippedIntro = true;

		add(bg);
		add(blob);
		add(borderTop);
		add(borderBottom);
		add(titleText);
		add(logoBl);
		remove(ngSpr);
		remove(textGroup);
		deleteCoolText();
	}

	// Deprecated, for backward compatibility for luas
	@:haxe.warning("-WDeprecated") public static var muteKeys(get, set):Array<FlxKey>;
	@:haxe.warning("-WDeprecated") public static var volumeDownKeys(get, set):Array<FlxKey>;
	@:haxe.warning("-WDeprecated") public static var volumeUpKeys(get, set):Array<FlxKey>;

	static function get_muteKeys():Array<FlxKey> return Main.muteKeys;
	static function set_muteKeys(v:Array<FlxKey>):Array<FlxKey> return Main.muteKeys = v;
	static function get_volumeDownKeys():Array<FlxKey> return Main.volumeDownKeys;
	static function set_volumeDownKeys(v:Array<FlxKey>):Array<FlxKey> return Main.volumeDownKeys = v;
	static function get_volumeUpKeys():Array<FlxKey> return Main.volumeUpKeys;
	static function set_volumeUpKeys(v:Array<FlxKey>):Array<FlxKey> return Main.volumeUpKeys = v;
}