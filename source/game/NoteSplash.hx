package game;

import utilities.NoteVariables;
import flixel.FlxG;
import states.PlayState;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
    public function new(x:Float = 0, y:Float = 0, noteData:Int) {
        super(x, y);

        alpha = 0.8;
        frames = PlayState.splash_Texture;

        var coolAnimRando:Int = FlxG.random.int(1,2);

        animation.addByPrefix("default", "note splash " + NoteVariables.Other_Note_Anim_Stuff[PlayState.SONG.keyCount - 1][noteData] + " " + coolAnimRando, 24 + FlxG.random.int(-2, 2), false);
        animation.play("default", true);

        setGraphicSize(Std.int((width * Std.parseFloat(PlayState.instance.splashesSettings[0])) * (Std.parseFloat(PlayState.instance.splashesSettings[2]) - ((PlayState.SONG.keyCount - 4) * 0.06))));
        updateHitbox();
    }

    override function update(elapsed:Float) {
        if(animation.curAnim.finished)
        {
            kill();
            alpha = 0;
        }

        super.update(elapsed);
    }
}