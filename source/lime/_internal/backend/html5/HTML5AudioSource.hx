package lime._internal.backend.html5;

import lime.math.Vector4;
import lime.media.AudioSource;

@:access(lime.media.AudioBuffer)
class HTML5AudioSource
{
	private var completed:Bool;
	private var gain:Float;
	private var id:Int;
	private var length:Null<Float>;
	private var loops:Int;
	private var loopTime:Null<Float>;
	private var parent:AudioSource;
	private var playing:Bool;
	private var position:Vector4;

	public function new(parent:AudioSource)
	{
		this.parent = parent;

		id = -1;
		gain = 1;
		position = new Vector4();
	}

	public function dispose():Void {
		stop();
		if (parent != null && parent.buffer != null && parent.buffer.__references != null)
			parent.buffer.__references.remove(parent);
	}

	public function init():Void {
		parent.buffer.initBuffer();
		parent.buffer.__references.push(parent);
	}

	public function play():Void
	{
		#if lime_howlerjs
		if (playing || parent.buffer == null || parent.buffer.__srcHowl == null)
		{
			return;
		}

		playing = true;

		var time = getCurrentTime();

		completed = false;

		var cacheVolume = untyped parent.buffer.__srcHowl._volume;
		untyped parent.buffer.__srcHowl._volume = parent.gain;

		id = parent.buffer.__srcHowl.play();

		untyped parent.buffer.__srcHowl._volume = cacheVolume;
		// setGain (parent.gain);

		setPosition(parent.position);

		parent.buffer.__srcHowl.on("end", howl_onEnd, id);

		// Calling setCurrentTime causes html5 audio to replay from this position on next frame
		#if force_html5_audio
		if (time == 0) setCurrentTime(time);
		#else
		setCurrentTime(time);
		#end
		#end
	}

	public function pause():Void
	{
		#if lime_howlerjs
		playing = false;

		if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			parent.buffer.__srcHowl.pause(id);
		}
		#end
	}

	public function stop():Void
	{
		#if lime_howlerjs
		playing = false;

		if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			parent.buffer.__srcHowl.stop(id);
			parent.buffer.__srcHowl.off("end", howl_onEnd, id);
		}
		#end
	}

	// Event Handlers
	private function howl_onEnd()
	{
		#if lime_howlerjs
		playing = false;

		if (loops > 0)
		{
			loops--;
			stop();
			if (loopTime != null && loopTime > 0) setCurrentTime(loopTime);
			play();
			parent.onLoop.dispatch();
			return;
		}
		else if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			parent.buffer.__srcHowl.stop(id);
			parent.buffer.__srcHowl.off("end", howl_onEnd, id);
		}

		completed = true;
		parent.onComplete.dispatch();
		#end
	}

	// Get & Set Methods
	public function getCurrentTime():Float
	{
		if (id == -1)
		{
			return 0;
		}

		#if lime_howlerjs
		if (completed)
		{
			return getLength();
		}
		else if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			var time = (parent.buffer.__srcHowl.seek(id) * 1000) - parent.offset;
			if (time < 0) return 0;
			return time;
		}
		#end

		return 0;
	}

	public function setCurrentTime(value:Float):Float
	{
		#if lime_howlerjs
		if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			// if (playing) buffer.__srcHowl.play (id);
			var pos = (value + parent.offset) / 1000;
			if (pos < 0) pos = 0;
			parent.buffer.__srcHowl.seek(pos, id);
		}
		#end

		return value;
	}

	public function getGain():Float
	{
		return gain;
	}

	public function setGain(value:Float):Float
	{
		#if lime_howlerjs
		// set howler volume only if we have an active id.
		// Passing -1 might create issues in future play()'s.

		if (parent.buffer != null && parent.buffer.__srcHowl != null && id != -1)
		{
			parent.buffer.__srcHowl.volume(value, id);
		}
		#end

		return gain = value;
	}

	public function getLength():Float
	{
		if (length != 0)
		{
			return length;
		}

		#if lime_howlerjs
		if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			return parent.buffer.__srcHowl.duration() * 1000;
		}
		#end

		return 0;
	}

	public function setLength(value:Float):Float
	{
		return length = value;
	}

	public function getLoops():Int
	{
		return loops;
	}

	public function setLoops(value:Int):Int
	{
		return loops = value;
	}

	public function getLoopTime():Float {
		return loopTime;
	}

	public function setLoopTime(value:Float):Float {
		return loopTime = value;
	}

	public function getPitch():Float
	{
		#if lime_howlerjs
		if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			return parent.buffer.__srcHowl.rate();
		}
		#end
		
		return 1;
	}

	public function setPitch(value:Float):Float
	{
		#if lime_howlerjs
		if (parent.buffer != null && parent.buffer.__srcHowl != null)
		{
			parent.buffer.__srcHowl.rate(value);
		}
		else
			return 1;
		#end
		
		return getPitch();
	}
	

	public function getPosition():Vector4
	{
		#if lime_howlerjs
		// This should work, but it returns null (But checking the inside of the howl, the _pos is actually null... so ¯\_(ツ)_/¯)
		/*
			var arr = parent.buffer.__srcHowl.pos())
			position.x = arr[0];
			position.y = arr[1];
			position.z = arr[2];
		 */
		#end

		return position;
	}

	public function setPosition(value:Vector4):Vector4
	{
		position.x = value.x;
		position.y = value.y;
		position.z = value.z;
		position.w = value.w;

		#if lime_howlerjs
		if (parent.buffer != null && parent.buffer.__srcHowl != null && parent.buffer.__srcHowl.pos != null) parent.buffer.__srcHowl.pos(position.x, position.y, position.z, id);
		// There are more settings to the position of the sound on the "pannerAttr()" function of howler. Maybe somebody who understands sound should look into it?
		#end

		return position;
	}
}