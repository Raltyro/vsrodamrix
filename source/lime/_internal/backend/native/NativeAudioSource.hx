// Thanks to RapperGF for letting me aware that it should queue buffer and
// unqueue them when finished playing instead or it'll stays in memory forever
// :33

package lime._internal.backend.native;

import haxe.Timer;
import haxe.Int64;

import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.vorbis.VorbisFile;

import lime.math.Vector4;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.utils.ArrayBufferView;

import sys.thread.Thread;
import sys.thread.Mutex;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.AudioBuffer)
@:access(lime.utils.ArrayBufferView)
@:access(lime.media.vorbis.VorbisFile)
class NativeAudioSource {
	private static final STREAM_BUFFER_SIZE:Int = 16384;
	private static final STREAM_NUM_BUFFERS:Int = 8;
	private static final STREAM_TIMER_FREQUENCY:Int = 100;

	private var buffers:Array<ALBuffer>;
	private var bufferDatas:Array<ArrayBufferView>;
	private var bufferTimeBlocks:Array<Float>;
	private var bufferLoops:Int;
	private var queuedBuffers:Int;
	private var requestBuffers:Int;

	private var length:Null<Float>;
	private var loopTime:Null<Float>;
	private var playing:Bool;
	private var loops:Int;
	private var position:Vector4;

	private var bitsPerSample:Int;
	private var format:Int;
	private var dataLength:Int64;
	private var samples:Int64;
	private var completed:Bool;
	private var stream:Bool;

	private var handle:ALSource;
	private var parent:AudioSource;
	private var timer:Timer;
	private var disposed:Bool;
	private var safeEnd:Bool;

	public function new(parent:AudioSource) {
		this.parent = parent;
		position = new Vector4();
	}

	public function dispose():Void {
		disposed = true;
		stop();

		if (parent != null && parent.buffer != null && parent.buffer.__references != null)
			parent.buffer.__references.remove(parent);

		if (handle != null) AL.deleteSource(handle);
		handle = null;

		if (buffers != null) AL.deleteBuffers(buffers);
		buffers = null;
	}

	public function init():Void {
		if (handle != null) return;

		var buffer = parent.buffer;
		buffer.initBuffer();
		buffer.__references.push(parent);

		disposed = (handle = AL.createSource()) == null;
		bitsPerSample = buffer.bitsPerSample;
		format = buffer.__format;
		bufferLoops = 0;

		var vorbisFile = buffer.__srcVorbisFile;
		if (stream = vorbisFile != null) {
			dataLength = (samples = vorbisFile.pcmTotal()) * buffer.channels * (Int64.ofInt(bitsPerSample) / 8);
			buffers = AL.genBuffers(STREAM_NUM_BUFFERS);
			bufferDatas = new Array();
			bufferTimeBlocks = new Array();

			var constructor = bitsPerSample == 8 ? Int8 : Int16;
			for (i in 0...STREAM_NUM_BUFFERS) {
				bufferDatas.push(new ArrayBufferView(STREAM_BUFFER_SIZE, constructor));
				bufferTimeBlocks.push(0);
			}
		}
		else
			samples = ((dataLength = AL.getBufferi(buffer.__srcBuffer, AL.SIZE)) * 8) / (buffer.channels * buffer.bitsPerSample);
	}

	public function play():Void {
		if (playing || disposed) return;

		playing = true;
		if (completed) setCurrentTime(0);
		else setCurrentTime(getCurrentTime());
	}

	public function pause():Void {
		if (!(disposed = handle == null)) AL.sourcePause(handle);

		playing = false;
		stopStreamTimer();
		stopTimer();
	}

	public function stop():Void {
		if (!(disposed = handle == null)) {
			if (AL.getSourcei(handle, AL.SOURCE_STATE) != AL.STOPPED) AL.sourceStop(handle);
			AL.sourceUnqueueBuffers(handle, AL.getSourcei(handle, AL.BUFFERS_QUEUED) + AL.getSourcei(handle, AL.BUFFERS_PROCESSED));
		}

		requestBuffers = queuedBuffers = bufferLoops = 0;
		playing = false;
		stopStreamTimer();
		stopTimer();
	}

	private function complete():Void {
		stop();

		completed = true;
		parent.onComplete.dispatch();
	}

	// Stream Handler
	private static var threadRunning:Bool = false;
	private static var streamSources:Array<NativeAudioSource> = [];
	private static var lengthStreamSources:Int = 0;
	private static var mutex:Mutex = new Mutex();

	private static function sourceStreamHandler():Void {
		var time = STREAM_TIMER_FREQUENCY / 1000, i = 0, n = 0;
		while (lengthStreamSources != 0) {
			i = -1;
			try {
				n = streamSources.length;
				while (++i < n) streamSources[i].streamRun();
			}
			catch (e) {
				trace('Streaming Error: $e');
				if (streamSources[i] != null) {
					mutex.acquire();
					streamSources[i].dispose();
					mutex.release();
				}
			}
			Sys.sleep(time);
		}
		threadRunning = false;
	}

	private function readVorbisFileBuffer(vorbisFile:VorbisFile, max:Int):ArrayBufferView {
		#if lime_vorbis
		var id = STREAM_NUM_BUFFERS - requestBuffers, read = STREAM_NUM_BUFFERS - 1, total = 0, readMax = 0;
		var buffer = bufferDatas[id];

		mutex.acquire();
		queuedBuffers = requestBuffers;
		for (i in id...read) {
			bufferTimeBlocks[i] = bufferTimeBlocks[i + 1];
			bufferDatas[i] = bufferDatas[i + 1];
		}
		bufferTimeBlocks[read] = vorbisFile.timeTell();
		bufferDatas[read] = buffer;

		while (total < STREAM_BUFFER_SIZE) {
			if ((readMax = 4096) > (read = max - total)) readMax = read;
			if (vorbisFile.handle == null) break;
			if (readMax > 0 && (read = vorbisFile.read(buffer.buffer, total, readMax)) > 0) total += read;
			else if (safeEnd = (loops > bufferLoops)) {
				if (readMax == 4096) continue;
				bufferLoops++; vorbisFile.timeSeek((loopTime != null ? Math.max(0, loopTime / 1000) : 0) + parent.offset / 1000);
				if ((max = (dataLength - (vorbisFile.pcmTell() * (Int64.ofInt(bitsPerSample) / 8) * parent.buffer.channels)).low) > STREAM_BUFFER_SIZE)
					max = STREAM_BUFFER_SIZE;
			}
			else {
				buffer.buffer.fill(total, STREAM_BUFFER_SIZE - total - 1, 0);
				resetTimer((getLength() - getCurrentTime()) / getPitch());
				break;
			}
		}
		mutex.release();
		return buffer;
		#else
		return null;
		#end
	}

	private function fillBuffers(buffers:Array<ALBuffer>):Void {
		#if lime_vorbis
		if (parent == null || parent.buffer == null) return dispose();
		if (handle == null || buffers.length < 1) return;

		var buffer = parent.buffer;
		var vorbisFile = buffer.__srcVorbisFile;
		var actualDataRate = (Int64.ofInt(bitsPerSample) / 8) * buffer.channels;
		var position = vorbisFile.pcmTell() * actualDataRate, length = getLengthSamples() * actualDataRate;
		if (position >= length && safeEnd) return;

		var sampleRate = buffer.sampleRate, numBuffers = 0, data, size:Int64;
		for (buffer in buffers) {
			if ((size = length - position) > STREAM_BUFFER_SIZE) size = Int64.ofInt(STREAM_BUFFER_SIZE);
			data = readVorbisFileBuffer(vorbisFile, Int64.toInt(size));

			if (disposed) return;
			AL.bufferData(buffer, format, data, STREAM_BUFFER_SIZE, sampleRate);
			numBuffers++;

			if (safeEnd) break;
			else if ((position += size) >= length && bufferLoops > 0) position = vorbisFile.pcmTell() * actualDataRate;
		}
		mutex.acquire();
		AL.sourceQueueBuffers(handle, numBuffers, buffers);

		if (playing && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.STOPPED) {
			AL.sourcePlay(handle);
			resetTimer(Std.int((getLength() - getCurrentTime()) / getPitch()));
		}
		mutex.release();
		#end
	}

	private function streamRun():Void {
		#if lime_vorbis
		if (disposed = (handle == null)) return dispose();

		var vorbisFile = parent.buffer.__srcVorbisFile;
		if (vorbisFile == null) return dispose();

		var processed = AL.getSourcei(handle, AL.BUFFERS_PROCESSED);
		if (processed > 0) {
			fillBuffers(AL.sourceUnqueueBuffers(handle, processed));
			if (!safeEnd || loops > 0) {
				if (AL.getSourcei(handle, AL.BUFFERS_QUEUED) < STREAM_NUM_BUFFERS)
					fillBuffers([buffers[(++requestBuffers) - 1]]);
			}
		}
		#end
	}

	// Timers
	inline function stopStreamTimer():Void {
		if (streamSources.contains(this)) {
			streamSources.remove(this);
			lengthStreamSources--;
		}
	}

	private function resetStreamTimer():Void {
		if (!streamSources.contains(this)) {
			streamSources.push(this);
			lengthStreamSources++;
		}
		if (!threadRunning) {
			threadRunning = true;
			Thread.create(sourceStreamHandler);
		}
	}

	inline function stopTimer():Void if (timer != null) timer.stop();

	private function resetTimer(timeRemaining:Float):Void {
		stopTimer();

		if (timeRemaining <= 30) {
			timer_onRun();
			return;
		}
		timer = new Timer(timeRemaining);
		timer.run = timer_onRun;
	}

	private function timer_onRun():Void {
		if (!safeEnd && bufferLoops <= 0) {
			#if lime_vorbis
			var ranOut = false;
			if (stream) {
				var vorbisFile = parent.buffer.__srcVorbisFile;
				if (vorbisFile == null) return dispose();
				ranOut = vorbisFile.pcmTell() >= getLengthSamples() || queuedBuffers < 3;
			}

			if (!ranOut)
			#end
			{
				var timeRemaining = (getLength() - getCurrentTime()) / getPitch();
				if (timeRemaining > 100 && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING) {
					resetTimer(timeRemaining);
					return;
				}
			}
		}
		safeEnd = false;

		if (loops <= 0) {
			complete();
			return;
		}

		if (bufferLoops > 0) {
			loops -= bufferLoops;
			bufferLoops = 0;
			parent.onLoop.dispatch();
			return;
		}

		loops--;
		setCurrentTime(loopTime != null ? loopTime : 0);
		parent.onLoop.dispatch();
	}

	// Get & Set Methods
	public function getCurrentTime():Float {
		if (completed) return getLength();
		else if (!disposed) {
			#if (lime >= "8.2.0") // [0] == realOffset, [1] == deviceOffset
			var value = AL.getSourcedvSOFT(handle, AL.SEC_OFFSET_LATENCY_SOFT, 2), time = value[0] - value[1];
			#else
			var time = AL.getSourcef(handle, AL.SEC_OFFSET);
			#end
			if (stream) time += bufferTimeBlocks[STREAM_NUM_BUFFERS - queuedBuffers];
			time = (time * 1000) - parent.offset;
			if (loops > 0 && time > getLength()) {
				var start = loopTime != null ? Math.max(0, loopTime + parent.offset) : parent.offset;
				return ((time - start) % (getLength() - start)) + start;
			}
			else if (time > 0) return time;
		}
		return 0;
	}

	public function setCurrentTime(value:Float):Float {
		if (disposed = (handle == null)) return value;

		var total = getRealLength();
		var time = Math.max(0, Math.min(total, value + parent.offset)), ratio = time / total;

		if (stream) {
			// TODO: smooth setCurrentTime for stream (dont refill buffers again)

			AL.sourceStop(handle);
			AL.sourceUnqueueBuffers(handle, AL.getSourcei(handle, AL.BUFFERS_QUEUED));

			#if lime_vorbis
			var vorbisFile = parent.buffer.__srcVorbisFile;
			if (vorbisFile != null) {
				// var chunk = Std.int(Math.floor(getFloat(samples) * ratio / STREAM_BUFFER_SIZE) * STREAM_BUFFER_SIZE);
				vorbisFile.pcmSeek(Int64.fromFloat(getFloat(samples) * ratio));
				fillBuffers(buffers.slice(0, requestBuffers = queuedBuffers = 3));
				// AL.sourcei(handle, AL.SAMPLE_OFFSET, Std.int((samples * ratio) - chunk));
				if (playing) resetStreamTimer();
			}
			#end
		}
		else {
			AL.sourceRewind(handle);
			AL.sourceUnqueueBuffers(handle, AL.getSourcei(handle, AL.BUFFERS_QUEUED) + AL.getSourcei(handle, AL.BUFFERS_PROCESSED));
			AL.sourceQueueBuffer(handle, parent.buffer.__srcBuffer);
			AL.sourcei(handle, AL.BYTE_OFFSET, Int64.fromFloat(getFloat(dataLength) * ratio));
		}

		if (playing) {
			var timeRemaining = (getLength() - time) / getPitch();
			if (completed = timeRemaining <= 0) complete();
			else {
				AL.sourcePlay(handle);
				resetTimer(timeRemaining);
			}
		}

		return value;
	}

	inline private function getLengthSamples():Int64 {
		return if (length == null) samples;
		else Int64.fromFloat((length + parent.offset) / 1000 * parent.buffer.sampleRate);
	}
	
	inline private function getFloat(x:Int64):Float return x.high * 4294967296. + (x.low >>> 0);

	inline private function getRealLength():Float return getFloat(samples) / parent.buffer.sampleRate * 1000;

	public function getLength():Float {
		return if (length == null) getRealLength() - parent.offset;
		else length - parent.offset;
	}

	public function setLength(value:Float):Float {
		if (value == length) return value;
		if (playing) {
			var timeRemaining = ((value - parent.offset) - getCurrentTime()) / getPitch();
			if (timeRemaining > 0) resetTimer(timeRemaining);
		}
		return length = value;
	}

	public function getPitch():Float {
		return if (disposed) 1;
		else AL.getSourcef(handle, AL.PITCH);
	}

	public function setPitch(value:Float):Float {
		if (disposed || value == AL.getSourcef(handle, AL.PITCH)) return value;
		if (playing) {
			var timeRemaining = (getLength() - getCurrentTime()) / value;
			if (timeRemaining > 0) resetTimer(timeRemaining);
		}
		AL.sourcef(handle, AL.PITCH, value);
		return value;
	}

	public function getGain():Float {
		if (disposed) return 1;
		return AL.getSourcef(handle, AL.GAIN);
	}

	public function setGain(value:Float):Float {
		if (!disposed) AL.sourcef(handle, AL.GAIN, value);
		return value;
	}

	inline public function getLoops():Int return loops;

	inline public function setLoops(value:Int):Int return loops = value;

	inline public function getLoopTime():Float return loopTime;

	inline public function setLoopTime(value:Float):Float return loopTime = value;

	public function getPosition():Vector4 return position;

	public function setPosition(value:Vector4):Vector4 {
		position.x = value.x;
		position.y = value.y;
		position.z = value.z;
		position.w = value.w;

		if (!disposed) {
			AL.distanceModel(AL.NONE);
			AL.source3f(handle, AL.POSITION, position.x, position.y, position.z);
		}
		return position;
	}
}

/*
	// Stream Handler
	private static var threadRunning:Bool = false;
	private static var streamSources:Array<NativeAudioSource> = [];
	private static var requestStreamSources:Array<Dynamic> = []; // NativeAudioSource, Int
	private static var lengthStreamSources:Int = 0;
	private static var mutex:Mutex = new Mutex();

	private static var streamHandlerTimer:Timer;
	private static var streamThread:Thread;

	private static function sourceStreamThread():Void {
		var i = 0, n = 0, source:NativeAudioSource;

		while ((n = lengthStreamSources) != 0) {
			try {
				i = -1;
				while (++i < n) {
					if ((source = streamSources[i]).handle == null) continue;

					var handle = source.handle, processed = AL.getSourcei(handle, AL.BUFFERS_PROCESSED);
					if (processed > 0) {
						source.fillBuffers(processed);
						var queued = AL.getSourcei(handle, AL.BUFFERS_QUEUED);
						if ((!source.safeEnd || source.loops > 0) && queued < STREAM_NUM_BUFFERS) {
							source.requestBuffers = queued + 1;
							source.fillBuffers(1);
							processed++;
						}
					}

					requestStreamSources.push(source);
					requestStreamSources.push(processed);
				}
			}
			catch (e) {
				trace('Streaming Error: $e');
				if (streamSources[i] != null) {
					mutex.acquire();
					streamSources[i].dispose();
					mutex.release();
				}
			}

			Thread.readMessage(true);
		}

		threadRunning = false;
	}

	private static function sourceStreamHandler():Void {
		var source:NativeAudioSource;
		while ((source = requestStreamSources.shift()) != null) {
			var request:Int = requestStreamSources.shift();
			var processed = AL.getSourcei(source.handle, AL.BUFFERS_PROCESSED);
			var buffers = source.requestBuffers;

			source.requestBuffers -= request - processed;
			source.uploadBuffers(AL.sourceUnqueueBuffers(source.handle, processed));
			source.requestBuffers = buffers;

			if (request > processed) source.uploadBuffers(source.buffers.slice(processed + 1, request));
		}

		streamThread.sendMessage(0);
	}

	private function readVorbisFileBuffer(vorbisFile:VorbisFile, max:Int):Void {
		#if lime_vorbis
		var id = STREAM_NUM_BUFFERS - requestBuffers, read = STREAM_NUM_BUFFERS - 1, total = 0, readMax = 0;
		var buffer = bufferDatas[id];

		mutex.acquire();
		queuedBuffers = requestBuffers;
		for (i in id...read) {
			bufferTimeBlocks[i] = bufferTimeBlocks[i + 1];
			bufferDatas[i] = bufferDatas[i + 1];
		}
		bufferTimeBlocks[read] = vorbisFile.timeTell();
		bufferDatas[read] = buffer;

		while (total < STREAM_BUFFER_SIZE) {
			if ((readMax = 4096) > (read = max - total)) readMax = read;
			if (readMax > 0 && (read = vorbisFile.read(buffer.buffer, total, readMax)) > 0) total += read;
			else if (loops > bufferLoops) {
				if (readMax == 4096) continue;
				bufferLoops++; vorbisFile.timeSeek((loopTime != null ? Math.max(0, loopTime / 1000) : 0) + parent.offset / 1000);
				if ((max = (dataLength - (vorbisFile.pcmTell() * (Int64.ofInt(bitsPerSample) / 8) * parent.buffer.channels)).low) > STREAM_BUFFER_SIZE)
					max = STREAM_BUFFER_SIZE;
			}
			else {
				safeEnd = true;
				buffer.buffer.fill(total, STREAM_BUFFER_SIZE - total - 1, 0);
				resetTimer((getLength() - getCurrentTime()) / getPitch());
				break;
			}
		}
		mutex.release();
		#end
	}

	private function fillBuffers(len:Int):Void {
		#if lime_vorbis
		if (parent == null || parent.buffer == null) return dispose();

		var buffer = parent.buffer;
		var vorbisFile = buffer.__srcVorbisFile;
		var actualDataRate = (Int64.ofInt(bitsPerSample) / 8) * buffer.channels;
		var position = vorbisFile.pcmTell() * actualDataRate, length = getLengthSamples() * actualDataRate;
		if (position >= length && safeEnd) return;

		var i = 0, size:Int64;
		while (i++ < len) {
			if ((size = length - position) > STREAM_BUFFER_SIZE) size = Int64.ofInt(STREAM_BUFFER_SIZE);
			readVorbisFileBuffer(vorbisFile, Int64.toInt(size));

			if (safeEnd) break;
			else if ((position += size) >= length && bufferLoops > 0) position = vorbisFile.pcmTell() * actualDataRate;
		}
		#end
	}

	private function uploadBuffers(buffers:Array<ALBuffer>):Void {
		if (parent == null || parent.buffer == null) return dispose();
		if (buffers.length < 1) return;

		var buffer = parent.buffer, sampleRate = buffer.sampleRate, numBuffers = buffers.length;
		for (i in 0...numBuffers)
			AL.bufferData(buffers[i], format, bufferDatas[STREAM_NUM_BUFFERS - requestBuffers - i], STREAM_BUFFER_SIZE, sampleRate);

		AL.sourceQueueBuffers(handle, numBuffers, buffers);
		if (playing && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.STOPPED) {
			AL.sourcePlay(handle);  
			resetTimer(Std.int((getLength() - getCurrentTime()) / getPitch()));
		}
	}

	// Timers
	inline function stopStreamTimer():Void {
		if (streamSources.contains(this)) {
			streamSources.remove(this);
			lengthStreamSources--;
			if (lengthStreamSources <= 0) {
				if (streamHandlerTimer != null) {
					streamHandlerTimer.stop();
					streamHandlerTimer = null;
				}
				streamThread.sendMessage(0);
			}
		}
	}

	private function resetStreamTimer():Void {
		if (!streamSources.contains(this)) {
			streamSources.push(this);
			lengthStreamSources++;
			if (!threadRunning) {
				threadRunning = true;
				streamThread = Thread.create(sourceStreamThread);
			}
			if (streamHandlerTimer == null) {
				streamHandlerTimer = new Timer(STREAM_TIMER_FREQUENCY);
				streamHandlerTimer.run = sourceStreamHandler;
			}
		}
	}
*/