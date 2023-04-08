package modding.scripts.lua;

import openfl.display.BlendMode;
import states.PlayState;
import flixel.FlxCamera;

using StringTools;

/**
    Any Script in the game that uses the `Lua` programming language.

    @author Leather128
**/
class LuaScript extends Script
{
    override public function call(func:String, ?arguments:Array<Dynamic>):Null<Bool>
    {
        // idfk

        return true;
    }

    override public function set(variable:String, value:Dynamic):Null<Bool>
    {
        // idfk

        return true;
    }

    override public function setup_enviroment():Null<Bool>
    {
        // idfk

        return true;
    }

    /**
        Returns the correct camera from PlayState based on the string `cam`.

        @author Leather128

        @param cam String representation of the camera being returned.
    **/
    public static function camera(cam:String):FlxCamera
        return cam.toLowerCase().endsWith("hud") ? PlayState.instance.camHUD : PlayState.instance.camGame;

    /**
        Returns the correct blend mode based on the string `blend`.    

        @author Leather128

        @param blend String representation of the blend mode being returned.
    **/
    public static function blend_mode(blend:String):BlendMode
    {
        @:privateAccess
        var mode:BlendMode = BlendMode.fromString(blend.toLowerCase().trim());

        if (mode != null)
            return mode;
        else
            return NORMAL;
    }
}