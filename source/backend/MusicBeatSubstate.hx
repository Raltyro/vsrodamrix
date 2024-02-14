package backend;

import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState {
	public var controls(get, never):Controls;
	function get_controls() return Controls.instance;

	private static var lastSubstateClass:Class<FlxSubState>;
	private var substateClass:Class<MusicBeatSubstate>;

	private var curBPMChange:BPMChangeEvent;

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

	public function new() {
		substateClass = Type.getClass(this);
		curBPMChange = Conductor.getDummyBPMChange();
		super();
	}

	override function create() {
		if (curBPMChange != null && curBPMChange.bpm != Conductor.bpm) curBPMChange = Conductor.getDummyBPMChange();

		super.create();
	}

	override function destroy() {
		lastSubstateClass = cast substateClass;
		passedSections = null;

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
			if (curStep > 0) stepHit();
			if (passedSections == null) passedSections = [];
			if (curStep > lastStep)
				updateSection();
			else
				rollbackSection();
		}

		updatedMusicBeat = true;
	}

	override function update(elapsed:Float) {
		if (!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;

		if (!updatedMusicBeat) updateMusicBeat();
		updatedMusicBeat = false;

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

	public function stepHit():Void
		if (curStep % 4 == 0) beatHit();

	public function beatHit():Void {}
	
	public function sectionHit():Void {}
}