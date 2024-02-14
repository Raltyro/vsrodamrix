package backend;

class Difficulty {
	// The chart that has no suffix and starting difficulty on Freeplay/Story Mode
	private static var defaultDifficulty(default, never):String = 'Normal';

	public static var defaultList(default, never):Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var list:Array<String> = [];
	public static var lowercaseList(get, null):Array<String>;
	inline static function get_lowercaseList():Array<String> return [for (v in list) v.toLowerCase()];

	inline public static function getFilePath(num:Null<Int> = null) {
		if (num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = list[num];
		if (fileSuffix != defaultDifficulty) fileSuffix = '-' + fileSuffix;
		else fileSuffix = '';

		return Paths.formatToSongPath(fileSuffix);
	}

	inline public static function loadFromWeek(week:WeekData = null) {
		if (week == null) week = WeekData.getCurrentWeek();

		var diffStr:String = week.difficulties;
		if (diffStr != null && diffStr.length > 0) {
			var diffs:Array<String> = diffStr.trim().split(',');
			var i:Int = diffs.length - 1;
			while (i > 0) {
				if (diffs[i] != null) {
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if (diffs.length > 0 && diffs[0].length > 0)
				list = diffs;
		}
		else
			resetList();
	}

	inline public static function resetList()
		list = defaultList.copy();

	inline public static function copyFrom(diffs:Array<String>)
		list = diffs.copy();

	inline public static function getString(num:Null<Int> = null):String
		return list[num == null ? PlayState.storyDifficulty : num];

	inline public static function getDefault():String
		return defaultDifficulty;
}