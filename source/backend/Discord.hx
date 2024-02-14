package backend;

#if (cpp && DISCORD_ALLOWED)
import Sys.sleep;
import cpp.Function;
import cpp.RawPointer;
import cpp.RawConstPointer;
import cpp.ConstPointer;
import cpp.ConstCharStar;
import cpp.Star;

import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient {
	private static final _defaultID:String = "1031744183737786378";

	public static var isInitialized:Bool = false;
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public static function check() {
		if (ClientPrefs.data.discordRPC) initialize();
		else if (isInitialized) shutdown();
	}
	
	public static function prepare() {
		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(() -> {if (isInitialized) shutdown();});
	}

	public dynamic static function shutdown() {
		Discord.Shutdown();
		isInitialized = false;
	}
	
	private static function onReady(request:RawConstPointer<DiscordUser>):Void {
		var requestPtr:Star<DiscordUser> = ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else //Old discriminators
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)})');

		changePresence();
	}

	private static function onError(errorCode:Int, message:ConstCharStar):Void
		trace('Discord: Error ($errorCode: ${cast(message, String)})');

	private static function onDisconnected(errorCode:Int, message:ConstCharStar):Void
		trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');

	public static function initialize() {
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, RawPointer.addressOf(discordHandlers), 1, null);

		if (!isInitialized) trace("Discord Client initialized");

		sys.thread.Thread.create(() -> {
			var localID:String = clientID;
			while (localID == clientID) {
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey: String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "OneFunk";
		presence.smallImageKey = smallImageKey;

		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updatePresence()
		Discord.UpdatePresence(RawConstPointer.addressOf(presence));
	
	public static function resetClientID()
		clientID = _defaultID;

	private static function set_clientID(newID:String) {
		if (clientID != newID) {
			clientID = newID;
			if (isInitialized) {
				shutdown();
				initialize();
				updatePresence();
			}
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String = null) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
#end