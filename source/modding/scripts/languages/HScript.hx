package modding.scripts.languages;

import states.PlayState;
import openfl.utils.Assets;
import flixel.FlxG;
import hscript.Parser;
import hscript.Expr;
import hscript.Interp;

/**
	Handles HScript for you.

	@author Leather128
**/
class HScript
{
	/**
		Parses the HScript.

		@author Leather128
	**/
	public var parser:Parser = new Parser();

	/**
		Current Expression.

		@author Leather128
	**/
	public var program:Expr;

	/**
		Interprets the HScript.

		@author Leather128
	**/
	public var interp:Interp = new Interp();

	/**
		Array of other scripts to call functions from (that were loaded from the script).

		@author Leather128
	**/
	public var other_scripts:Array<HScript> = [];

	/**
		`Bool` representation for if the `createPost` function has been called yet (used in the `load` function).

		@author Leather128
	**/
	public var create_post:Bool = false;

	public function new(hscript_path:String, ?global:Bool = false)
	{
		// parser settings
		parser.allowJSON = true;
		parser.allowTypes = true;
		parser.allowMetadata = true;
		
		// load text
		#if sys
		//Shoutout to @sword_352 on discord for helping my dumbass brain with this
		if(global)
			program = parser.parseString(sys.io.File.getContent(hscript_path));
		else
		#end
			program = parser.parseString(Assets.getText(hscript_path));

		set_default_vars();

		interp.execute(program);
	}

	public function start()
		call("create");

	public function update(elapsed:Float)
		call("update", [elapsed]);

	public function call(func:String, ?args:Array<Dynamic>)
	{
		if (interp.variables.exists(func))
		{
			var real_func = interp.variables.get(func);

			try
			{
				if (args == null)
					real_func();
				else
					Reflect.callMethod(null, real_func, args);
			}
			catch (e)
			{
				trace(e.details());
				trace("ERROR Caused in " + func + " with " + Std.string(args) + " args");
			}
		}

		for (other_script in other_scripts)
		{
			other_script.call(func, args);
		}
	}

	public function set_default_vars()
	{
		// global class shit

		// haxeflixel classes
		interp.variables.set("FlxG", flixel.FlxG);
		interp.variables.set("FlxSprite", flixel.FlxSprite);
		interp.variables.set("FlxSound", flixel.sound.FlxSound);
		interp.variables.set('FlxCamera', flixel.FlxCamera);
		interp.variables.set("FlxMath", flixel.math.FlxMath);
		interp.variables.set('FlxTimer', flixel.util.FlxTimer);
		interp.variables.set('FlxTween', flixel.tweens.FlxTween);
		interp.variables.set('FlxColor', modding.helpers.FlxColorHelper);
		interp.variables.set('FlxEase', flixel.tweens.FlxEase);
		interp.variables.set("Polymod", polymod.Polymod);
		interp.variables.set("Assets", openfl.utils.Assets);
		interp.variables.set("LimeAssets", lime.utils.Assets);
		interp.variables.set("Math", Math);
		interp.variables.set("Std", Std);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
		interp.variables.set("CustomShader", shaders.custom.CustomShader);
		interp.variables.set("FlxShader", flixel.system.FlxAssets.FlxShader);
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('FlxAnimate', flxanimate.FlxAnimate);
		interp.variables.set('Json', haxe.Json);
		interp.variables.set("FlxEmitter", flixel.effects.particles.FlxEmitter);

		// game classes
		interp.variables.set("PlayState", states.PlayState);
		interp.variables.set("Conductor", game.Conductor);
		interp.variables.set("Paths", Paths);
		interp.variables.set("CoolUtil", utilities.CoolUtil);
		interp.variables.set('Options', utilities.Options);
		interp.variables.set('Character', game.Character);
		interp.variables.set('Alphabet', ui.Alphabet);
		interp.variables.set('ModList', modding.ModList);
		interp.variables.set('CustomState', modding.custom.CustomState);
		#if discord_rpc
		interp.variables.set('Discord', utilities.Discord.DiscordClient);
		#end
		#if THREE_D_ALLOWED
		interp.variables.set('Model', models.Model);
		interp.variables.set('FlxView3D', flx3D.FlxView3D);
        interp.variables.set('Mesh', away3d.entities.Mesh);
        interp.variables.set('ControllerBase', away3d.controllers.ControllerBase);
        interp.variables.set('FirstPersonController', away3d.controllers.FirstPersonController);
        interp.variables.set('HoverController', away3d.controllers.HoverController);
		interp.variables.set('MotionBlurFilter3D', away3d.filters.MotionBlurFilter3D);
		interp.variables.set('BloomFilter3D', away3d.filters.BloomFilter3D);
		interp.variables.set('DepthOfFieldFilter3D', away3d.filters.DepthOfFieldFilter3D);
		interp.variables.set('TorusGeometry', away3d.primitives.TorusGeometry);
		interp.variables.set('CubeGeometry', away3d.primitives.CubeGeometry);
		interp.variables.set('ObjectContainer3D', away3d.containers.ObjectContainer3D);
		interp.variables.set('ControllerBase', away3d.controllers.ControllerBase);
		interp.variables.set('FirstPersonController', away3d.controllers.FirstPersonController);
		interp.variables.set('HoverController', away3d.controllers.HoverController);
		interp.variables.set('Mesh', away3d.entities.Mesh);
		interp.variables.set('Scene3D', models.Scene3D);
		#end

		//modchart tools stuff
		#if MODCHARTING_TOOLS
		if (FlxG.state == PlayState.instance){
			interp.variables.set('PlayfieldRenderer', modcharting.PlayfieldRenderer);
			interp.variables.set('ModchartUtil', modcharting.ModchartUtil);
			interp.variables.set('Modifier', modcharting.Modifier);
			interp.variables.set('NoteMovement', modcharting.NoteMovement);
			interp.variables.set('NotePositionData', modcharting.NotePositionData);
			interp.variables.set('ModchartFile', modcharting.ModchartFile);
		}
		#end
		// function shits

	    interp.variables.set("import", function(class_name:String) {
			var classes = class_name.split(".");
	
			if(Type.resolveClass(class_name) != null)
				interp.variables.set(classes[classes.length - 1], Type.resolveClass(class_name));
			else if(Type.resolveEnum(class_name) != null)
			{
				var enum_new = {};
				var good_enum = Type.resolveEnum(class_name);
	
				for(constructor in good_enum.getConstructors())
				{
					Reflect.setField(enum_new, constructor, good_enum.createByName(constructor));
				}
	
				interp.variables.set(classes[classes.length - 1], enum_new);
			}
			else
				trace(class_name + " isn't a valid class or enum!");
		});

		interp.variables.set("trace", function(value:Dynamic)
		{
			#if sys
			Sys.println(value);
			#else
			trace(value);
			#end
		});

		interp.variables.set("load", function(script_path:String)
		{
			var new_script = new HScript(script_path);
			new_script.start();

			if (create_post)
				new_script.call("createPost");

			other_scripts.push(new_script);

			return other_scripts.length - 1;
		});

		interp.variables.set("unload", function(script_index:Int)
		{
			if (other_scripts.length - 1 >= script_index)
				other_scripts.remove(other_scripts[script_index]);
		});

		interp.variables.set("otherScripts", other_scripts);

		// playstate local shit
		interp.variables.set("bf", states.PlayState.boyfriend);
		interp.variables.set("gf", states.PlayState.gf);
		interp.variables.set("dad", states.PlayState.dad);

		interp.variables.set("removeStage", function()
		{
			states.PlayState.instance.stage.stage_Objects = [];

			states.PlayState.instance.stage.infrontOfGFSprites.clear();
			states.PlayState.instance.stage.foregroundSprites.clear();
			states.PlayState.instance.stage.clear();
		});
	}
}
