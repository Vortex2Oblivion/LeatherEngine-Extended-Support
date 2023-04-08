package game;

import animateatlas.AtlasFrameMaker;
import utilities.Options;
import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.util.FlxColor;
import lime.utils.Assets;
import haxe.Json;
import utilities.CoolUtil;
import states.PlayState;
import flixel.FlxSprite;
import modding.CharacterConfig;

using StringTools;

class Character extends FlxSprite {
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	public var animationNotes:Array<Dynamic> = [];

	public var dancesLeftAndRight:Bool = false;

	public var barColor:FlxColor = FlxColor.WHITE;
	public var positioningOffset:Array<Float> = [0, 0];
	public var cameraOffset:Array<Float> = [0, 0];

	public var otherCharacters:Array<Character>;

	public var offsetsFlipWhenPlayer:Bool = true;
	public var offsetsFlipWhenEnemy:Bool = false;

	public var coolTrail:FlxTrail;

	public var deathCharacter:String = "bf-dead";

	public var swapLeftAndRightSingPlayer:Bool = true;

	public var icon:String;

	public var isDeathCharacter:Bool = false;

	public var config:CharacterConfig;

	public var singDuration:Float = 4.0;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isDeathCharacter:Bool = false) {
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();

		curCharacter = character;
		this.isPlayer = isPlayer;
		this.isDeathCharacter = isDeathCharacter;

		antialiasing = true;

		dancesLeftAndRight = false;

		var ilikeyacutg:Bool = false;

		switch (curCharacter) {
			case 'bf-pixel-dead':
				swapLeftAndRightSingPlayer = false;

				frames = Paths.getSparrowAtlas('characters/bfPixelsDEAD');
				animation.addByPrefix('singUP', "BF Dies pixel", 24, false);
				animation.addByPrefix('firstDeath', "BF Dies pixel", 24, false);
				animation.addByPrefix('deathLoop', "Retry Loop", 24, true);
				animation.addByPrefix('deathConfirm', "RETRY CONFIRM", 24, false);

				playAnim('firstDeath');
				// pixel bullshit
				setGraphicSize(Std.int(width * 6));

				antialiasing = false;
				flipX = true;
				barColor = FlxColor.fromRGB(123, 214, 246);
			case 'senpai':
				frames = Paths.getSparrowAtlas('characters/senpai');
				animation.addByPrefix('idle', 'Senpai Idle', 24, false);
				animation.addByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				cameraOffset = [15, 0];
				positioningOffset = [317, 522];

				antialiasing = false;
				barColor = FlxColor.fromRGB(255, 170, 111);
			case 'senpai-angry':
				frames = Paths.getSparrowAtlas('characters/senpai');
				animation.addByPrefix('idle', 'Angry Senpai Idle', 24, false);
				animation.addByPrefix('singUP', 'Angry Senpai UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'Angry Senpai LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'Angry Senpai RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'Angry Senpai DOWN NOTE', 24, false);

				playAnim('idle');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				cameraOffset = [15, 0];
				positioningOffset = [317, 522];

				antialiasing = false;
				barColor = FlxColor.fromRGB(255, 170, 111);
			case 'spirit':
				frames = Paths.getPackerAtlas('characters/spirit');
				animation.addByPrefix('idle', "idle spirit_", 24, false);
				animation.addByPrefix('singUP', "up_", 24, false);
				animation.addByPrefix('singRIGHT', "right_", 24, false);
				animation.addByPrefix('singLEFT', "left_", 24, false);
				animation.addByPrefix('singDOWN', "spirit down_", 24, false);

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

				playAnim('idle');

				positioningOffset = [67, 122];

				antialiasing = false;
				barColor = FlxColor.fromRGB(255, 60, 110);

				coolTrail = new FlxTrail(this, null, 4, 24, 0.3, 0.069);
			case 'parents-christmas':
				frames = Paths.getSparrowAtlas('characters/mom_dad_christmas_assets');
				animation.addByPrefix('idle', 'Parent Christmas Idle', 24, false);
				animation.addByPrefix('singUP', 'Parent Up Note Dad', 24, false);
				animation.addByPrefix('singDOWN', 'Parent Down Note Dad', 24, false);
				animation.addByPrefix('singLEFT', 'Parent Left Note Dad', 24, false);
				animation.addByPrefix('singRIGHT', 'Parent Right Note Dad', 24, false);

				animation.addByPrefix('singUP-alt', 'Parent Up Note Mom', 24, false);

				animation.addByPrefix('singDOWN-alt', 'Parent Down Note Mom', 24, false);
				animation.addByPrefix('singLEFT-alt', 'Parent Left Note Mom', 24, false);
				animation.addByPrefix('singRIGHT-alt', 'Parent Right Note Mom', 24, false);

				playAnim('idle');
				barColor = FlxColor.fromRGB(199, 111, 211);
			case '':
				trace("NO VALUE THINGY LOL DONT LOAD SHIT");
				deathCharacter = "bf-dead";

			default:
				if (isPlayer)
					flipX = !flipX;

				ilikeyacutg = true;

				loadNamedConfiguration(curCharacter);
		}

		if (isPlayer && !ilikeyacutg)
			flipX = !flipX;

		if (icon == null)
			icon = curCharacter;

		// YOOOOOOOOOO POG MODDING STUFF
		if (character != "")
			loadOffsetFile(curCharacter);

		if (curCharacter != '' && otherCharacters == null && animation.curAnim != null) {
			updateHitbox();

			if (!debugMode) {
				dance();

				if (isPlayer) {
					// Doesn't flip for BF, since his are already in the right place???
					if (swapLeftAndRightSingPlayer && !isDeathCharacter) {
						var oldOffRight = animOffsets.get("singRIGHT");
						var oldOffLeft = animOffsets.get("singLEFT");

						// var animArray
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;

						animOffsets.set("singRIGHT", oldOffLeft);
						animOffsets.set("singLEFT", oldOffRight);

						// IF THEY HAVE MISS ANIMATIONS??
						if (animation.getByName('singRIGHTmiss') != null) {
							var oldOffRightMiss = animOffsets.get("singRIGHTmiss");
							var oldOffLeftMiss = animOffsets.get("singLEFTmiss");

							var oldMiss = animation.getByName('singRIGHTmiss').frames;
							animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
							animation.getByName('singLEFTmiss').frames = oldMiss;

							animOffsets.set("singRIGHTmiss", oldOffLeftMiss);
							animOffsets.set("singLEFTmiss", oldOffRightMiss);
						}
					}
				}
			}
		} else
			visible = false;
	}

	function loadNamedConfiguration(characterName:String) {
		if (!Assets.exists(Paths.json("character data/" + characterName + "/config"))) {
			characterName = "bf";
			curCharacter = characterName;
		}

		if (Options.getData("optimizedChars") && Assets.exists(Paths.json("character data/optimized_" + characterName + "/config")))
			characterName = "optimized_" + characterName;

		var rawJson = Assets.getText(Paths.json("character data/" + characterName + "/config")).trim();

		this.config = cast Json.parse(rawJson);

		loadCharacterConfiguration(this.config);
	}

	public function loadCharacterConfiguration(config:CharacterConfig) {
		if (config.characters == null || config.characters.length <= 1) {
			if (!isPlayer)
				flipX = config.defaultFlipX;
			else
				flipX = !config.defaultFlipX;

			if (config.offsetsFlipWhenPlayer == null) {
				if (curCharacter.startsWith("bf"))
					offsetsFlipWhenPlayer = false;
				else
					offsetsFlipWhenPlayer = true;
			} else
				offsetsFlipWhenPlayer = config.offsetsFlipWhenPlayer;

			if (config.offsetsFlipWhenEnemy == null) {
				if (curCharacter.startsWith("bf"))
					offsetsFlipWhenEnemy = true;
				else
					offsetsFlipWhenEnemy = false;
			} else
				offsetsFlipWhenEnemy = config.offsetsFlipWhenEnemy;

			dancesLeftAndRight = config.dancesLeftAndRight;

			if (Assets.exists(Paths.file("images/characters/" + config.imagePath + ".txt", TEXT)))
				frames = Paths.getPackerAtlas('characters/' + config.imagePath);
			else
				frames = Paths.getSparrowAtlas('characters/' + config.imagePath);

			var size:Null<Float> = config.graphicSize;

			if (size == null)
				size = config.graphicsSize;

			if (size != null)
				scale.set(size, size);

			for (selected_animation in config.animations) {
				if (selected_animation.indices != null && selected_animation.indices.length > 0) {
					animation.addByIndices(selected_animation.name, selected_animation.animation_name, selected_animation.indices, "", selected_animation.fps,
						selected_animation.looped);
				} else {
					animation.addByPrefix(selected_animation.name, selected_animation.animation_name, selected_animation.fps, selected_animation.looped);
				}
			}

			if (isDeathCharacter)
				playAnim("firstDeath");
			else {
				if (dancesLeftAndRight)
					playAnim("danceRight");
				else
					playAnim("idle");
			}

			if (debugMode)
				flipX = config.defaultFlipX;

			if (config.antialiasing != null)
				antialiasing = config.antialiasing;
			else if (config.antialiased != null)
				antialiasing = config.antialiased;

			updateHitbox();

			if (config.positionOffset != null)
				positioningOffset = config.positionOffset;

			if (config.trail == true)
				coolTrail = new FlxTrail(this, null, config.trailLength, config.trailDelay, config.trailStalpha, config.trailDiff);

			if (config.swapDirectionSingWhenPlayer != null)
				swapLeftAndRightSingPlayer = config.swapDirectionSingWhenPlayer;
			else if (curCharacter.startsWith("bf"))
				swapLeftAndRightSingPlayer = false;

			if (config.singDuration != null)
				singDuration = config.singDuration;
		} else {
			otherCharacters = [];

			for (characterData in config.characters) {
				var character:Character;

				if (!isPlayer)
					character = new Character(x, y, characterData.name, isPlayer, isDeathCharacter);
				else
					character = new Boyfriend(x, y, characterData.name, isDeathCharacter);

				if (flipX)
					characterData.positionOffset[0] = 0 - characterData.positionOffset[0];

				character.positioningOffset[0] += characterData.positionOffset[0];
				character.positioningOffset[1] += characterData.positionOffset[1];

				otherCharacters.push(character);
			}
		}

		if (config.barColor == null)
			config.barColor = [255, 0, 0];

		barColor = FlxColor.fromRGB(config.barColor[0], config.barColor[1], config.barColor[2]);

		if (config.cameraOffset != null) {
			if (flipX)
				config.cameraOffset[0] = 0 - config.cameraOffset[0];

			cameraOffset = config.cameraOffset;
		}

		if (config.deathCharacter != null)
			deathCharacter = config.deathCharacter;
		else if (config.deathCharacterName != null)
			deathCharacter = config.deathCharacterName;
		else
			deathCharacter = "bf-dead";

		if (config.healthIcon != null)
			icon = config.healthIcon;
	}

	public function loadOffsetFile(characterName:String) {
		animOffsets = new Map<String, Array<Dynamic>>();

		if (Assets.exists(Paths.txt("character data/" + characterName + "/" + "offsets"))) {
			var offsets:Array<String> = CoolUtil.coolTextFile(Paths.txt("character data/" + characterName + "/" + "offsets"));

			for (x in 0...offsets.length) {
				var selectedOffset = offsets[x];
				var arrayOffset:Array<String>;
				arrayOffset = selectedOffset.split(" ");

				addOffset(arrayOffset[0], Std.parseInt(arrayOffset[1]), Std.parseInt(arrayOffset[2]));
			}
		}
	}

	public var shouldDance:Bool = true;

	override function update(elapsed:Float) {
		if (!debugMode && curCharacter != '' && animation.curAnim != null) {
			if (!isPlayer) {
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed * (FlxG.state == PlayState.instance ? PlayState.songMultiplier : 1);

				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001) {
					dance(mostRecentAlt);
					holdTimer = 0;
				}
			}

			// fix for multi character stuff lmao
			if (animation.curAnim != null) {
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playAnim('danceRight');
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	var mostRecentAlt:String = "";

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?altAnim:String = '') {
		if (shouldDance) {
			if (!debugMode && curCharacter != '' && animation.curAnim != null) {
				var alt = "";

				if ((!dancesLeftAndRight && animation.getByName("idle" + altAnim) != null)
					|| (dancesLeftAndRight
						&& animation.getByName("danceLeft" + altAnim) != null
						&& animation.getByName("danceRight" + altAnim) != null))
					alt = altAnim;

				mostRecentAlt = alt;

				var special_animation = !(animation.curAnim.name.startsWith('idle')
					|| animation.curAnim.name.startsWith('danceLeft')
					|| animation.curAnim.name.startsWith('danceRight')
					|| animation.curAnim.name.startsWith('sing'));

				if (!special_animation || animation.curAnim.finished || animation.curAnim.looped) {
					if (!dancesLeftAndRight)
						playAnim('idle' + alt);
					else {
						danced = !danced;

						if (danced)
							playAnim('danceRight' + alt);
						else
							playAnim('danceLeft' + alt);
					}
				}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		if (!animation.exists(AnimName))
			return;
		
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets.set(name, [(isPlayer && offsetsFlipWhenPlayer) || (!isPlayer && offsetsFlipWhenEnemy) ? -x : x, y]);
	}
}
