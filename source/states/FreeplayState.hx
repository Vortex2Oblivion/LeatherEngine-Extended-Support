package states;

import game.Conductor;
#if sys
import sys.thread.Thread;
#end
#if discord_rpc
import utilities.Discord.DiscordClient;
#end
import utilities.Options;
import flixel.util.FlxTimer;
import substates.ResetScoreSubstate;
import flixel.sound.FlxSound;
import lime.app.Application;
import flixel.tweens.FlxTween;
import game.Song;
import game.Highscore;
import utilities.CoolUtil;
import ui.HealthIcon;
import ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.tweens.FlxEase;

using StringTools;

class FreeplayState extends MusicBeatState {
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;

	static var curSelected:Int = 0;
	static var curDifficulty:Int = 1;
	static var curSpeed:Float = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var speedText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public static var songsReady:Bool = false;

	public static var coolColors:Array<Int> = [
		0xFF7F1833,
		0xFF7C689E,
		-14535868,
		0xFFA8E060,
		0xFFFF87FF,
		0xFF8EE8FF,
		0xFFFF8CCD,
		0xFFFF9900
	];

	private var bg:FlxSprite;
	private var selectedColor:Int = 0xFF7F1833;
	private var scoreBG:FlxSprite;

	private var curRank:String = "N/A";

	private var curDiffString:String = "normal";
	private var curDiffArray:Array<String> = ["easy", "normal", "hard"];

	var vocals:FlxSound = new FlxSound();

	var canEnterSong:Bool = true;

	// thx psych engine devs
	var colorTween:FlxTween;

	#if (cpp && sys)
	public var loading_songs:Thread;
	public var stop_loading_songs:Bool = false;
	#end

	var ui_Skin:Null<String>;
	var lastSelectedSong:Int = -1;

	override function create() {
		if (ui_Skin == null || ui_Skin == "default")
			ui_Skin = Options.getData("uiSkin");

		MusicBeatState.windowNameSuffix = " Freeplay";

		var black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		#if NO_PRELOAD_ALL
		if (!songsReady) {
			Assets.loadLibrary("songs").onComplete(function(_) {
				FlxTween.tween(black, {alpha: 0}, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween) {
						remove(black);
						black.kill();
						black.destroy();
					}
				});

				songsReady = true;
			});
		}
		#else
		songsReady = true;
		#end

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			TitleState.playTitleMusic();

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		// Loops through all songs in freeplaySonglist.txt
		for (i in 0...initSonglist.length) {
			if (initSonglist[i].trim() != "") {
				// Creates an array of their strings
				var listArray = initSonglist[i].split(":");

				// Variables I like yes mmmm tasty
				var week = Std.parseInt(listArray[2]);
				var icon = listArray[1];
				var song = listArray[0];

				var diffsStr = listArray[3];
				var diffs = ["easy", "normal", "hard"];

				var color = listArray[4];
				var actualColor:Null<FlxColor> = null;

				if (color != null)
					actualColor = FlxColor.fromString(color);

				if (diffsStr != null)
					diffs = diffsStr.split(",");

				// Creates new song data accordingly
				songs.push(new SongMetadata(song, week, icon, diffs, actualColor));
			}
		}

		if (utilities.Options.getData("menuBGs"))
			if (!Assets.exists(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuBG')))
				bg = new FlxSprite().loadGraphic(Paths.image('ui skins/default/backgrounds/menuDesat'));
			else
				bg = new FlxSprite().loadGraphic(Paths.image('ui skins/' + ui_Skin + '/backgrounds' + '/menuDesat'));
		else
			bg = new FlxSprite().makeGraphic(1286, 730, FlxColor.fromString("#E1E1E1"), false, "optimizedMenuDesat");

		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		scoreText = new FlxText(FlxG.width, 5, 0, "", 32);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 1, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		diffText = new FlxText(FlxG.width, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.alignment = RIGHT;
		add(diffText);

		speedText = new FlxText(FlxG.width, diffText.y + 36, 0, "", 24);
		speedText.font = scoreText.font;
		speedText.alignment = RIGHT;
		add(speedText);

		#if sys
		if (!Options.getData("loadAsynchronously") || !Options.getData("healthIcons")) {
		#end
			for (i in 0...songs.length) {
				var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
				songText.isMenuItem = true;
				songText.targetY = i;
				grpSongs.add(songText);

				if (Options.getData("healthIcons")) {
					var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
					icon.sprTracker = songText;
					iconArray.push(icon);
					add(icon);
				}
			}
		#if sys
		}
		else {
			loading_songs = Thread.create(function() {
				var i:Int = 0;

				while (!stop_loading_songs && i < songs.length) {
					var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
					songText.isMenuItem = true;
					songText.targetY = i;
					grpSongs.add(songText);

					var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
					icon.sprTracker = songText;
					iconArray.push(icon);
					add(icon);

					i++;
				}
			});
		}
		#end

		selector = new FlxText();

		selector.size = 40;
		selector.text = "<";

		if (!songsReady)
			add(black);
		else {
			remove(black);
			black.kill();
			black.destroy();

			songsReady = false;

			new FlxTimer().start(1, function(_) songsReady = true);
		}

		selectedColor = songs[curSelected].color;
		bg.color = selectedColor;

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press RESET to reset song score and rank ~ Press SPACE to play Song Audio ~ Shift + LEFT and RIGHT to change song speed";
		#else
		var leText:String = "Press RESET to reset song score";
		#end

		var text:FlxText = new FlxText(textBG.x - 1, textBG.y + 4, FlxG.width, leText, 18);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String) {
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>) {
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;

		for (song in songs) {
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		for (i in 0...iconArray.length) {
			if (i == lastSelectedSong)
				continue;

			iconArray[i].scale.set(1, 1);
		}

		if (lastSelectedSong != -1 && iconArray[lastSelectedSong] != null)
			iconArray[lastSelectedSong].scale.set(FlxMath.lerp(iconArray[lastSelectedSong].scale.x, 1, elapsed * 9),
				FlxMath.lerp(iconArray[lastSelectedSong].scale.y, 1, elapsed * 9));

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		var funnyObject:FlxText = scoreText;

		if (speedText.width >= scoreText.width && speedText.width >= diffText.width)
			funnyObject = speedText;

		if (diffText.width >= scoreText.width && diffText.width >= speedText.width)
			funnyObject = diffText;

		scoreBG.x = funnyObject.x - 6;

		if (Std.int(scoreBG.width) != Std.int(funnyObject.width + 6))
			scoreBG.makeGraphic(Std.int(funnyObject.width + 6), 108, FlxColor.BLACK);

		scoreText.x = FlxG.width - scoreText.width;
		scoreText.text = "PERSONAL BEST:" + lerpScore;

		diffText.x = FlxG.width - diffText.width;

		curSpeed = FlxMath.roundDecimal(curSpeed, 2);

		#if !sys
		curSpeed = 1;
		#end

		if (curSpeed < 0.25)
			curSpeed = 0.25;

		#if sys
		speedText.text = "Speed: " + curSpeed + " (R+SHIFT)";
		#else
		speedText.text = "";
		#end

		speedText.x = FlxG.width - speedText.width;

		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		var shift = FlxG.keys.pressed.SHIFT;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;

		if (songsReady) {
			if (-1 * Math.floor(FlxG.mouse.wheel) != 0 && !shift)
				changeSelection(-1 * Math.floor(FlxG.mouse.wheel));
			else if (-1 * (Math.floor(FlxG.mouse.wheel) / 10) != 0 && shift)
				curSpeed += -1 * (Math.floor(FlxG.mouse.wheel) / 10);

			if (upP)
				changeSelection(-1);
			if (downP)
				changeSelection(1);

			if (leftP && !shift)
				changeDiff(-1);
			else if (leftP && shift)
				curSpeed -= 0.05;

			if (rightP && !shift)
				changeDiff(1);
			else if (rightP && shift)
				curSpeed += 0.05;

			if (FlxG.keys.justPressed.R && shift)
				curSpeed = 1;

			if (controls.BACK) {
				if (colorTween != null)
					colorTween.cancel();

				if (vocals.active && vocals.playing)
					destroyFreeplayVocals(false);
				if (FlxG.sound.music.active && FlxG.sound.music.playing)
					FlxG.sound.music.pitch = 1;

				#if (cpp && sys)
				stop_loading_songs = true;
				#end

				FlxG.switchState(new MainMenuState());
			}

			#if PRELOAD_ALL
			if (FlxG.keys.justPressed.SPACE) {
				destroyFreeplayVocals();

				if (Assets.exists(Paths.voices(songs[curSelected].songName.toLowerCase(), curDiffString.toLowerCase())))
					vocals = new FlxSound().loadEmbedded(Paths.voices(songs[curSelected].songName.toLowerCase(), curDiffString.toLowerCase()));
				else
					vocals = new FlxSound();

				vocals.persist = false;
				vocals.looped = true;
				vocals.volume = 0.7;

				FlxG.sound.list.add(vocals);

				FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(songs[curSelected].songName.toLowerCase(), curDiffString.toLowerCase()));
				FlxG.sound.music.persist = true;
				FlxG.sound.music.looped = true;
				FlxG.sound.music.volume = 0.7;

				FlxG.sound.list.add(FlxG.sound.music);

				FlxG.sound.music.play();
				vocals.play();

				lastSelectedSong = curSelected;

				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDiffString);

				if (Assets.exists(Paths.json("song data/" + songs[curSelected].songName.toLowerCase() + "/" + poop))) {
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					Conductor.changeBPM(PlayState.SONG.bpm, curSpeed);
				}
			}
			#end

			if (FlxG.sound.music.active && FlxG.sound.music.playing && !FlxG.keys.justPressed.ENTER)
				FlxG.sound.music.pitch = curSpeed;
			if (vocals != null && vocals.active && vocals.playing && !FlxG.keys.justPressed.ENTER)
				vocals.pitch = curSpeed;

			if (controls.RESET && !shift) {
				openSubState(new ResetScoreSubstate(songs[curSelected].songName, curDiffString));
				changeSelection();
			}

			if (FlxG.keys.justPressed.ENTER && canEnterSong) {
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDiffString);

				trace(poop);

				if (Assets.exists(Paths.json("song data/" + songs[curSelected].songName.toLowerCase() + "/" + poop))) {
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					PlayState.isStoryMode = false;
					PlayState.songMultiplier = curSpeed;
					PlayState.storyDifficultyStr = curDiffString.toUpperCase();

					PlayState.storyWeek = songs[curSelected].week;
					trace('CUR WEEK' + PlayState.storyWeek);

					if (Assets.exists(Paths.inst(PlayState.SONG.song, curDiffString.toLowerCase()))) {
						#if sys
						stop_loading_songs = true;
						#end

						if (colorTween != null)
							colorTween.cancel();

						PlayState.loadChartEvents = true;
						destroyFreeplayVocals();
						LoadingState.loadAndSwitchState(new PlayState());
					} else {
						if (Assets.exists(Paths.inst(songs[curSelected].songName.toLowerCase(), curDiffString.toLowerCase())))
							CoolUtil.coolError(PlayState.SONG.song.toLowerCase()
								+ " (JSON) != "
								+ songs[curSelected].songName.toLowerCase() + " (FREEPLAY)\nTry making them the same.",
								"Leather Engine's No Crash, We Help Fix Stuff Tool");
						else
							CoolUtil.coolError("Your song seems to not have an Inst.ogg, check the folder name in 'songs'!",
								"Leather Engine's No Crash, We Help Fix Stuff Tool");
					}
				} else
					CoolUtil.coolError(songs[curSelected].songName.toLowerCase()
						+ " doesn't match with any song audio files!\nTry fixing it's name in freeplaySonglist.txt",
						"Leather Engine's No Crash, We Help Fix Stuff Tool");
			}
		}
	}

	override function closeSubState() {
		changeSelection();
		FlxG.mouse.visible = false;
		super.closeSubState();
	}

	function changeDiff(change:Int = 0) {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, curDiffArray.length - 1);
		curDiffString = curDiffArray[curDifficulty].toUpperCase();

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDiffString);
		curRank = Highscore.getSongRank(songs[curSelected].songName, curDiffString);
		#end

		if (curDiffArray.length > 1)
			diffText.text = "< " + curDiffString + " ~ " + curRank + " >";
		else
			diffText.text = curDiffString + " ~ " + curRank + "  ";
	}

	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, grpSongs.length - 1);

		// Sounds

		// Scroll Sound
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		// Song Inst
		if (utilities.Options.getData("freeplayMusic")) {
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName, curDiffString.toLowerCase()), 0.7);

			if (vocals.active && vocals.playing)
				destroyFreeplayVocals(false);
		}

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDiffString);
		curRank = Highscore.getSongRank(songs[curSelected].songName, curDiffString);
		#end

		curDiffArray = songs[curSelected].difficulties;

		changeDiff();

		var bullShit:Int = 0;

		if (iconArray.length > 0) {
			for (i in 0...iconArray.length) {
				iconArray[i].alpha = 0.6;

				if (iconArray[i].animation.curAnim != null && !iconArray[i].animatedIcon)
					iconArray[i].animation.curAnim.curFrame = 0;
			}

			iconArray[curSelected].alpha = 1;

			if (iconArray[curSelected].animation.curAnim != null && !iconArray[curSelected].animatedIcon) {
				iconArray[curSelected].animation.curAnim.curFrame = 2;

				if (iconArray[curSelected].animation.curAnim.curFrame != 2)
					iconArray[curSelected].animation.curAnim.curFrame = 0;
			}
		}

		for (item in grpSongs.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		if (change != 0) {
			var newColor:FlxColor = songs[curSelected].color;

			if (newColor != selectedColor) {
				if (colorTween != null) {
					colorTween.cancel();
				}

				selectedColor = newColor;

				colorTween = FlxTween.color(bg, 0.25, bg.color, selectedColor, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
				});
			}
		} else
			bg.color = songs[curSelected].color;
	}

	public function destroyFreeplayVocals(?destroyInst:Bool = true) {
		if (vocals != null) {
			vocals.stop();
			vocals.destroy();
		}

		vocals = null;

		if (!destroyInst)
			return;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		FlxG.sound.music = null;
	}

	override function beatHit() {
		super.beatHit();

		if (lastSelectedSong != -1 && iconArray[lastSelectedSong] != null)
			iconArray[lastSelectedSong].scale.add(0.2, 0.2);
	}
}

class SongMetadata {
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var difficulties:Array<String> = ["easy", "normal", "hard"];
	public var color:FlxColor = FlxColor.GREEN;

	public function new(song:String, week:Int, songCharacter:String, ?difficulties:Array<String>, ?color:FlxColor) {
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;

		if (difficulties != null)
			this.difficulties = difficulties;

		if (color != null)
			this.color = color;
		else {
			if (FreeplayState.coolColors.length - 1 >= this.week)
				this.color = FreeplayState.coolColors[this.week];
			else
				this.color = FreeplayState.coolColors[0];
		}
	}
}
