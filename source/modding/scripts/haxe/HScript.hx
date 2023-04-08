package modding.scripts.haxe;

import openfl.utils.Assets;
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

	public function new(hscript_path:String)
	{
		// parser settings
		parser.allowJSON = true;
		parser.allowTypes = true;
		parser.allowMetadata = true;
		
		// load text
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
		interp.variables.set("Polymod", polymod.Polymod);
		interp.variables.set("Assets", openfl.utils.Assets);
		interp.variables.set("LimeAssets", lime.utils.Assets);
		interp.variables.set("FlxSprite", flixel.FlxSprite);
		interp.variables.set("Math", Math);
		interp.variables.set("Std", Std);
		interp.variables.set("StringTools", StringTools);

		// game classes
		interp.variables.set("PlayState", states.PlayState);
		interp.variables.set("Conductor", game.Conductor);
		interp.variables.set("Paths", Paths);
		interp.variables.set("CoolUtil", utilities.CoolUtil);

		// function shits
		interp.variables.set("trace", function(value:Dynamic)
		{
			trace(value);
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
