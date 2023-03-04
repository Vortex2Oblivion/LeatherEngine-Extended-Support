package debuggers;

import game.StageGroup;
import flixel.ui.FlxButton;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import ui.FlxUIDropDownMenuCustom;
import states.MusicBeatState;
import states.MainMenuState;
import states.PlayState;
import utilities.CoolUtil;
import game.Character;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

/**
	*DEBUG MODE
 */
class AnimationDebug extends MusicBeatState {
	var char:Character;
	var animText:FlxText;
	var moveText:FlxText;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;
	var _file:FileReference;

	public function new(daAnim:String = 'spooky', selectedStage:String) {
		super();
		this.daAnim = daAnim;
		stages = CoolUtil.coolTextFile(Paths.txt('stageList'));

		if (selectedStage != null)
			stage_Name = selectedStage;
	}

	var characters:Map<String, Array<String>> = ["default" => ["bf", "gf"]];

	var modListLmao:Array<String> = ["default"];
	var curCharList:Array<String>;

	var offset_Button:FlxButton;
	var charDropDown:FlxUIDropDownMenuCustom;
	var modDropDown:FlxUIDropDownMenuCustom;

	var gridBG:FlxSprite;

	/* CAMERA */
	var gridCam:FlxCamera;
	var charCam:FlxCamera;
	var camHUD:FlxCamera;

	/*STAGE*/
	var stage:StageGroup;
	var stagePosition:FlxSprite;

	public var stages:Array<String>;
	public var stage_Name:String = 'stage';
	public var stageData:StageData;
	
	private var stage_Dropdown:FlxUIDropDownMenuCustom;
	private var objects:Array<Array<Dynamic>> = [];




	override function create() {
		FlxG.mouse.visible = true;

		gridCam = new FlxCamera();
		charCam = new FlxCamera();
		charCam.bgColor.alpha = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset();
		FlxG.cameras.add(gridCam, false);
		FlxG.cameras.add(charCam, true);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(charCam, true);

		FlxG.camera = charCam;

		if (FlxG.sound.music.active)
			FlxG.sound.music.stop();

		reloadStage();

		gridBG = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0, 0);
		gridBG.cameras = [gridCam];
		add(gridBG);



		stagePosition = new FlxSprite().makeGraphic(32, 32, 0xFFFF0000);
		add(stagePosition);

		char = new Character(0, 0, daAnim);
		char.debugMode = true;
		add(char);

		animText = new FlxText(4, 4, 0, "BRUH BRUH BRUH: [0,0]", 20);
		animText.font = Paths.font("vcr.ttf");
		animText.scrollFactor.set();
		animText.color = FlxColor.WHITE;
		animText.borderColor = FlxColor.BLACK;
		animText.borderStyle = OUTLINE;
		animText.borderSize = 2;
		animText.cameras = [camHUD];
		add(animText);

		moveText = new FlxText(4, 4, 0, "", 20);
		moveText.font = Paths.font("vcr.ttf");
		moveText.x = FlxG.width - moveText.width - 4;
		moveText.scrollFactor.set();
		moveText.color = FlxColor.WHITE;
		moveText.borderColor = FlxColor.BLACK;
		moveText.borderStyle = OUTLINE;
		moveText.borderSize = 2;
		moveText.alignment = RIGHT;
		moveText.cameras = [camHUD];
		add(moveText);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.sound.playMusic(Paths.music('breakfast'));

		charCam.follow(camFollow);

		var characterData:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
		char.setPosition(position[0], position[1]);

		if (char.isPlayer)
			stagePosition.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
		else
			stagePosition.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

		for (item in characterData) {
			var characterDataVal:Array<String> = item.split(":");

			var charName:String = characterDataVal[0];
			var charMod:String = characterDataVal[1];

			var charsLmao:Array<String> = [];

			if (characters.exists(charMod))
				charsLmao = characters.get(charMod);
			else
				modListLmao.push(charMod);

			charsLmao.push(charName);
			characters.set(charMod, charsLmao);
		}

		curCharList = characters.get("default");

		charDropDown = new FlxUIDropDownMenuCustom(10, 500, FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true), function(character:String) {
			remove(char);
			char.kill();
			char.destroy();

			daAnim = curCharList[Std.parseInt(character)];
			char = new Character(0, 0, daAnim);
			char.debugMode = true;
			add(char);

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);

			if (char.isPlayer)
				stagePosition.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
			else
				stagePosition.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

			animList = [];
			genBoyOffsets(true);
		});

		charDropDown.selectedLabel = daAnim;
		charDropDown.scrollFactor.set();
		charDropDown.cameras = [camHUD];
		add(charDropDown);

		modDropDown = new FlxUIDropDownMenuCustom(charDropDown.x + charDropDown.width + 1, charDropDown.y,
			FlxUIDropDownMenu.makeStrIdLabelArray(modListLmao, true), function(modID:String) {
				var mod:String = modListLmao[Std.parseInt(modID)];

				if (characters.exists(mod)) {
					curCharList = characters.get(mod);
					charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(curCharList, true));
					charDropDown.selectedLabel = curCharList[0];

					remove(char);
					char.kill();
					char.destroy();

					daAnim = curCharList[0];
					char = new Character(0, 0, daAnim);
					char.debugMode = true;
					add(char);
					
					var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
					char.setPosition(position[0], position[1]);
			
					if (char.isPlayer)
						stagePosition.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
					else
						stagePosition.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

					animList = [];
					genBoyOffsets(true);
				}
		});

		modDropDown.selectedLabel = "default";
		modDropDown.scrollFactor.set();
		modDropDown.cameras = [camHUD];
		add(modDropDown);


		stage_Dropdown = new FlxUIDropDownMenuCustom(modDropDown.x + modDropDown.width + 1, modDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true),
		function(stageName:String) {

			
			stage_Name = stages[Std.parseInt(stageName)];
			reloadStage();
			remove(char);
			char.kill();
			char.destroy();

			daAnim = curCharList[0];
			char = new Character(0, 0, daAnim);
			char.debugMode = true;
			add(char);

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);

			if (char.isPlayer)
				stagePosition.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
			else
				stagePosition.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

			animList = [];
			genBoyOffsets(true);
		});

		stage_Dropdown.selectedLabel = stage_Name;
		stage_Dropdown.scrollFactor.set();
		stage_Dropdown.cameras = [camHUD];
		add(stage_Dropdown);


		offset_Button = new FlxButton(charDropDown.x, charDropDown.y - 30, "Save Offsets", function() {
			saveOffsets();
		});
		offset_Button.scrollFactor.set();
		offset_Button.cameras = [camHUD];
		add(offset_Button);
		

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void {
		animText.text = "";

		for (anim => offsets in char.animOffsets) {
			if (pushList)
				animList.push(anim);

			animText.text += anim + (anim == animList[curAnim] ? " (current) " : "") + ": " + offsets + "\n";
		}

		if ((char.offsetsFlipWhenPlayer && char.isPlayer) || (char.offsetsFlipWhenEnemy && !char.isPlayer))
			animText.text += "(offsets flipped)";
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.E)
			charCam.zoom += FlxG.keys.pressed.SHIFT ? 0.01 : 0.1;
		if (FlxG.keys.justPressed.Q)
			charCam.zoom -= FlxG.keys.pressed.SHIFT ? 0.01 : 0.1;
		if (FlxG.mouse.wheel != 0)
			charCam.zoom += FlxG.keys.pressed.SHIFT ? FlxG.mouse.wheel / 100.0 : FlxG.mouse.wheel / 10.0;
		if (FlxG.keys.justPressed.Z)
			stage.visible = !stage.visible;
		if (FlxG.keys.justPressed.X) {
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;

			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
	
			if (char.isPlayer)
				stagePosition.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
			else
				stagePosition.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

			char.loadOffsetFile(char.curCharacter);
			char.playAnim(animList[curAnim], true);
			animList = [];
			genBoyOffsets(true);
		}

		var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 5 : 1;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L) {
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90 * shiftThing;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90 * shiftThing;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90 * shiftThing;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90 * shiftThing;
			else
				camFollow.velocity.x = 0;
		} else {
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W) {
			curAnim -= 1;
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new MainMenuState());

		if (FlxG.keys.justPressed.S) {
			curAnim += 1;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE) {
			char.playAnim(animList[curAnim], true);
			
			var position = stage.getCharacterPos(char.isPlayer ? 0 : 1, char);
			char.setPosition(position[0], position[1]);
	
			if (char.isPlayer)
				stagePosition.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
			else
				stagePosition.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

			genBoyOffsets(false);
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP) {
			if (upP)
				char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			if (downP)
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			if (leftP)
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			if (rightP)
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;

			genBoyOffsets(false);
			char.playAnim(animList[curAnim], true);
		}

		charCam.zoom = flixel.math.FlxMath.roundDecimal(charCam.zoom, 2) <= 0 ? 1 : charCam.zoom;
		moveText.text = 'Use IJKL to move the camera\nE and Q to zoom the camera\nSHIFT for faster moving offset or camera\nZ to toggle the stage\nX to toggle playing side\nCamera Zoom: ${flixel.math.FlxMath.roundDecimal(charCam.zoom, 2)}\n';
		moveText.x = FlxG.width - moveText.width - 4;

		super.update(elapsed);
	}

	function saveOffsets() {
		var offsetsText:String = "";
		var flipped = (char.offsetsFlipWhenPlayer && char.isPlayer) || (char.offsetsFlipWhenEnemy && !char.isPlayer);

		for (anim => offsets in char.animOffsets) {
			offsetsText += anim + " " + (flipped ? -offsets[0] : offsets[0]) + " " + offsets[1] + "\n";
		}

		if ((offsetsText != "") && (offsetsText.length > 0)) {
			if (offsetsText.endsWith("\n"))
				offsetsText = offsetsText.substr(0, offsetsText.length - 1);

			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			_file.save(offsetsText, "offsets.txt");
		}
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved OFFSETS FILE.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving offsets file");
	}
	function reloadStage() {
		objects = [];

		clear();

		add(camFollow);

		stage = new StageGroup(stage_Name);
		add(stage);

		@:privateAccess
		stageData = stage.stage_Data;

		add(stage.infrontOfGFSprites);


		add(stage.foregroundSprites);

		add(gridBG);

		add(stagePosition);

		add(char);

		add(animText);
		add(moveText);

		add(camFollow);

		add(modDropDown);
		add(charDropDown);
		add(stage_Dropdown);

		add(offset_Button);
	}
}
