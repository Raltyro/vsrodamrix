package backend;

import backend.Song;
import backend.Section;

typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	var id:Int; // is calculated in mapBPMChanges()
	@:optional var stepCrochet:Float;
}

class Conductor {
	public static var bpm(default, set):Float = 100;
	static function set_bpm(newBPM:Float):Float {
		crochet = calculateCrotchet(bpm = newBPM);
		stepCrochet = crochet / 4;
		return newBPM;
	}

	public static var crochet:Float = calculateCrotchet(bpm); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;
	public static var lastSongPos:Float;

	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var usePlayState:Bool = false;

	public function new() {}

	inline public static function calculateCrotchet(bpm:Float):Float
		return (60 / bpm) * 1000;

	static var _i:Int;
	public static function judgeNote(arr:Array<Rating>, diff:Float = 0):Rating {
		var end = arr.length - 1;

		_i = -1;
		while (++_i < end) if (diff <= arr[_i].hitWindow) return arr[_i];
		return arr[end];
	}

	public static function getDummyBPMChange():BPMChangeEvent {
		var bpm = (usePlayState && PlayState.SONG != null) ? PlayState.SONG.bpm : bpm;
		return {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: calculateCrotchet(bpm) / 4,
			id: -1
		};
	}

	private static function sortBPMChangeMap():Void {
		bpmChangeMap.sort((v1, v2) -> (v1.songTime > v2.songTime ? 1 : -1));

		_i = -1;
		while (++_i < bpmChangeMap.length) bpmChangeMap[_i].id = _i;
	}

	static var _lastChange:BPMChangeEvent;
	public static function getBPMFromIndex(index:Int):BPMChangeEvent {
		_lastChange = bpmChangeMap[index];
		if (_lastChange == null) return getDummyBPMChange();
		if (_lastChange.id == index) return _lastChange;

		sortBPMChangeMap(); _lastChange = bpmChangeMap[index];
		return _lastChange == null ? getDummyBPMChange() : _lastChange;
	}

	// This looks like shit but it works whatever
	public static function getBPMFromTime(time:Float, from:Int = -1):BPMChangeEvent {
		if (bpmChangeMap.length == 0 || time < bpmChangeMap[0].songTime) return getDummyBPMChange();
		else if (time >= bpmChangeMap[bpmChangeMap.length - 1].songTime) return bpmChangeMap[bpmChangeMap.length - 1];

		var _lastChange = getBPMFromIndex(from);
		var reverse = _lastChange.songTime > time;
		from = _lastChange.id;

		_i = from < 0 ? (reverse ? bpmChangeMap.length : -1) : from;
		var v:BPMChangeEvent;
		while (reverse ? --_i >= 0 : ++_i < bpmChangeMap.length) {
			if ((v = bpmChangeMap[_i]).id != _i) {
				sortBPMChangeMap();
				return getBPMFromTime(time);
			}
			if (reverse ? v.songTime <= time : v.songTime > time) break;
			_lastChange = v;
		}
		return _lastChange;
	}

	public static function getBPMFromStep(step:Float, from:Int = -1):BPMChangeEvent {
		if (bpmChangeMap.length == 0 || step < bpmChangeMap[0].stepTime) return getDummyBPMChange();
		else if (step >= bpmChangeMap[bpmChangeMap.length - 1].stepTime) return bpmChangeMap[bpmChangeMap.length - 1];

		var _lastChange = getBPMFromIndex(from);
		var reverse = _lastChange.stepTime > step;
		from = _lastChange.id;

		_i = from < 0 ? (reverse ? bpmChangeMap.length : -1) : from;
		var v:BPMChangeEvent;
		while (reverse ? --_i >= 0 : ++_i < bpmChangeMap.length) {
			if ((v = bpmChangeMap[_i]).id != _i) {
				sortBPMChangeMap();
				return getBPMFromStep(step);
			}
			if (reverse ? v.stepTime <= step : v.stepTime > step) break;
			_lastChange = v;
		}
		return _lastChange;
	}

	@:noCompletion
	public static function getCrotchetAtTime(time:Float, ?from:Int):Float
		return getBPMFromTime(time, from).stepCrochet * 4;

	@:noCompletion
	public static function stepToTime(step:Float, ?offset:Float = 0, ?from:Int):Float {
		_lastChange = getBPMFromStep(step, from);
		return _lastChange.songTime + (step - _lastChange.stepTime - offset) * _lastChange.stepCrochet;
	}

	@:noCompletion
	public static function beatToTime(beat:Float, ?offset:Float, ?from:Int):Float
		return inline stepToTime(beat * 4, offset, from);

	@:noCompletion
	public static function getStep(time:Float, ?offset:Float = 0, ?from:Int):Float {
		_lastChange = getBPMFromTime(time, from);
		return _lastChange.stepTime + (time - _lastChange.songTime - offset) / _lastChange.stepCrochet;
	}

	@:noCompletion
	public static function getStepRounded(time:Float, ?offset:Float, ?from:Int):Int
		return Math.floor(inline getStep(time, offset, from));

	@:noCompletion
	public static function getBeat(time:Float, ?offset:Float = 0, ?from:Int):Float
		return (inline getStep(time, offset, from)) / 4;

	@:noCompletion
	public static function getBeatRounded(time:Float, ?offset:Float, ?from:Int):Int
		return Math.floor(inline getBeat(time, offset, from));

	public static function mapBPMChanges(?song:SwagSong, reuse:Bool = #if MODS_ALLOWED false #else true #end) {
		if (reuse) bpmChangeMap.resize(0);
		else bpmChangeMap = [];

		if (song == null) return;

		var state:MusicBeatState = MusicBeatState.getState();
		if (state != null) state.curBPMChange = null;

		var curBPM:Float = song.bpm;
		var totalPos:Float = 0, totalSteps:Int = 0, total:Int = 0;

		var deltaSteps:Int, v;
		for (i in 0...song.notes.length) {
			v = song.notes[i];

			if (v.changeBPM && v.bpm != curBPM) {
				curBPM = v.bpm;
				bpmChangeMap.push({
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrotchet(curBPM) / 4,
					id: total++
				});
			}

			totalSteps += (deltaSteps = Math.floor(getSectionBeats(song, i) * 4));
			totalPos += (calculateCrotchet(curBPM) / 4) * deltaSteps;
		}

		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	@:noCompletion
	public static function getSectionBeats(song:SwagSong, section:Int):Float {
		var v:Null<Float> = (song == null || song.notes[section] == null) ? null : song.notes[section].sectionBeats;
		return (v == null) ? 4 : v;
	}
}
