package modding;

import shaders.custom.CustomShader;
import openfl.filters.ShaderFilter;
import shaders.custom.flixel.FlxRuntimeShader;
import flixel.util.FlxTimer;
#if linc_luajit
import flixel.addons.effects.FlxTrail;
import flixel.text.FlxText;
import openfl.display.BlendMode;
import flixel.FlxCamera;
import game.DancingSprite;
import game.Boyfriend;
import ui.HealthIcon;
import game.Character;
import flixel.util.FlxColor;
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.FlxSprite;
import states.PlayState;
import lime.utils.Assets;
import flixel.sound.FlxSound;
import utilities.CoolUtil;
import polymod.backends.PolymodAssets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import llua.Lua.Lua_helper;
import flixel.FlxG;
import game.Conductor;
import lime.app.Application;
#if MODCHARTING_TOOLS
import modcharting.ModchartFuncs;
#end

using StringTools;

class ModchartUtilities {
	public var lua:State = null;

	public static var lua_Sprites:Map<String, FlxSprite> = [
		'boyfriend' => PlayState.boyfriend,
		'girlfriend' => PlayState.gf,
		'dad' => PlayState.dad,
	];

	public static var lua_Characters:Map<String, Character> = [
		'boyfriend' => PlayState.boyfriend,
		'girlfriend' => PlayState.gf,
		'dad' => PlayState.dad,
	];

	public static var lua_Sounds:Map<String, FlxSound> = [];
	public static var lua_Shaders:Map<String, shaders.Shaders.ShaderEffect> = [];
	public static var lua_Custom_Shaders:Map<String, CustomShader> = [];

	public var functions_called:Array<String> = [];

	function getActorByName(id:String):Dynamic {
		// lua objects or what ever
		if (lua_Sprites.exists(id))
			return lua_Sprites.get(id);
		else if (lua_Sounds.exists(id))
			return lua_Sounds.get(id);
		else if (lua_Shaders.exists(id))
			return lua_Shaders.get(id);
		else if (lua_Custom_Shaders.exists(id))
			return lua_Custom_Shaders.get(id);


		if (Reflect.getProperty(PlayState.instance, id) != null)
			return Reflect.getProperty(PlayState.instance, id);
		else if (Reflect.getProperty(PlayState, id) != null)
			return Reflect.getProperty(PlayState, id);

		if (PlayState.strumLineNotes.length - 1 >= Std.parseInt(id)) @:privateAccess
			return PlayState.strumLineNotes.members[Std.parseInt(id)];

		return null;
	}

	function getCharacterByName(id:String):Dynamic {
		// lua objects or what ever
		if (lua_Characters.exists(id))
			return lua_Characters.get(id);

		return null;
	}

	public function die() {
		PlayState.songMultiplier = oldMultiplier;

		lua_Sprites.clear();
		lua_Characters.clear();
		lua_Shaders.clear();
		lua_Custom_Shaders.clear();
		lua_Sounds.clear();

		Lua.close(lua);
		lua = null;
	}

	function getLuaErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);

		return v;
	}

	function callLua(func_name:String, args:Array<Dynamic>, ?type:String):Dynamic {
		functions_called.push(func_name);
		var result:Any = null;

		Lua.getglobal(lua, func_name);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		result = Lua.pcall(lua, args.length, 1, 0);

		var p = Lua.tostring(lua, result);
		var e = getLuaErrorMessage(lua);

		if (result == null) {
			return null;
		} else {
			return convert(result, type);
		}
	}

	public function setVar(name:String, value:Dynamic):Void {
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
	}

	var oldMultiplier:Float = PlayState.songMultiplier;

	public var trails:Map<String, FlxTrail> = [];

	public var extra_scripts:Array<ModchartUtilities> = [];

	/**
	 * Easy wrapper for `Lua_helper.add_callback`.
	 * @param name Function name
	 * @param func Function to use
	 */
	function setLuaFunction(name:String, func:Dynamic):Void {
		Lua_helper.add_callback(lua, name, func);
	}

	public function new(?path:Null<String>) {
		oldMultiplier = PlayState.songMultiplier;

		lua_Sprites.set("boyfriend", PlayState.boyfriend);
		lua_Sprites.set("girlfriend", PlayState.gf);
		lua_Sprites.set("dad", PlayState.dad);

		lua_Characters.set("boyfriend", PlayState.boyfriend);
		lua_Characters.set("girlfriend", PlayState.gf);
		lua_Characters.set("dad", PlayState.dad);

		lua_Sounds.set("Inst", FlxG.sound.music);
		@:privateAccess
		lua_Sounds.set("Voices", PlayState.instance.vocals);

		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		trace("lua version: " + Lua.version());
		trace("LuaJIT version: " + Lua.versionJIT());

		Lua.init_callbacks(lua);

		if (path == null)
			path = PolymodAssets.getPath(Paths.lua("modcharts/" + PlayState.SONG.modchartPath));

		var result = LuaL.dofile(lua, path); // execute le file

		if (result != 0) {
			CoolUtil.coolError("Lua ERROR:\n" + Lua.tostring(lua, result), "Leather Engine Modcharts");
			// FlxG.switchState(new MainMenuState());
		}

		// this might become a problem if i don't do this
		setVar("require", false);
		setVar("os", false);

		// get some fukin globals up in here bois

		setVar("difficulty", PlayState.storyDifficultyStr);
		setVar("bpm", Conductor.bpm);
		setVar("songBpm", PlayState.SONG.bpm);
		setVar("keyCount", PlayState.SONG.keyCount);
		setVar("playerKeyCount", PlayState.SONG.playerKeyCount);
		setVar("scrollspeed", PlayState.SONG.speed);
		setVar("fpsCap", utilities.Options.getData("maxFPS"));
		setVar("bot", utilities.Options.getData("botplay"));
		setVar("noDeath", utilities.Options.getData("noDeath"));
		setVar("downscroll", utilities.Options.getData("downscroll") == true ? 1 : 0); // fuck you compatibility
		setVar("downscrollBool", utilities.Options.getData("downscroll"));
		setVar("middlescroll", utilities.Options.getData("middlescroll"));
		setVar("flashingLights", utilities.Options.getData("flashingLights"));
		setVar("flashing", utilities.Options.getData("flashingLights"));
		setVar("distractions", true);
		setVar("cameraZooms", utilities.Options.getData("cameraZooms"));
		setVar("shaders", utilities.Options.getData("shaders"));

		setVar("animatedBackgrounds", utilities.Options.getData("animatedBGs"));

		setVar("curStep", 0);
		setVar("curBeat", 0);
		setVar("stepCrochet", Conductor.stepCrochet);
		setVar("crochet", Conductor.crochet);
		setVar("safeZoneOffset", Conductor.safeZoneOffset);

		setVar("hudZoom", PlayState.instance.camHUD.zoom);
		setVar("cameraZoom", FlxG.camera.zoom);

		setVar("cameraAngle", FlxG.camera.angle);

		setVar("camHudAngle", PlayState.instance.camHUD.angle);

		setVar("followXOffset", 0);
		setVar("followYOffset", 0);

		setVar("showOnlyStrums", false);
		setVar("strumLine1Visible", true);
		setVar("strumLine2Visible", true);

		setVar("screenWidth", lime.app.Application.current.window.display.currentMode.width);
		setVar("screenHeight", lime.app.Application.current.window.display.currentMode.height);
		setVar("windowWidth", FlxG.width);
		setVar("windowHeight", FlxG.height);

		setVar("hudWidth", PlayState.instance.camHUD.width);
		setVar("hudHeight", PlayState.instance.camHUD.height);

		setVar("mustHit", false);
		setVar("strumLineY", PlayState.instance.strumLine.y);

		setVar("characterPlayingAs", PlayState.characterPlayingAs);
		setVar("inReplay", PlayState.playingReplay);

		// other globals

		setVar('FlxColor', {
			TRANSPARENT: 0x00000000,
			WHITE: 0xFFFFFFFF,
			GRAY: 0xFF808080,
			BLACK: 0xFF000000,

			GREEN: 0xFF008000,
			LIME: 0xFF00FF00,
			YELLOW: 0xFFFFFF00,
			ORANGE: 0xFFFFA500,
			RED: 0xFFFF0000,
			PURPLE: 0xFF800080,
			BLUE: 0xFF0000FF,
			BROWN: 0xFF8B4513,
			PINK: 0xFFFFC0CB,
			MAGENTA: 0xFFFF00FF,
			CYAN: 0xFF00FFFF,
		});

		setVar("Conductor", {
			bpm: Conductor.bpm,
			crochet: Conductor.crochet,
			stepCrochet: Conductor.stepCrochet,
			songPosition: Conductor.songPosition,
			lastSongPos: Conductor.lastSongPos,
			offset: Conductor.offset,
			safeFrames: Conductor.safeFrames,
			safeZoneOffset: Conductor.safeZoneOffset,
			bpmChangeMap: Conductor.bpmChangeMap,
			timeScaleChangeMap: Conductor.timeScaleChangeMap,
			timeScale: Conductor.timeScale,
			stepsPerSection: Conductor.stepsPerSection,
		});

		setVar("FlxG", {
			width: FlxG.width,
			height: FlxG.height,
			elapsed: FlxG.elapsed,
		});

		setVar("lua", {
			version: Lua.version(),
			versionJIT: Lua.versionJIT(),
		});

		setVar("SONG", PlayState.SONG);

		setVar("leatherEngine", {
			version: lime.app.Application.current.meta.get('version'),
		});

		// callbacks

		setLuaFunction("flashCamera", function(camera:String = "", color:String = "#FFFFFF", time:Float = 1, force:Bool = false) {
			if (utilities.Options.getData("flashingLights"))
				cameraFromString(camera).flash(FlxColor.fromString(color), time, null, force);
		});

		setLuaFunction("triggerEvent", function(event_name:String, argument_1:Dynamic, argument_2:Dynamic) {
			var string_arg_1:String = Std.string(argument_1);
			var string_arg_2:String = Std.string(argument_2);

			if (!PlayState.instance.event_luas.exists(event_name.toLowerCase())
				&& Assets.exists(Paths.lua("event data/" + event_name.toLowerCase()))) {
				PlayState.instance.event_luas.set(event_name.toLowerCase(),
					new ModchartUtilities(PolymodAssets.getPath(Paths.lua("event data/" + event_name.toLowerCase()))));
				PlayState.instance.generatedSomeDumbEventLuas = true;
			}

			PlayState.instance.processEvent([event_name, Conductor.songPosition, string_arg_1, string_arg_2]);
		});

		setLuaFunction("setCamera", function(id:String, camera:String = "") {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
		});

		setLuaFunction("setObjectCamera", function(id:String, camera:String = "") {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				Reflect.setProperty(actor, "cameras", [cameraFromString(camera)]);
		});

		setLuaFunction("setGraphicSize", function(id:String, width:Int = 0, height:Int = 0) {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.setGraphicSize(width, height);
		});

		setLuaFunction("updateHitbox", function(id:String) {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.updateHitbox();
		});

		setLuaFunction("setBlendMode", function(id:String, blend:String = '') {
			var actor:FlxSprite = getActorByName(id);

			if (actor != null)
				actor.blend = blendModeFromString(blend);
		});

		// sprites

		// stage

		setLuaFunction("makeGraphic", function(id:String, width:Int, height:Int, color:String) {
			if (getActorByName(id) != null)
				getActorByName(id).makeGraphic(width, height, FlxColor.fromString(color));
		});

		setLuaFunction("makeStageSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				@:privateAccess
				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.image(PlayState.instance.stage.stage + "/" + filename, "stages"));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				@:privateAccess
				PlayState.instance.stage.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeStageAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				@:privateAccess
				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				@:privateAccess
				PlayState.instance.stage.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeStageDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					@:privateAccess
					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(PlayState.instance.stage.stage + "/" + filename, "stages");

					Sprite.scale.set(size, sizeY == null ? size : sizeY);
					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);

					@:privateAccess
					PlayState.instance.stage.add(Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		// regular

		setLuaFunction("exists", function(id:String):Bool {
			if (getActorByName(id) != null)
				return Reflect.getProperty(getActorByName(id), 'exists') != true ? false : true;

			return false;
		});

		setLuaFunction("randomBool", function(chance:Float):Bool {
			return FlxG.random.bool(chance);
		});

		setLuaFunction("randomFloat", function(min:Float, max:Float):Float {
			return FlxG.random.float(min, max);
		});

		setLuaFunction("randomInt", function(min:Int, max:Int):Int {
			return FlxG.random.int(min, max);
		});

		setLuaFunction("loadScript", function(script:String) {
			var modchart:ModchartUtilities = null;

			if (Assets.exists(Paths.lua("modcharts/" + script)))
				modchart = new ModchartUtilities(PolymodAssets.getPath(Paths.lua("modcharts/" + script)));
			else if (Assets.exists(Paths.lua("scripts/" + script)))
				modchart = new ModchartUtilities(PolymodAssets.getPath(Paths.lua("scripts/" + script)));

			if (modchart == null) {
				trace('Couldn\'t find script at either ${Paths.lua("modcharts/" + script)} OR ${Paths.lua("scripts/" + script)}!', WARNING);
				return;
			}

			modchart.setupTheShitCuzPullRequestsSuck();

			if (functions_called.contains("create"))
				modchart.executeState("create", [PlayState.SONG.song.toLowerCase()]);
			if (functions_called.contains("createPost"))
				modchart.executeState("createPost", [PlayState.SONG.song.toLowerCase()]);
			if (functions_called.contains("start"))
				modchart.executeState("start", [PlayState.SONG.song.toLowerCase()]);

			extra_scripts.push(modchart);
		});

		setLuaFunction("tween", function(obj:String, properties:Dynamic, duration:Float, ease:String, ?startDelay:Float = 0.0, ?onComplete:Dynamic) {
			var spr:Dynamic = getActorByName(obj);

			if (spr != null) {
				FlxTween.tween(spr, properties, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn) {
						if (onComplete != null)
							onComplete();
					},
					startDelay: startDelay,
				});
			} else {
				trace('Object named $obj doesn\'t exist!', ERROR);
			}
		});

		setLuaFunction("printIP", function():Void {
			trace('${FlxG.random.int(100, 999)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}');
		});

		setLuaFunction("getIP", function():String {
			return '${FlxG.random.int(100, 999)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}.${FlxG.random.int(1, 99)}';
		});

		setLuaFunction("color", function(r:Int, g:Int, b:Int, a:Int = 255):Int {
			return FlxColor.fromRGB(r, g, b, a);
		});

		setLuaFunction("colorString", function(color:String):Int {
			return FlxColor.fromString(color);
		});

		setLuaFunction("colorRGB", function(r:Int, g:Int, b:Int):Int {
			return FlxColor.fromRGB(r, g, b);
		});

		setLuaFunction("colorRGBA", function(r:Int, g:Int, b:Int, a:Int):Int {
			return FlxColor.fromRGB(r, g, b, a);
		});

		// sprite functions

		setLuaFunction("screenCenter", function(id:String, ?direction:String = "xy") {
			if (getActorByName(id) != null)
				getActorByName(id).screenCenter((direction.toLowerCase().contains('x') ? 0x01 : 0x00) + (direction.toLowerCase().contains('y') ? 0x10 : 0x00));
		});

		setLuaFunction("center", function(id:String, ?direction:String = "xy") {
			if (getActorByName(id) != null)
				getActorByName(id).screenCenter((direction.toLowerCase().contains('x') ? 0x01 : 0x00) + (direction.toLowerCase().contains('y') ? 0x10 : 0x00));
		});

		setLuaFunction("add", function(id:String) {
			FlxG.state.add(getActorByName(id));
		});

		setLuaFunction("remove", function(id:String, splice:Bool = true) {
			FlxG.state.remove(getActorByName(id), splice);
		});

		setLuaFunction("kill", function(id:String) {
			getActorByName(id).kill();
		});

		setLuaFunction("destroy", function(id:String) {
			getActorByName(id).destroy();
		});

		setLuaFunction("insert", function(id:String, position:Int) {
			FlxG.state.insert(position, getActorByName(id));
		});

		// stage sprite functions

		setLuaFunction("addStage", function(id:String) {
			PlayState.instance.stage.add(getActorByName(id));
		});

		setLuaFunction("removeStage", function(id:String, splice:Bool = true) {
			PlayState.instance.stage.remove(getActorByName(id), splice);
		});

		setLuaFunction("insertStage", function(id:String, position:Int) {
			PlayState.instance.stage.insert(position, getActorByName(id));
		});

		setLuaFunction("setActorTextColor", function(id:String, color:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "color", FlxColor.fromString(color));
		});

		setLuaFunction("setActorText", function(id:String, text:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "text", text);
		});

		setLuaFunction("setActorAlignment", function(id:String, align:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "alignment", align);
		});

		setLuaFunction("newText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxText = new FlxText(x, y, fieldWidth, text, size);
				Sprite.font = Paths.font(font);

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.image(filename));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(filename);

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("newDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(filename);

					Sprite.scale.set(size, sizeY == null ? size : sizeY);
					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		setLuaFunction("makeText", function(id:String, text:String, x:Float, y:Float, size:Int = 32, font:String = "vcr.ttf", fieldWidth:Float = 0) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxText = new FlxText(x, y, fieldWidth, text, size);
				Sprite.font = Paths.font(font);

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.loadGraphic(Paths.image(filename));

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeAnimatedSprite", function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?sizeY:Float = null) {
			if (!lua_Sprites.exists(id)) {
				var Sprite:FlxSprite = new FlxSprite(x, y);

				if (filename != null && filename.length > 0)
					Sprite.frames = Paths.getSparrowAtlas(filename);

				Sprite.scale.set(size, sizeY == null ? size : sizeY);
				Sprite.updateHitbox();

				lua_Sprites.set(id, Sprite);

				PlayState.instance.add(Sprite);
			} else
				CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
		});

		setLuaFunction("makeDancingSprite",
			function(id:String, filename:String, x:Float, y:Float, size:Float = 1, ?oneDanceAnimation:Bool, ?antialiasing:Bool, ?sizeY:Float = null) {
				if (!lua_Sprites.exists(id)) {
					var Sprite:DancingSprite = new DancingSprite(x, y, oneDanceAnimation, antialiasing);

					if (filename != null && filename.length > 0)
						Sprite.frames = Paths.getSparrowAtlas(filename);

					Sprite.scale.set(size, sizeY == null ? size : sizeY);
					Sprite.updateHitbox();

					lua_Sprites.set(id, Sprite);

					PlayState.instance.add(Sprite);
				} else
					CoolUtil.coolError("Sprite " + id + " already exists! Choose a different name!", "Leather Engine Modcharts");
			});

		setLuaFunction("destroySprite", function(id:String) {
			var sprite = lua_Sprites.get(id);

			if (sprite == null)
				return false;

			lua_Sprites.remove(id);

			PlayState.instance.remove(sprite);
			sprite.kill();
			sprite.destroy();

			return true;
		});

		setLuaFunction("getIsColliding", function(sprite1Name:String, sprite2Name:String) {
			var sprite1 = getActorByName(sprite1Name);

			if (sprite1 != null) {
				var sprite2 = getActorByName(sprite2Name);

				if (sprite2 != null)
					return sprite1.overlaps(sprite2);
			}

			return false;
		});

		setLuaFunction("addActorTrail", function(id:String, length:Int = 10, delay:Int = 3, alpha:Float = 0.4, diff:Float = 0.05) {
			if (!trails.exists(id) && getActorByName(id) != null) {
				var trail = new FlxTrail(getActorByName(id), null, length, delay, alpha, diff);

				PlayState.instance.insert(PlayState.instance.members.indexOf(getActorByName(id)) - 1, trail);

				trails.set(id, trail);
			} else
				trace("Trail " + id + " already exists (or actor is null)!!!");
		});

		setLuaFunction("removeActorTrail", function(id:String) {
			if (trails.exists(id)) {
				PlayState.instance.remove(trails.get(id));

				trails.get(id).destroy();
				trails.remove(id);
			} else
				trace("Trail " + id + " doesn't exist!!!");
		});

		setLuaFunction("getActorLayer", function(id:String) {
			var actor = getActorByName(id);

			if (actor != null)
				return PlayState.instance.members.indexOf(actor);
			else
				return -1;
		});

		setLuaFunction("setActorLayer", function(id:String, layer:Int) {
			var actor = getActorByName(id);

			if (actor != null) {
				if (trails.exists(id)) {
					PlayState.instance.remove(trails.get(id));
					PlayState.instance.insert(layer - 1, trails.get(id));
				}

				PlayState.instance.remove(actor);
				PlayState.instance.insert(layer, actor);
			}
		});

		// health

		setLuaFunction("getHealth", function() {
			return PlayState.instance.health;
		});

		setLuaFunction("setHealth", function(heal:Float) {
			PlayState.instance.health = heal;
		});

		setLuaFunction("getMinHealth", function() {
			return PlayState.instance.minHealth;
		});

		setLuaFunction("getMaxHealth", function() {
			return PlayState.instance.maxHealth;
		});

		setLuaFunction('changeHealthRange', function(minHealth:Float, maxHealth:Float) {
			@:privateAccess
			{
				var bar = PlayState.instance.healthBar;
				PlayState.instance.minHealth = minHealth;
				PlayState.instance.maxHealth = maxHealth;
				bar.setRange(minHealth, maxHealth);
			}
		});

		// hud/camera

		setLuaFunction("setHudAngle", function(x:Float) {
			PlayState.instance.camHUD.angle = x;
		});

		setLuaFunction("setHudPosition", function(x:Int, y:Int) {
			PlayState.instance.camHUD.x = x;
			PlayState.instance.camHUD.y = y;
		});

		setLuaFunction("getHudX", function() {
			return PlayState.instance.camHUD.x;
		});

		setLuaFunction("getHudY", function() {
			return PlayState.instance.camHUD.y;
		});

		setLuaFunction("setCamPosition", function(x:Int, y:Int) {
			@:privateAccess
			{
				PlayState.instance.camFollow.x = x;
				PlayState.instance.camFollow.y = y;
			}
		});

		setLuaFunction("getCameraX", function() {
			@:privateAccess
			return PlayState.instance.camFollow.x;
		});

		setLuaFunction("getCameraY", function() {
			@:privateAccess
			return PlayState.instance.camFollow.y;
		});

		setLuaFunction("getCamZoom", function() {
			return FlxG.camera.zoom;
		});

		setLuaFunction("getHudZoom", function() {
			return PlayState.instance.camHUD.zoom;
		});

		setLuaFunction("setCamZoom", function(zoomAmount:Float) {
			FlxG.camera.zoom = zoomAmount;
		});

		setLuaFunction("setHudZoom", function(zoomAmount:Float) {
			PlayState.instance.camHUD.zoom = zoomAmount;
		});

		// strumline

		setLuaFunction("setStrumlineY", function(y:Float, ?dontMove:Bool = false) {
			PlayState.instance.strumLine.y = y;

			if (!dontMove) {
				for (note in PlayState.strumLineNotes) {
					note.y = y;
				}
			}
		});

		// actors

		setLuaFunction("getRenderedNotes", function() {
			return PlayState.instance.notes.length;
		});

		setLuaFunction("getRenderedNoteX", function(id:Int) {
			return PlayState.instance.notes.members[id].x;
		});

		setLuaFunction("getRenderedNoteY", function(id:Int) {
			return PlayState.instance.notes.members[id].y;
		});

		setLuaFunction("getRenderedNoteType", function(id:Int) {
			return PlayState.instance.notes.members[id].noteData;
		});

		setLuaFunction("isSustain", function(id:Int) {
			return PlayState.instance.notes.members[id].isSustainNote;
		});

		setLuaFunction("isParentSustain", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.isSustainNote;
		});

		setLuaFunction("getRenderedNoteParentX", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.x;
		});

		setLuaFunction("getRenderedNoteParentY", function(id:Int) {
			return PlayState.instance.notes.members[id].prevNote.y;
		});

		setLuaFunction("getRenderedNoteHit", function(id:Int) {
			return PlayState.instance.notes.members[id].mustPress;
		});

		setLuaFunction("getRenderedNoteCalcX", function(id:Int) {
			if (PlayState.instance.notes.members[id].mustPress)
				return PlayState.playerStrums.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;

			return PlayState.strumLineNotes.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
		});

		setLuaFunction("anyNotes", function() {
			return PlayState.instance.notes.members.length != 0;
		});

		setLuaFunction("getRenderedNoteStrumtime", function(id:Int) {
			return PlayState.instance.notes.members[id].strumTime;
		});

		setLuaFunction("getRenderedNoteScaleX", function(id:Int) {
			return PlayState.instance.notes.members[id].scale.x;
		});

		setLuaFunction("setRenderedNotePos", function(x:Float, y:Float, id:Int) {
			if (PlayState.instance.notes.members[id] == null)
				throw('error! you cannot set a rendered notes position when it doesnt exist! ID: ' + id);
			else {
				PlayState.instance.notes.members[id].x = x;
				PlayState.instance.notes.members[id].y = y;
			}
		});

		setLuaFunction("setRenderedNoteAlpha", function(alpha:Float, id:Int) {
			PlayState.instance.notes.members[id].alpha = alpha;
		});

		setLuaFunction("setRenderedNoteScale", function(scale:Float, id:Int) {
			PlayState.instance.notes.members[id].scale.set(scale, scale);
		});

		setLuaFunction("setRenderedNoteScaleXY", function(scaleX:Int, scaleY:Int, id:Int) {
			PlayState.instance.notes.members[id].scale.set(scaleX, scaleY);
		});

		setLuaFunction("getRenderedNoteWidth", function(id:Int) {
			return PlayState.instance.notes.members[id].width;
		});

		setLuaFunction("getRenderedNoteHeight", function(id:Int) {
			return PlayState.instance.notes.members[id].height;
		});

		setLuaFunction("setRenderedNoteAngle", function(angle:Float, id:Int) {
			PlayState.instance.notes.members[id].angle = angle;
		});

		setLuaFunction("setActorX", function(x:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).x = x;
		});

		setLuaFunction("setActorPos", function(x:Float, y:Float, id:String) {
			var actor = getActorByName(id);

			if (actor != null) {
				actor.x = x;
				actor.y = y;
			}
		});

		setLuaFunction("setActorScroll", function(x:Float, y:Float, id:String) {
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				actor.scrollFactor.set(x, y);
			}
		});

		setLuaFunction("getOriginalCharX", function(character:Int) {
			@:privateAccess
			return PlayState.instance.stage.getCharacterPos(character)[0];
		});

		setLuaFunction("getOriginalCharY", function(character:Int) {
			@:privateAccess
			return PlayState.instance.stage.getCharacterPos(character)[1];
		});

		setLuaFunction("setActorAccelerationX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).acceleration.x = x;
			}
		});

		setLuaFunction("setActorDragX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).drag.x = x;
			}
		});

		setLuaFunction("setActorVelocityX", function(x:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).velocity.x = x;
			}
		});

		setLuaFunction("setActorAntialiasing", function(antialiasing:Bool, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).antialiasing = antialiasing;
			}
		});

		setLuaFunction("addActorAnimation", function(id:String, prefix:String, anim:String, fps:Int = 30, looped:Bool = true) {
			if (getActorByName(id) != null) {
				getActorByName(id).animation.addByPrefix(prefix, anim, fps, looped);
			}
		});

		setLuaFunction("addActorAnimationIndices", function(id:String, prefix:String, indiceString:String, anim:String, fps:Int = 30, looped:Bool = true) {
			if (getActorByName(id) != null) {
				var indices:Array<Dynamic> = indiceString.split(",");

				for (indiceIndex in 0...indices.length) {
					indices[indiceIndex] = Std.parseInt(indices[indiceIndex]);
				}

				getActorByName(id).animation.addByIndices(anim, prefix, indices, "", fps, looped);
			}
		});

		setLuaFunction("playCharAnim", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).playAnim(anim, force, reverse, frame);
			}
		});

		setLuaFunction("playAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).animation.play(anim, force, reverse, frame);
			}
		});

		setLuaFunction("dance", function(id:String, ?altAnim:String = '') {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setLuaFunction("playActorAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).animation.play(anim, force, reverse, frame);
			}
		});

		setLuaFunction("playActorDance", function(id:String, ?altAnim:String = '') {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setLuaFunction("playCharacterAnimation", function(id:String, anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0) {
			if (getActorByName(id) != null) {
				getActorByName(id).playAnim(anim, force, reverse, frame);
			}
		});

		setLuaFunction("setCharacterShouldDance", function(id:String, shouldDance:Bool = true) {
			if (getActorByName(id) != null) {
				getActorByName(id).shouldDance = shouldDance;
			}
		});

		setLuaFunction("playCharacterDance", function(id:String, ?altAnim:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).dance(altAnim);
			}
		});

		setLuaFunction("getPlayingActorAnimation", function(id:String) {
			if (getActorByName(id) != null) {
				if (Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
					return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "name");
			}

			return "unknown";
		});

		setLuaFunction("getPlayingActorAnimationFrame", function(id:String) {
			if (getActorByName(id) != null) {
				if (Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim") != null)
					return Reflect.getProperty(Reflect.getProperty(Reflect.getProperty(getActorByName(id), "animation"), "curAnim"), "curFrame");
			}

			return 0;
		});

		setLuaFunction("setActorAlpha", function(alpha:Float, id:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "alpha", alpha);
		});

		setLuaFunction("setActorVisible", function(visible:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).visible = visible;
		});

		setLuaFunction("setActorColor", function(id:String, r:Int, g:Int, b:Int, alpha:Int = 255) {
			if (getActorByName(id) != null) {
				Reflect.setProperty(getActorByName(id), "color", FlxColor.fromRGB(r, g, b, alpha));
			}
		});

		setLuaFunction("setActorY", function(y:Float, id:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "y", y);
		});

		setLuaFunction("setActorAccelerationY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).acceleration.y = y;
			}
		});

		setLuaFunction("setActorDragY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).drag.y = y;
			}
		});

		setLuaFunction("setActorVelocityY", function(y:Float, id:String) {
			if (getActorByName(id) != null) {
				getActorByName(id).velocity.y = y;
			}
		});

		setLuaFunction("setActorAngle", function(angle:Float, id:String) {
			if (getActorByName(id) != null)
				Reflect.setProperty(getActorByName(id), "angle", angle);
		});

		setLuaFunction("setActorModAngle", function(angle:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).modAngle = angle;
		});

		setLuaFunction("setActorScale", function(scale:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).scale.set(scale, scale);
		});

		setLuaFunction("setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).scale.set(scaleX, scaleY);
		});

		setLuaFunction("setActorFlipX", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).flipX = flip;
		});

		setLuaFunction("setActorFlipY", function(flip:Bool, id:String) {
			if (getActorByName(id) != null)
				getActorByName(id).flipY = flip;
		});

		setLuaFunction("setActorTrailVisible", function(id:String, visibleVal:Bool) {
			var char = getCharacterByName(id);

			if (char != null) {
				if (char.coolTrail != null) {
					char.coolTrail.visible = visibleVal;
					return true;
				} else
					return false;
			} else
				return false;
		});

		setLuaFunction("getActorTrailVisible", function(id:String) {
			var char = getCharacterByName(id);

			if (char != null) {
				if (char.coolTrail != null)
					return char.coolTrail.visible;
				else
					return false;
			} else
				return false;
		});

		setLuaFunction("getActorWidth", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).width;
			else
				return 0;
		});

		setLuaFunction("getActorHeight", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).height;
			else
				return 0;
		});

		setLuaFunction("getActorAlpha", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).alpha;
			else
				return 0.0;
		});

		setLuaFunction("getActorAngle", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).angle;
			else
				return 0.0;
		});

		setLuaFunction("getActorX", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).x;
			else
				return 0.0;
		});

		setLuaFunction("getActorY", function(id:String) {
			if (getActorByName(id) != null)
				return getActorByName(id).y;
			else
				return 0.0;
		});

		setLuaFunction("setWindowPos", function(x:Int, y:Int) {
			Application.current.window.move(x, y);
		});

		setLuaFunction("getWindowX", function() {
			return Application.current.window.x;
		});

		setLuaFunction("getWindowY", function() {
			return Application.current.window.y;
		});

		setLuaFunction("getCenteredWindowX", function() {
			return (Application.current.window.display.currentMode.width / 2) - (Application.current.window.width / 2);
		});

		setLuaFunction("getCenteredWindowY", function() {
			return (Application.current.window.display.currentMode.height / 2) - (Application.current.window.height / 2);
		});

		setLuaFunction("resizeWindow", function(Width:Int, Height:Int) {
			Application.current.window.resize(Width, Height);
		});

		setLuaFunction("getScreenWidth", function() {
			return Application.current.window.display.currentMode.width;
		});

		setLuaFunction("getScreenHeight", function() {
			return Application.current.window.display.currentMode.height;
		});

		setLuaFunction("getWindowWidth", function() {
			return Application.current.window.width;
		});

		setLuaFunction("getWindowHeight", function() {
			return Application.current.window.height;
		});

		setLuaFunction("setCanFullscreen", function(can_Fullscreen:Bool) {
			PlayState.instance.canFullscreen = can_Fullscreen;
		});

		setLuaFunction("changeDadCharacter", function(character:String) {
			var oldDad = PlayState.dad;
			PlayState.instance.remove(oldDad);

			var dad = new Character(100, 100, character);
			PlayState.dad = dad;

			if (dad.otherCharacters == null) {
				if (dad.coolTrail != null)
					PlayState.instance.add(dad.coolTrail);

				PlayState.instance.add(dad);
			} else {
				for (character in dad.otherCharacters) {
					if (character.coolTrail != null)
						PlayState.instance.add(character.coolTrail);

					PlayState.instance.add(character);
				}
			}

			lua_Sprites.remove("dad");

			oldDad.kill();
			oldDad.destroy();

			lua_Sprites.set("dad", dad);

			@:privateAccess
			{
				var oldIcon = PlayState.instance.iconP2;
				var bar = PlayState.instance.healthBar;

				PlayState.instance.remove(oldIcon);
				oldIcon.kill();
				oldIcon.destroy();

				PlayState.instance.iconP2 = new HealthIcon(dad.icon, false);
				PlayState.instance.iconP2.y = PlayState.instance.healthBar.y - (PlayState.instance.iconP2.height / 2);
				PlayState.instance.iconP2.cameras = [PlayState.instance.camHUD];
				PlayState.instance.add(PlayState.instance.iconP2);

				bar.createFilledBar(dad.barColor, PlayState.boyfriend.barColor);
				bar.updateFilledBar();

				PlayState.instance.stage.setCharOffsets();
			}
		});

		setLuaFunction("changeBoyfriendCharacter", function(character:String) {
			var oldBF = PlayState.boyfriend;
			PlayState.instance.remove(oldBF);

			var boyfriend = new Boyfriend(770, 450, character);
			PlayState.boyfriend = boyfriend;

			if (boyfriend.otherCharacters == null) {
				if (boyfriend.coolTrail != null)
					PlayState.instance.add(boyfriend.coolTrail);

				PlayState.instance.add(boyfriend);
			} else {
				for (character in boyfriend.otherCharacters) {
					if (character.coolTrail != null)
						PlayState.instance.add(character.coolTrail);

					PlayState.instance.add(character);
				}
			}

			lua_Sprites.remove("boyfriend");

			oldBF.kill();
			oldBF.destroy();

			lua_Sprites.set("boyfriend", boyfriend);

			@:privateAccess
			{
				var oldIcon = PlayState.instance.iconP1;
				var bar = PlayState.instance.healthBar;

				PlayState.instance.remove(oldIcon);
				oldIcon.kill();
				oldIcon.destroy();

				PlayState.instance.iconP1 = new HealthIcon(boyfriend.icon, false);
				PlayState.instance.iconP1.y = PlayState.instance.healthBar.y - (PlayState.instance.iconP1.height / 2);
				PlayState.instance.iconP1.cameras = [PlayState.instance.camHUD];
				PlayState.instance.iconP1.flipX = true;
				PlayState.instance.add(PlayState.instance.iconP1);

				bar.createFilledBar(PlayState.dad.barColor, boyfriend.barColor);
				bar.updateFilledBar();

				PlayState.instance.stage.setCharOffsets();
			}
		});

		// scroll speed

		var original_Scroll_Speed = PlayState.SONG.speed;

		setLuaFunction("getBaseScrollSpeed", function() {
			return original_Scroll_Speed;
		});

		setLuaFunction("getScrollSpeed", function() {
			return PlayState.SONG.speed;
		});

		setLuaFunction("setScrollSpeed", function(speed:Float) {
			PlayState.SONG.speed = speed;
		});

		// sounds

		setLuaFunction("createSound", function(id:String, file_Path:String, library:String, ?looped:Bool = false) {
			if (lua_Sounds.get(id) == null) {
				lua_Sounds.set(id, new FlxSound().loadEmbedded(Paths.sound(file_Path, library), looped));
				FlxG.sound.list.add(lua_Sounds.get(id));
			} else
				trace("Error! Sound " + id + " already exists! Try another sound name!");
		});

		setLuaFunction("removeSound", function(id:String) {
			if (lua_Sounds.get(id) != null) {
				FlxG.sound.list.remove(lua_Sounds.get(id));

				var sound = lua_Sounds.get(id);
				sound.stop();
				sound.kill();
				sound.destroy();

				lua_Sounds.set(id, null);
			}
		});

		setLuaFunction("playSound", function(id:String, ?forceRestart:Bool = false) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).play(forceRestart);
		});

		setLuaFunction("stopSound", function(id:String) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).stop();
		});

		setLuaFunction("setSoundVolume", function(id:String, volume:Float) {
			if (lua_Sounds.get(id) != null)
				lua_Sounds.get(id).volume = volume;
		});

		setLuaFunction("getSoundTime", function(id:String) {
			if (lua_Sounds.get(id) != null)
				return lua_Sounds.get(id).time;

			return 0;
		});

		// tweens

		setLuaFunction("tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenPos", function(id:String, toX:Int, toY:Int, time:Float, ?onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.linear,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.quintInOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.cubeOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenCameraZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance, {defaultCamZoom: toZoom}, time, {
				ease: FlxEase.quintInOut,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String = "") {
			FlxTween.tween(PlayState.instance, {defaultHudCamZoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) {
					if (onComplete != '' && onComplete != null) {
						callLua(onComplete, ["camera"]);
					}
				}
			});
		});

		setLuaFunction("tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
					ease: FlxEase.cubeIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenFadeOut", function(id:String, toAlpha:Float, time:Float, onComplete:String = "") {
			if (getActorByName(id) != null)
				FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
					ease: FlxEase.circOut,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
		});

		setLuaFunction("tweenActorColor", function(id:String, r1:Int, g1:Int, b1:Int, r2:Int, g2:Int, b2:Int, time:Float, onComplete:String = "") {
			var actor = getActorByName(id);

			if (getActorByName(id) != null) {
				FlxTween.color(actor, time, FlxColor.fromRGB(r1, g1, b1, 255), FlxColor.fromRGB(r2, g2, b2, 255), {
					ease: FlxEase.circIn,
					onComplete: function(flxTween:FlxTween) {
						if (onComplete != '' && onComplete != null) {
							callLua(onComplete, [id]);
						}
					}
				});
			}
		});

		// properties

		setLuaFunction("set", function(property:Dynamic, value:Dynamic):Void {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = getActorByName(seperated_path[0]);
			var property:String = property;

			for (i in 1...seperated_path.length) {
				if (i < seperated_path.length - 1) {
					if (seperated_path[i].contains('[')) {
						var array = seperated_path[i].substr(0, seperated_path[i].indexOf('['));
						object = Reflect.getProperty(object, array)[Std.parseInt(seperated_path[i].split(']')[0].split('[')[1])];
					} else
						object = Reflect.getProperty(object, seperated_path[i]);
				} else
					property = seperated_path[i];
			}

			if (seperated_path.length > 1) {
				Reflect.setProperty(object, property, value);
			} else {
				if (Reflect.getProperty(PlayState.instance, property) != null)
					Reflect.setProperty(PlayState.instance, property, value);
				else
					Reflect.setProperty(PlayState, property, value);
			}
		});

		setLuaFunction("get", function(property:Dynamic):Dynamic {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = getActorByName(seperated_path[0]);
			var property:String = property;

			for (i in 1...seperated_path.length) {
				if (i < seperated_path.length - 1)
					object = Reflect.getProperty(object, seperated_path[i]);
				else
					property = seperated_path[i];
			}

			if (seperated_path.length > 1) {
				return Reflect.getProperty(object, property);
			} else {
				if (Reflect.getProperty(PlayState.instance, property) != null)
					return Reflect.getProperty(PlayState.instance, property);
				else
					return Reflect.getProperty(PlayState, property);
			}
		});

		setLuaFunction("setClass", function(class_name:String, property:Dynamic, value:Dynamic):Void {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = Type.resolveClass(class_name);
			var property:String = property;

			for (i in 1...seperated_path.length) {
				if (i < seperated_path.length - 1) {
					if (seperated_path[i].contains('[')) {
						var array = seperated_path[i].substr(0, seperated_path[i].indexOf('['));
						object = Reflect.getProperty(object, array)[Std.parseInt(seperated_path[i].split(']')[0].split('[')[1])];
					} else
						object = Reflect.getProperty(object, seperated_path[i]);
				} else
					property = seperated_path[i];
			}

			Reflect.setProperty(object != Type.resolveClass(class_name) ? object : Type.resolveClass(class_name), property, value);
		});

		setLuaFunction("getClass", function(class_name:String, property:Dynamic):Dynamic {
			var seperated_path:Array<String> = property.split('.');
			var object:Dynamic = Type.resolveClass(class_name);
			var property:String = property;

			if (seperated_path.length > 1) {
				for (i in 0...seperated_path.length) {
					if (i < seperated_path.length - 1)
						object = Reflect.getProperty(object, seperated_path[i]);
					else
						property = seperated_path[i];
				}
			}

			return Reflect.getProperty(object != Type.resolveClass(class_name) ? object : Type.resolveClass(class_name), property);
		});

		setLuaFunction("setProperty", function(object:String, property:String, value:Dynamic) {
			if (object != "") {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, object) != null)
					Reflect.setProperty(Reflect.getProperty(PlayState.instance, object), property, value);
				else
					Reflect.setProperty(Reflect.getProperty(PlayState, object), property, value);
			} else {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, property) != null)
					Reflect.setProperty(PlayState.instance, property, value);
				else
					Reflect.setProperty(PlayState, property, value);
			}
		});

		setLuaFunction("getProperty", function(object:String, property:String) {
			if (object != "") {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, object) != null)
					return Reflect.getProperty(Reflect.getProperty(PlayState.instance, object), property);
				else
					return Reflect.getProperty(Reflect.getProperty(PlayState, object), property);
			} else {
				@:privateAccess
				if (Reflect.getProperty(PlayState.instance, property) != null)
					return Reflect.getProperty(PlayState.instance, property);
				else
					return Reflect.getProperty(PlayState, property);
			}
		});

		setLuaFunction("getPropertyFromClass", function(className:String, variable:String) {
			@:privateAccess
			{
				var variablePaths = variable.split(".");

				if (variablePaths.length > 1) {
					var selectedVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), variablePaths[0]);

					for (i in 1...variablePaths.length - 1) {
						selectedVariable = Reflect.getProperty(selectedVariable, variablePaths[i]);
					}

					return Reflect.getProperty(selectedVariable, variablePaths[variablePaths.length - 1]);
				}

				return Reflect.getProperty(Type.resolveClass(className), variable);
			}
		});

		setLuaFunction("setPropertyFromClass", function(className:String, variable:String, value:Dynamic) {
			@:privateAccess
			{
				var variablePaths:Array<String> = variable.split('.');

				if (variablePaths.length > 1) {
					var selectedVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), variablePaths[0]);

					for (i in 1...variablePaths.length - 1) {
						selectedVariable = Reflect.getProperty(selectedVariable, variablePaths[i]);
					}

					return Reflect.setProperty(selectedVariable, variablePaths[variablePaths.length - 1], value);
				}

				return Reflect.setProperty(Type.resolveClass(className), variable, value);
			}
		});

		// song stuff

		setLuaFunction("setSongPosition", function(position:Float) {
			Conductor.songPosition = position;
			setVar('songPos', Conductor.songPosition);
		});

		setLuaFunction("stopSong", function() {
			@:privateAccess
			{
				PlayState.instance.paused = true;

				FlxG.sound.music.volume = 0;
				PlayState.instance.vocals.volume = 0;

				PlayState.instance.notes.clear();
				PlayState.instance.remove(PlayState.instance.notes);

				FlxG.sound.music.time = 0;
				PlayState.instance.vocals.time = 0;

				Conductor.songPosition = 0;
				PlayState.songMultiplier = 0;

				Conductor.recalculateStuff(PlayState.songMultiplier);

				FlxG.sound.music.pitch = PlayState.songMultiplier;

				if (PlayState.instance.vocals.playing)
					PlayState.instance.vocals.pitch = PlayState.songMultiplier;

				PlayState.instance.stopSong = true;
			}

			return true;
		});

		setLuaFunction("endSong", function() {
			@:privateAccess
			{
				FlxG.sound.music.time = FlxG.sound.music.length;
				PlayState.instance.vocals.time = FlxG.sound.music.length;

				PlayState.instance.health = 500000;
				PlayState.instance.invincible = true;

				PlayState.instance.stopSong = false;

				PlayState.instance.resyncVocals();
			}

			return true;
		});

		setLuaFunction("getCharFromEvent", function(eventId:String) {
			switch (eventId.toLowerCase()) {
				case "girlfriend" | "gf" | "player3" | "2":
					return "girlfriend";
				case "dad" | "opponent" | "player2" | "1":
					return "dad";
				case "bf" | "boyfriend" | "player" | "player1" | "0":
					return "boyfriend";
			}

			return eventId;
		});

		setLuaFunction("charFromEvent", function(id:String) {
			switch (id.toLowerCase()) {
				case "girlfriend" | "gf" | "player3" | "2":
					return "girlfriend";
				case "dad" | "opponent" | "player2" | "1":
					return "dad";
				case "bf" | "boyfriend" | "player" | "player1" | "0":
					return "boyfriend";
			}

			return id;
		});

		// shader bullshit

		setLuaFunction("setActor3DShader", function(id:String, ?speed:Float = 3, ?frequency:Float = 10, ?amplitude:Float = 0.25) {
			var actor = getActorByName(id);

			if (actor != null) {
				var funnyShader:shaders.Shaders.ThreeDEffect = shaders.Shaders.newEffect("3d");
				funnyShader.waveSpeed = speed;
				funnyShader.waveFrequency = frequency;
				funnyShader.waveAmplitude = amplitude;
				lua_Shaders.set(id, funnyShader);

				actor.shader = funnyShader.shader;
			}
		});

		setLuaFunction("setActorNoShader", function(id:String) {
			var actor = getActorByName(id);

			if (actor != null) {
				lua_Shaders.remove(id);
				actor.shader = null;
			}
		});

		setLuaFunction("createCustomShader", function(id:String, file:String, glslVersion:Int = 120	){
			var funnyCustomShader:CustomShader = new CustomShader(Assets.getText(Paths.frag(file)));
			lua_Custom_Shaders.set(id, funnyCustomShader);
		});

		setLuaFunction("setActorCustomShader", function(id:String, actor:String){
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			lua_Custom_Shaders.set(id, funnyCustomShader);
			getActorByName(actor).shader = funnyCustomShader;
		});

		setLuaFunction("setActorNoCustomShader", function(actor:String){
			getActorByName(actor).shader = null;
		});

		setLuaFunction("setCameraCustomShader", function(id:String, camera:String){
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			lua_Custom_Shaders.set(id, funnyCustomShader);
			cameraFromString(camera).setFilters([new ShaderFilter(funnyCustomShader)]);
		});

		setLuaFunction("setCameraNoCustomShader", function(camera:String){
			cameraFromString(camera).setFilters(null);
		});

		setLuaFunction("getCustomShaderBool", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getBool(property);
		});

		setLuaFunction("getCustomShaderInt", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getInt(property);
		});

		setLuaFunction("getCustomShaderFloat", function(id:String, property:String) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			return funnyCustomShader.getFloat(property);
		});

		setLuaFunction("setCustomShaderBool", function(id:String, property:String, value:Bool) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setBool(property, value);
		});
		
		setLuaFunction("setCustomShaderInt", function(id:String, property:String, value:Int) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setInt(property, value);
		});

		setLuaFunction("setCustomShaderFloat", function(id:String, property:String, value:Float) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setFloat(property, value);
		});

		setLuaFunction("tweenCustomShaderInt", function(id:String, property:String, value:Int, time:Float) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			funnyCustomShader.setInt(property, value);
		});

		setLuaFunction("tweenCustomShaderFloat", function(id:String, shaderProperty:String, value:Float, time:Float, ?ease:String = "linear", ?onComplete:Dynamic) {
			var funnyCustomShader:CustomShader = lua_Custom_Shaders.get(id);
			FlxTween.tween(funnyCustomShader, {shaderProperty: value}, time, {
				ease: easeFromString(ease),
				onComplete: function(twn) {
					if (onComplete != null)
						onComplete();
				}
			});
		});
		
		setLuaFunction("updateRating", function() {
			PlayState.instance.updateRating();
		});

		setLuaFunction("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			cancelTimer(tag);
			PlayState.instance.luaTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.luaTimers.remove(tag);
				}
				PlayState.instance.executeALuaState('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
				//trace('Timer Completed: ' + tag);
			}, loops));
		});
		setLuaFunction("cancelTimer", function(tag:String) {
			cancelTimer(tag);
		});

		#if MODCHARTING_TOOLS
		if (PlayState.SONG.modchartingTools){
			setLuaFunction('startMod', function(name:String, modClass:String, type:String = '', pf:Int = -1){
				ModchartFuncs.startMod(name,modClass,type,pf);

				PlayState.instance.playfieldRenderer.modifierTable.reconstructTable(); //needs to be reconstructed for lua modcharts
			});
			setLuaFunction('setMod', function(name:String, value:Float){
				ModchartFuncs.setMod(name, value);
			});
			setLuaFunction('setSubMod', function(name:String, subValName:String, value:Float){
				ModchartFuncs.setSubMod(name, subValName,value);
			});
			setLuaFunction('setModTargetLane', function(name:String, value:Int){
				ModchartFuncs.setModTargetLane(name, value);
			});
			setLuaFunction('setModPlayfield', function(name:String, value:Int){
				ModchartFuncs.setModPlayfield(name,value);
			});
			setLuaFunction('addPlayfield', function(?x:Float = 0, ?y:Float = 0, ?z:Float = 0){
				ModchartFuncs.addPlayfield(x,y,z);
			});
			setLuaFunction('removePlayfield', function(idx:Int){
				ModchartFuncs.removePlayfield(idx);
			});
			setLuaFunction('tweenModifier', function(modifier:String, val:Float, time:Float, ease:String){
				ModchartFuncs.tweenModifier(modifier,val,time,ease);
			});
			setLuaFunction('tweenModifierSubValue', function(modifier:String, subValue:String, val:Float, time:Float, ease:String){
				ModchartFuncs.tweenModifierSubValue(modifier,subValue,val,time,ease);
			});
			setLuaFunction('setModEaseFunc', function(name:String, ease:String){
				ModchartFuncs.setModEaseFunc(name,ease);
			});
			setLuaFunction('setMod', function(beat:Float, argsAsString:String){
				ModchartFuncs.set(beat, argsAsString);
			});
			setLuaFunction('easeMod', function(beat:Float, time:Float, easeStr:String, argsAsString:String){

				ModchartFuncs.ease(beat, time, easeStr, argsAsString);
				
			});
			setLuaFunction('ease', function(beat:Float, time:Float, easeStr:String, argsAsString:String){

				ModchartFuncs.ease(beat, time, easeStr, argsAsString);
				
			});
		}
		#end

		executeState("onCreate", []);
		executeState("createLua", []);
		executeState("new", []);
	}

	public function setupTheShitCuzPullRequestsSuck() {
		lua_Sprites.set("boyfriend", PlayState.boyfriend);
		lua_Sprites.set("girlfriend", PlayState.gf);
		lua_Sprites.set("dad", PlayState.dad);

		lua_Characters.set("boyfriend", PlayState.boyfriend);
		lua_Characters.set("girlfriend", PlayState.gf);
		lua_Characters.set("dad", PlayState.dad);

		lua_Sounds.set("Inst", FlxG.sound.music);
		@:privateAccess
		lua_Sounds.set("Voices", PlayState.instance.vocals);

		@:privateAccess
		for (object in PlayState.instance.stage.stage_Objects) {
			lua_Sprites.set(object[0], object[1]);
		}

		if (PlayState.dad.otherCharacters != null) {
			for (char in 0...PlayState.dad.otherCharacters.length) {
				lua_Sprites.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
				lua_Characters.set("dadCharacter" + char, PlayState.dad.otherCharacters[char]);
			}
		}

		if (PlayState.boyfriend.otherCharacters != null) {
			for (char in 0...PlayState.boyfriend.otherCharacters.length) {
				lua_Sprites.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
				lua_Characters.set("bfCharacter" + char, PlayState.boyfriend.otherCharacters[char]);
			}
		}

		if (PlayState.gf.otherCharacters != null) {
			for (char in 0...PlayState.gf.otherCharacters.length) {
				lua_Sprites.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
				lua_Characters.set("gfCharacter" + char, PlayState.gf.otherCharacters[char]);
			}
		}

		if (PlayState.instance != null) {
			for (i in 0...PlayState.strumLineNotes.length) {
				lua_Sprites.set("defaultStrum" + i, PlayState.strumLineNotes.members[i]);

				if (PlayState.enemyStrums.members.contains(PlayState.strumLineNotes.members[i])) {
					lua_Sprites.set("enemyStrum" + i % PlayState.SONG.keyCount, PlayState.strumLineNotes.members[i]);
				} else {
					lua_Sprites.set("playerStrum" + i % PlayState.SONG.playerKeyCount, PlayState.strumLineNotes.members[i]);
				}
			}
		}

		for (script in extra_scripts) {
			script.setupTheShitCuzPullRequestsSuck();
		}
	}

	private function convert(v:Any, type:String):Dynamic { // I didn't write this lol
		if (Std.isOfType(v, String) && type != null) {
			var v:String = v;

			if (type.substr(0, 4) == 'array') {
				if (type.substr(4) == 'float') {
					var array:Array<String> = v.split(',');
					var array2:Array<Float> = new Array();

					for (vars in array) {
						array2.push(Std.parseFloat(vars));
					}

					return array2;
				} else if (type.substr(4) == 'int') {
					var array:Array<String> = v.split(',');
					var array2:Array<Int> = new Array();

					for (vars in array) {
						array2.push(Std.parseInt(vars));
					}

					return array2;
				} else {
					var array:Array<String> = v.split(',');

					return array;
				}
			} else if (type == 'float') {
				return Std.parseFloat(v);
			} else if (type == 'int') {
				return Std.parseInt(v);
			} else if (type == 'bool') {
				if (v == 'true') {
					return true;
				} else {
					return false;
				}
			} else {
				return v;
			}
		} else {
			return v;
		}
	}

	public function getVar(var_name:String, type:String):Dynamic {
		var result:Any = null;

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
			return null;
		else {
			var new_result = convert(result, type);
			return new_result;
		}
	}

	public function executeState(name, args:Array<Dynamic>) {
		for (script in extra_scripts) {
			script.executeState(name, args);
		}

		return Lua.tostring(lua, callLua(name, args));
	}

	function cameraFromString(cam:String):FlxCamera {
		switch (cam.toLowerCase()) {
			case 'camhud' | 'hud':
				return PlayState.instance.camHUD;
		}

		return PlayState.instance.camGame;
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.luaTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.luaTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.luaTimers.remove(tag);
		}
	}

	@:access(openfl.display.BlendMode)
	function blendModeFromString(blend:String):BlendMode {
		return BlendMode.fromString(blend.toLowerCase());
	}


	public static function easeFromString(?ease:String = ''):Float->Float {
		switch (ease.toLowerCase().trim()) {
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}

		return FlxEase.linear;
	}
}
#end
