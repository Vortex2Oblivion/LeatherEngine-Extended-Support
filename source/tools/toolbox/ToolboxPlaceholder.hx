package tools.toolbox;

import states.MainMenuState;
import states.MusicBeatState;
import states.PlayState;
import utilities.Options;
import utilities.CoolUtil;
import substates.UISkinSelect;
import substates.ControlMenuSubstate;
import modding.CharacterCreationState;
import utilities.MusicUtilities;
import ui.Option;
import ui.Checkbox;
import flixel.group.FlxGroup;
import tools.ChartingState;
import tools.StageMakingState;
import flixel.sound.FlxSound;
import tools.CharacterCreator;
import utilities.Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import ui.Alphabet;
import game.Song;
import tools.StageMakingState;
import game.Highscore;
import openfl.utils.Assets as OpenFLAssets;
import tools.ChartingStateDev;

class ToolboxPlaceholder extends states.MusicBeatState {
	var curSelected:Int = 0;
	var ui_Skin:Null<String>;

	public static var inMenu = false;

	public var pages:Map<String, Array<Dynamic>> = [
		"Tools" => [
			new GameStateOption("Charter", 0, new ChartingState()),
			new CharacterCreatorOption("Character Creator", 1, new CharacterCreator("dad", "stage")),
			new GameStateOption("Stage Editor", 2, new StageMakingState("stage")),
			#if MODCHARTING_TOOLS
			new GameStateOption("Modchart Editor", 3, new modcharting.ModchartEditorState()),
			#end
			new GameSubstateOption("Import Old Scores", 4, substates.ImportHighscoresSubstate)
		]
	];

	public var page:FlxTypedGroup<Option> = new FlxTypedGroup<Option>();
	public static var instance:ToolboxPlaceholder;

	override function create():Void {
		if (ui_Skin == null || ui_Skin == "default")
			ui_Skin = Options.getData("uiSkin");

		if (PlayState.instance == null) {
			pages["Tools"][0] = null;
		}

		MusicBeatState.windowNameSuffix = "";
		instance = this;

		var menuBG:FlxSprite;

		if(Options.getData("menuBGs"))
			if (!Assets.exists(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuToolbox')))
				menuBG = new FlxSprite().loadGraphic(Paths.image('ui skins/default/backgrounds/menuToolbox'));
			else
				menuBG = new FlxSprite().loadGraphic(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuToolbox'));
		else
			menuBG = new FlxSprite().makeGraphic(1286, 730, FlxColor.fromString("#E1E1E1"), false, "optimizedMenuDesat");

		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();

		add(page);

		LoadPage("Tools");

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);
	}

	public static function LoadPage(Page_Name:String):Void {
		inMenu = true;
		instance.curSelected = 0;

		var curPage:FlxTypedGroup<Option> = instance.page;
		curPage.clear();

		for (x in instance.pages.get(Page_Name).copy()) {
			curPage.add(x);
		}

		inMenu = false;
		var bruh:Int = 0;

		for (x in instance.page.members) {
			x.Alphabet_Text.targetY = bruh - instance.curSelected;
			bruh++;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!inMenu) {
			if (-1 * Math.floor(FlxG.mouse.wheel) != 0) {
				curSelected -= 1 * Math.floor(FlxG.mouse.wheel);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.UP_P) {
				curSelected -= 1;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.DOWN_P) {
				curSelected += 1;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.BACK)
				FlxG.switchState(new MainMenuState());
		} else {
			if (controls.BACK)
				inMenu = false;
		}

		if (curSelected < 0)
			curSelected = page.length - 1;

		if (curSelected >= page.length)
			curSelected = 0;

		var bruh = 0;

		for (x in page.members) {
			x.Alphabet_Text.targetY = bruh - curSelected;
			bruh++;
		}

		for (x in page.members) {
			if (x.Alphabet_Text.targetY != 0) {
				for (item in x.members) {
					item.alpha = 0.6;
				}
			} else {
				for (item in x.members) {
					item.alpha = 1;
				}
			}
		}
	}
}
