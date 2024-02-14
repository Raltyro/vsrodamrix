package backend;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import backend.PsychCamera;

class MusicBeatState extends FlxUIState {
	public static var timePassedOnState:Float = 0;
	public static var camBeat:FlxCamera;

	public var stages:Array<BaseStage> = [];
	public var controls(get, never):Controls;
	function get_controls() return Controls.instance;

	private static var lastStateClass:Class<FlxState>;
	private var stateClass:Class<MusicBeatState>;
	private var isPlayState:Bool;

	public var curBPMChange:BPMChangeEvent;

	private var passedSections:Array<Float> = [];
	private var stepsOnSection:Float = 0;
	private var stepsToDo:Float = 0;

	private var curDecSection:Float = 0;
	private var curSection:Int = 0;
	private var lastDecSection:Float = 0;
	private var lastSection:Int = 0;

	private var curDecStep:Float = 0;
	private var curStep:Int = 0;
	private var lastDecStep:Float = 0;
	private var lastStep:Int = 0;

	private var curDecBeat:Float = 0;
	private var curBeat:Int = 0;
	private var lastDecBeat:Float = 0;
	private var lastBeat:Int = 0;

	var _psychCameraInitialized:Bool = false;

	public function new() {
		isPlayState = (stateClass = Type.getClass(this)) == PlayState;
		curBPMChange = Conductor.getDummyBPMChange();
		super();
	}

	override function create() {
		if (curBPMChange != null && curBPMChange.bpm != Conductor.bpm) curBPMChange = Conductor.getDummyBPMChange();
		var skip = FlxTransitionableState.skipNextTransOut;
		camBeat = FlxG.camera;

		if(!_psychCameraInitialized) initPsychCamera();
		super.create();

		if (!skip) openSubState(new CustomFadeTransition(0.6, true));
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera {
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	override function destroy() {
		lastStateClass = cast stateClass;
		persistentUpdate = false;
		passedSections = null;
		Paths.compress();

		super.destroy();
	}

	var updatedMusicBeat:Bool = false;
	public function updateMusicBeat() {
		lastDecSection = curDecSection;
		lastSection = curSection;

		lastDecStep = curDecStep;
		lastStep = curStep;

		lastDecBeat = curDecBeat;
		lastBeat = curBeat;

		updateCurStep();
		updateBeat();

		if (lastStep != curStep) {
			if (curStep > 0 || !isPlayState) stepHit();
			if (passedSections == null) passedSections = [];
			if (curStep > lastStep)
				updateSection();
			else
				rollbackSection();
		}

		updatedMusicBeat = true;
	}

	override function update(elapsed:Float) {
		timePassedOnState += elapsed;

		if (!updatedMusicBeat) updateMusicBeat();
		updatedMusicBeat = false;

		ClientPrefs.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection(?dontHit:Bool = false):Void {
		if (stepsToDo <= 0) {
			curSection = 0;
			stepsToDo = stepsOnSection = getBeatsOnSection() * 4;
			passedSections.resize(0);
		}

		while (curStep >= stepsToDo) {
			passedSections.push(stepsToDo);

			curDecSection = curSection = passedSections.length;
			stepsOnSection = getBeatsOnSection() * 4;

			stepsToDo = stepsToDo + stepsOnSection;
			if (!dontHit) sectionHit();
		}

		curDecSection = curSection + (curDecStep - passedSections[curSection - 1]) / stepsOnSection;
	}

	private function rollbackSection():Void {
		if (curStep <= 0) {
			stepsToDo = 0;
			updateSection();
			if (curBeat < 1 && curSection != lastSection) sectionHit();
			return;
		}

		lastSection = curSection;
		while ((curSection = passedSections.length) > 0 && curStep < passedSections[curSection - 1])
			stepsToDo = passedSections.pop();

		if (curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void {
		curDecBeat = curDecStep / 4;
		curBeat = Math.floor(curDecBeat);
	}

	private function updateCurStep():Void {
		curBPMChange = Conductor.getBPMFromTime(Conductor.songPosition, curBPMChange != null ? curBPMChange.id : -1);
		curDecStep = Conductor.getStep(Conductor.songPosition, ClientPrefs.data.noteOffset, curBPMChange.id);
		curStep = Math.floor(curDecStep);
	}

	public function getBeatsOnSection():Float
		return inline Conductor.getSectionBeats(PlayState.SONG, curSection);

	public static function switchState(?nextState:FlxState):Bool {
		if (!Reflect.field(FlxG.state, 'switchTo')(nextState)) return false;
		if (FlxTransitionableState.skipNextTransIn) _switchState(nextState);
		else startTransition(nextState);
		return true;
	}

	public static function resetState()
		switchState(null);

	// Custom made Trans in
	public static function startTransition(nextState:FlxState) {
		if (nextState == null || inState(Type.getClass(nextState)))
			nextState = Type.createInstance(Type.getClass(FlxG.state), []);

		if (FlxG.state == null) return _switchState(nextState);
		CustomFadeTransition.finishCallback = () -> _switchState(nextState);
		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
	}

	@:noCompletion
	private static function _switchState(nextState:FlxState) {
		FlxTransitionableState.skipNextTransIn = false;
		CustomFadeTransition.finishCallback = null;

		@:privateAccess FlxG.game._requestedState = nextState;
	}

	public static function getState(?state:FlxState):MusicBeatState
		return cast(state != null ? state : FlxG.state);

	public static function isState(state1:FlxState, state2:Class<FlxState>):Bool
		return Std.isOfType(state1, state2);

	public static function inState(state:Class<FlxState>):Bool
		return inline isState(FlxG.state, state);

	public function stepHit():Void {
		stagesFunc(stageStepHit);

		if (curStep % 4 == 0) beatHit();
	}

	private function stageStepHit(stage:BaseStage):Void {
		stage.curStep = curStep;
		stage.curDecStep = curDecStep;
		stage.stepHit();
	}

	public function beatHit():Void
		stagesFunc(stageBeatHit);

	private function stageBeatHit(stage:BaseStage):Void {
		stage.curBeat = curBeat;
		stage.curDecBeat = curDecBeat;
		stage.beatHit();
	}

	public function sectionHit():Void
		stagesFunc(stageSectionHit);

	private function stageSectionHit(stage:BaseStage):Void {
		stage.curSection = curSection;
		stage.sectionHit();
	}

	function stagesFunc(func:BaseStage->Void) {
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}
}