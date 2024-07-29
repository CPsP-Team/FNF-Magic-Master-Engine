package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.editors.tiled.TiledMap;
import flixel.group.FlxGroup.FlxTypedGroup;
import objects.scripts.Script.Script_Calls;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.atlas.FlxAtlas;
import objects.notes.Note.Event_Data;
import objects.songs.Song.Song_File;
import substates.MusicBeatSubstate;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import flixel.sound.FlxSoundGroup;
import openfl.geom.ColorTransform;
import openfl.display.BitmapData;
import flixel.util.FlxStringUtil;
import flixel.util.FlxCollision;
import openfl.display.BlendMode;
import objects.utils.EventList;
import substates.PauseSubState;
import objects.notes.StrumNote;
import objects.notes.StrumLine;
import objects.game.Character;
import objects.scripts.Script;
import flixel.tweens.FlxTween;
import objects.game.Dialogue;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import objects.game.Alphabet;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import states.GitarooPause;
import flixel.util.FlxSort;
import flixel.text.FlxText;
import objects.game.HudBar;
import flixel.FlxSubState;
import objects.notes.Note;
import objects.game.Stage;
import objects.songs.Song;
import objects.game.Icon;
import lime.utils.Assets;
import sys.thread.Thread;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.ui.FlxBar;
import flixel.FlxState;
import utils.Highscore;
import flixel.FlxBasic;
import flixel.FlxGame;
import utils.Players;
import utils.Magic;
import utils.Songs;
import flixel.FlxG;
import haxe.Timer;
import haxe.Json;

#if (hxCodec >= "2.6.1") import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0") import VideoHandler as MP4Handler;
#else import vlc.MP4Handler; #end

#if desktop
import utils.Discord;
#end

using utils.Files;
using StringTools;

class PlayState extends MusicBeatState {
	public static var strumLeftPos:Float = 100;
	public static var strumMiddlePos:Float = 100;
	public static var strumRightPos:Float = 100;

	private static var prevCamFollow:FlxObject;

	public static var sickEmote:Float = 0.1;
	public var emoteBeat:Int = 0;

	public static var song:Song_File = null;
	public static var count:Int = 0;
	
	public var introAssets:Array<{asset:String, sound:String}> = [
		{asset:null, sound: 'intro3'},
		{asset:'ready', sound: 'intro2'},
		{asset:'set', sound: 'intro1'},
		{asset:'go', sound: 'introGo'}
	];

    public var curSection(get, never):Int;
	inline function get_curSection():Int{return Std.int(conductor.getCurStep() / 16);}

	// Hud Stuff
	public var healthfront:FlxSprite;
	public var alpScore:Alphabet;
	public var readyInfo:FlxText;
	public var healthbar:HudBar;
	public var playerIcon:Icon;
	public var enemyIcon:Icon;

	public var danceIcon:FlxSprite;
	
    public var popScore:Alphabet;
    public var rankIcon:FlxSprite;
    public var rankTween:FlxTween;

	//Audio Properties
	public var inst:FlxSound;
	public var voices:FlxSoundGroup;

	//Strumlines
	public var strums:FlxTypedGroup<StrumLine>;
	public var strumPlayer:StrumLine;

	//Song Stats
	public var song_Length:Float = 0;
	public var song_Time:Float = 0;

	public var lastScore:Int = 0;
	public var highscore:Int = 0;

	public var events:EventList = new EventList();
	
	// Gameplay Bools
	public var defaultBumps:Bool = true;
	public var followChar:Bool = true;
	public var defaultZoom:Float = 1;
	public var zoomMult:Float = 1;
	public var iconMult:Float = 1;
	
    public var camFollow:FlxObject;
	
	public var stage:Stage;

	//Other Bools
	public var songGenerated:Bool = false;
	public var canStartSong:Bool = false;
	public var songStarted:Bool = false;
	public var songPlaying:Bool = false;
	public var onGameOver:Bool = false;
	public var onResults:Bool = false;
	public var canPause:Bool = false;
	public var isPaused:Bool = false;
	public var canReset:Bool = true;
	public var canEmote:Bool = true;

	public var offsetIcons:FlxPoint = FlxPoint.get(0, 0);
	public var offsetBar:FlxPoint = FlxPoint.get(5, 6);
	public var lastPlayer:Int = 0;

	// Pause Properties
	public var timers:Array<FlxTimer> = [];
	public var tweens:Array<FlxTween> = [];

	// PreMethods
	public function doSing(cur_strum:StrumLine, note:Note, isMiss:Bool = false):Void { // Do Sing to Characters
		var song_animation:String = note.singAnimation + (isMiss ? "miss" : "");
		var section_strum = cur_strum.data.sections[curSection];

		if(section_strum != null && section_strum.changeAlt){song_animation += '-alt';}

		var character_list:Array<Int> = cur_strum.data.characters;
		if(section_strum != null && section_strum.changeCharacters){character_list = section_strum.characters;}

		for(id in character_list){
			var new_character:Character = stage.getCharacterById(id);
			if(new_character == null){continue;}
			new_character.singAnim((note.typeHit == "Hold" && new_character.curAnim.contains("sing")) ? new_character.curAnim : song_animation, note.typeHit != "Hold");
		}
	}
	public function doRank(cur_strum:StrumLine, _note:Note, _score:Float, _rank:String, _pop_image:String):Void {
		if(!cur_strum.isUsing || cur_strum.botplay){return;}
		if(rankTween != null){rankTween.cancel();} rankIcon.revive();
		rankIcon.loadGraphic(Paths.styleImage(_pop_image, song.style).getGraphic());
		rankIcon.scale.set(0.7, 0.7); rankIcon.updateHitbox(); rankIcon.alpha = 1;
		rankIcon.setPosition(cur_strum.x + (cur_strum.width / 2) - (rankIcon.width / 2), cur_strum.y + 300);
		popScore.setPosition(rankIcon.x, rankIcon.y + rankIcon.height); popScore.popScore(cur_strum.combo, song.style);
		rankTween = FlxTween.tween(rankIcon, {y: rankIcon.y - 25, alpha: 0}, 0.5, {ease:FlxEase.quadOut, onComplete: function(twn){rankIcon.kill();}});
	}
	public function doStart():Void { // Start Song
		FlxTween.tween(camHUD, {alpha: 1}, (conductor.crochet / 1000) * (introAssets.length + 1), {ease: FlxEase.quadInOut});
		conductor.position = -(conductor.crochet * (introAssets.length + 1));
		readyInfo.visible = false;
		songPlaying = true;

		startCountdown(startSong);
	}
	public function doEnd():Void { // End Song
		if(Songs.playlist.length > 0){Songs.play(); return;}
		
		doResults(lastPlayer);
	};	
	public function startCountdown(onComplete:Void->Void = null):Void {
		var swagCounter:Int = 0;

		timers.push(new FlxTimer().start(conductor.crochet / 1000, function(tmr:FlxTimer){
			if(introAssets[swagCounter] != null){
				if(introAssets[swagCounter].sound != null){FlxG.sound.play(Paths.styleSound(introAssets[swagCounter].sound, song.style).getSound(), 0.6);}
			
				if(introAssets[swagCounter].asset != null){
					var iAssets:FlxSprite = new FlxSprite().loadGraphic(Paths.styleImage(introAssets[swagCounter].asset, song.style));
					iAssets.scrollFactor.set();
					iAssets.updateHitbox();
					iAssets.screenCenter();
					add(iAssets);

					FlxTween.tween(iAssets, {y: iAssets.y += 100, alpha: 0}, conductor.crochet / 1000, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween){iAssets.destroy();}});
				}
			}

			if(swagCounter == introAssets.length){if(onComplete != null){onComplete();}}

			swagCounter++;
		}, introAssets.length + 1));
	}

	override public function create(){
		song = Songs.playlist.length > 0 ? Songs.playlist[0] : Song.load('Tutorial-Normal-Normal');
		super.create();

		strumRightPos = FlxG.width - 100;
		strumMiddlePos = FlxG.width / 2;

		PlayState.count++;
		
		persistentUpdate = true;
		persistentDraw = true;

		stage = new Stage(song.stage, song.characters);
		add(stage);
		
		danceIcon = new FlxSprite().loadGraphic(Paths.styleImage("dance", song.style));
		danceIcon.scale.set(0.7, 0.7); danceIcon.updateHitbox();
		danceIcon.alpha = 0.0001;
		add(danceIcon);
	
		defaultZoom = stage.zoom;

		conductor.position = -5000;

		strums = new FlxTypedGroup<StrumLine>();
		strums.cameras = [camHUD];
		add(strums);
			
        camFollow = prevCamFollow != null ? prevCamFollow : new FlxObject(0, 0, 1, 1);
		if (prevCamFollow != null){prevCamFollow = null;}
		camFollow.screenCenter();
		add(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.zoom = stage.zoom;
		FlxG.fixedTimestep = false;
		FlxG.mouse.visible = false;


		camHUD.alpha = 0;

		generateHud();
		generateSong();

		#if desktop
		Discord.change("Playing " + song.song, null);
		Magic.setWindowTitle("Playing " + song.song);
		#end
	}

	private function generateSong():Void {
		conductor.changeBPM(song.bpm);
		conductor.mapBPMChanges(song);

		//Loading Instrumental
		inst = new FlxSound().loadEmbedded(Paths.inst(song.song, song.category).getSound(), false, false, endSong);
		inst.looped = false;
		inst.onComplete = endSong.bind();
		FlxG.sound.list.add(inst);
		
		song_Length = inst.length;

		//Loading Voices
		voices = new FlxSoundGroup();		
		voices.sounds = [];

		if(song.voices){
            for(i in 0...song.strums.length){
				if(song.strums[i].characters.length <= 0){continue;}
				if(song.characters.length <= song.strums[i].characters[0]){continue;}
				var voice_path:String = Paths.voice(i, song.characters[song.strums[i].characters[0]][0], song.song, song.category);
				if(!Paths.exists(voice_path)){continue;}
				var voice = new FlxSound().loadEmbedded(voice_path.getSound());
				FlxG.sound.list.add(voice);
				voices.add(voice);
            }
        }
		
		if(voices.sounds.length <= 0){
			var voice = new FlxSound();
			FlxG.sound.list.add(voice);
			voices.add(voice);
		}
		
		// Loading Events
		events.conductor = conductor;
		events.clear();
		for(event in song.events){
			var event_data:Event_Data = Note.getEventData(event);
			
			events.push(event_data.strumTime, ()->{
				for(cur_action in event_data.eventData){
					var action_script:Script = scripts.get(cur_action[0]);
					if(action_script == null){trace('Null Event: ${cur_action[0]}'); continue;}
					action_script.call("execute", cast(cur_action[1], Array<Dynamic>));
				}
			});
		}

		//Loading Strumlines
		for(i in 0...song.strums.length){
			var new_strum = new StrumLine(0, 0, song.strums[i].keys, 448, null, song.strums[i].style, null);
			
			new_strum.onHIT = function(note:Note){doSing(new_strum, note, false);};
			new_strum.onMISS = function(note:Note){doSing(new_strum, note, true);};

			new_strum.scrollspeed = song.speed;
			new_strum.conductor = conductor;
			new_strum.bpm = song.bpm;
			
			new_strum.alpha = 0;
			new_strum.x = (FlxG.width / 2) - (new_strum.width / 2);
			new_strum.y = Settings.get("DownScroll") ? FlxG.height - new_strum.height - 30 : 30;

			new_strum.load(song.strums[i]);
			new_strum.ID = i;

			strums.add(new_strum);
		}

		if(Songs.players.length <= 0){Songs.players = [song.player];}

		for(i in Songs.players){
			var cur_strum:StrumLine = strums.members[i];
			if(cur_strum == null){continue;}

			cur_strum.isUsing = true;

			if(Songs.players.length > 1){
				cur_strum.controls = Players.get(i).controls;
				cur_strum.onGAME_OVER = function(){}
			} else {
				strumPlayer = cur_strum;
				cur_strum.controls = controls;
				cur_strum.onGAME_OVER = ()->{doGameOver(i);};
				cur_strum.onRANK = (_note:Note, _score:Float, _rank:String, _pop_image:String)->{doRank(cur_strum, _note, _score, _rank, _pop_image);};
				playerIcon.setIcon(stage.getCharacterById(song.strums[i].characters[0]).icon, cur_strum);
				healthbar.setColors(null, stage.getCharacterById(song.strums[i].characters[0]).barcolor);
				enemyIcon.parent = cur_strum;
			}
		}

		for(i in 0...strums.length){
			if(strums.members[i].isUsing){continue;}
			enemyIcon.setIcon(stage.getCharacterById(song.strums[i].characters[0]).icon);
			healthbar.setColors(stage.getCharacterById(song.strums[i].characters[0]).barcolor, null);
		}
		
		checkScroll();
		updateStrums();
		
		playerIcon.x = healthbar.x + healthbar.width_value + offsetIcons.x;
		enemyIcon.x = healthbar.x + healthbar.width_value - enemyIcon.width + offsetIcons.x;

		FlxTween.tween(readyInfo, {y: FlxG.height - readyInfo.height - 10}, {ease: FlxEase.bounceOut, startDelay: 5});

		scripts.call('preload');

		songGenerated = true;
		if(scripts.callback("startSong") != Stop){canStartSong = true;}
	}
	private function generateHud():Void {
		healthfront = new FlxSprite().loadGraphic(Paths.styleImage("healthBar_front", song.style));
		healthfront.setGraphicSize(FlxG.width * 0.5); healthfront.updateHitbox();
		healthfront.camera = camHUD;

		healthbar = new HudBar(0, 0, Paths.styleImage("healthBar_back", song.style));
		healthbar.setBarScale(healthfront.scale.x, healthfront.scale.y);
		healthbar.camera = camHUD;
		healthbar.flipBar = true;

		add(healthbar);
		add(healthfront);

		alpScore = new Alphabet(0, 0, {font: "small_numbers", scale: 0.5, text: '0'});
		alpScore.camera = camHUD;
		add(alpScore);

		readyInfo = new FlxText(0, FlxG.height + 10, 0, Language.get("ready_info"), 20);
		readyInfo.camera = camBHUD;
		readyInfo.screenCenter(X);
		add(readyInfo);

		playerIcon = new Icon(true);
		playerIcon.camera = camHUD;
		playerIcon.flipX = true;
		add(playerIcon);

		enemyIcon = new Icon();
		enemyIcon.camera = camHUD;
		add(enemyIcon);

        rankIcon = new FlxSprite();
		rankIcon.camera = camHUD;
        add(rankIcon);
        rankIcon.kill();
        
        popScore = new Alphabet(0, 0, []);
		popScore.camera = camHUD;
        add(popScore);
	}

	override public function update(elapsed:Float){
		super.update(elapsed);

		if(Songs.players.length == 1){
			if(lastScore != strumPlayer.score){
				alpScore.setText({font: "small_numbers", scale: 0.5, text: '${lastScore = strumPlayer.score}'});
				alpScore.x = healthbar.x + healthbar.width - alpScore.width - 10;
			}
			if(healthbar.value != strumPlayer.health){
				healthbar.value = strumPlayer.health;
				playerIcon.x = healthbar.x + healthbar.width_value + offsetIcons.x;
				enemyIcon.x = healthbar.x + healthbar.width_value - enemyIcon.width + offsetIcons.x;
			}
		}else{

		}

		if(canControlle){
			if(canStartSong && songGenerated && !songPlaying && !songEnded && controls.check("Start")){
				doStart();
			}else if(songPlaying){
				if(controls.check("Emote") && canEmote && emoteBeat != curBeat){
					emoteBeat = curBeat;
					if(song_Time % conductor.crochet < (conductor.crochet * sickEmote) || song_Time % conductor.crochet > conductor.crochet - (conductor.crochet * sickEmote)){
						var character_list:Array<Int> = strumPlayer.data.characters;
						if(strumPlayer.data.sections[curSection] != null && strumPlayer.data.sections[curSection].changeCharacters){character_list = strumPlayer.data.sections[curSection].characters;}
				
						var firstChar:Character = null;
						for(id in character_list){
							var new_character:Character = stage.getCharacterById(id);
							if(new_character == null){continue;}
							if(firstChar == null){firstChar = new_character;}
							new_character.playEmote();
						}

						danceIcon.revive();
						FlxTween.cancelTweensOf(danceIcon);
						danceIcon.setPosition(firstChar.x + firstChar.cameraPosition[0], firstChar.y + firstChar.cameraPosition[1]); danceIcon.alpha = 1; danceIcon.angle = 0;
						FlxTween.tween(danceIcon, {y: danceIcon.y - 25, alpha: 0, angle: FlxG.random.float(-5, 5)}, 1.5, {ease:FlxEase.quadOut, onComplete: (twn) -> {danceIcon.kill();}});
					}
				}else if(controls.check("Pause") && canPause){
					pauseAndOpen(
						"substates.PauseSubState",
						[
							function(){
								if(!songGenerated){isPaused = false; pauseSong(false); return;}
								checkScroll();
								startCountdown(function(){
									persistentUpdate = true;
									persistentDraw = true;
									canControlle = true;
									isPaused = false;
									pauseSong(false);
								});
							}
						],
						true
					);
					return;
				}else if(FlxG.keys.justPressed.SEVEN && !Songs.isStoryMode){
					persistentUpdate = false;
					inst.destroy();
					for(s in voices.sounds){s.destroy();}
					VoidState.clearAssets = false;
					states.editors.ChartEditorState.song = song;
					MusicBeatState.switchState("states.editors.ChartEditorState", []);
					return;
				}else if(controls.check("Reset") && canReset){doGameOver(Songs.players[0]); return;}
				else if(FlxG.keys.justPressed.P){endSong(); return;}
			}			
		}

		if(songPlaying){			
			// conductor.position = inst.time;
			conductor.position += FlxG.elapsed * 1000;
	
			if(!isPaused){
				song_Time += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
	
				// Interpolation type beat
				if(conductor.lastPosition != conductor.position){
					song_Time = (song_Time + conductor.position) / 2;
					conductor.lastPosition = conductor.position;
					// conductor.position += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}	
			// conductor.lastPosition = inst.time;
		
			if(followChar){Character.setCamera(stage.getCharacterById(Character.getFocus(song, curSection)), camFollow, stage);}

			if(Settings.get("BumpingCamera") && defaultBumps){
				playerIcon.scale.x = FlxMath.lerp(playerIcon.scale.x, playerIcon.default_scale.x, elapsed * 3.125);
				playerIcon.scale.y = FlxMath.lerp(playerIcon.scale.y, playerIcon.default_scale.y, elapsed * 3.125);
				enemyIcon.scale.x = FlxMath.lerp(enemyIcon.scale.x, enemyIcon.default_scale.x, elapsed * 3.125);
				enemyIcon.scale.y = FlxMath.lerp(enemyIcon.scale.y, enemyIcon.default_scale.y, elapsed * 3.125);
	
				FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultZoom, FlxG.elapsed * 3.125);
				camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, FlxG.elapsed * 3.125);
			}
		}
	}

	public var last_conductor:Float = -10000;
	public function resyncVocals():Void{
		if(!songPlaying){return;}

		for(sound in voices.sounds){sound.pause();}
	
		inst.play();
		conductor.position = inst.time;
		for(sound in voices.sounds){
			sound.time = conductor.position;
			sound.play();
		}

		if(conductor.position < last_conductor){endSong();}
		last_conductor = conductor.position;
	}

	public function pauseSong(pause:Bool = true){
		songPlaying = !pause;

		if(!songPlaying){
			if(inst != null){
				inst.pause();
				for(sound in voices.sounds){sound.pause();}
			}
			for(timer in timers){if(timer != null){timer.active = false;}}
			for(tween in tweens){if(tween != null){tween.active = false;}}
		}else{
			if(songGenerated && inst != null){resyncVocals();}	
			for(timer in timers){if(timer != null){timer.active = true;}}
			for(tween in tweens){if(tween != null){tween.active = true;}}
		}
		
		scripts.call('paused', [pause]);
	}

	public function pauseAndOpen(substate:String, args:Array<Dynamic>, hasEasterEgg:Bool = false, per_update:Bool = false, per_draw:Bool = true){
		if(isPaused){return;}
		persistentUpdate = per_update;
		persistentDraw = per_draw;
		isPaused = true;

		pauseSong();

		// 1 / 1000 chance for Gitaroo Man easter egg
		if(hasEasterEgg && FlxG.random.bool(0.1)){
			trace('GITAROO MAN EASTER EGG');
			MusicBeatState.switchState("states.GitarooPause", []);
		}else{
			canControlle = false;
			loadSubState(substate, args);
		}
	}
	
	var previousFrameTime:Int = 0;
	function startSong():Void{
		trace("Starting Song");

		previousFrameTime = FlxG.game.ticks;
		
		conductor.position = 0;

		inst.play(true);
		for(sound in voices.sounds){sound.play(true);}
				
		canPause = true;
		resyncVocals();

		songStarted = true;
		scripts.call('songStarted');
	}

	var songEnded:Bool = false;
	function endSong():Void {
		if(songEnded){return;}
		songEnded = true;

		trace("Ending Song");

		songPlaying = false;
		canPause = false;
		isPaused = true;

		inst.stop();
		for(sound in voices.sounds){sound.stop();}
		
		lastPlayer = Songs.players[0];

		var song_score:Int = 0;
		for(s in Songs.players){song_score += strums.members[s].score;}

		highscore = Highscore.save(Paths.format(song.song, true), song_score, song.difficulty, song.category);
		Songs.next(song_score);
		
		if(Songs.playlist.length <= 0){
			NGio.unlockMedal(60961);
			Highscore.saveWeek(Songs.weekName, Songs.total_score, song.difficulty, song.category);

			inst.destroy();
			for(s in voices.sounds){s.destroy();}
			
			Songs.reset();
		}else{
			prevCamFollow = camFollow;
		}

		if(scripts.callback("endSong") != Stop){doEnd();}
	}

	function doGameOver(_player:Int):Void {
		onGameOver = true;

		camHUD.visible = false;
		camFHUD.visible = false;
		
		var chars:Array<Character> = [];
		var char:Array<Int> = song.strums[_player].characters;
		if(song.strums[_player].sections[curSection].changeCharacters){char = song.strums[_player].sections[curSection].characters;}
		for(i in char){chars.push(stage.getCharacterById(i)); stage.getCharacterById(i).visible = false;}

		pauseAndOpen("substates.GameOverSubstate", [chars, song.style], false, false);
	}
	function doResults(_player:Int):Void {
		onResults = true;
		
		camHUD.visible = false;
		camFHUD.visible = false;
		
		var chars:Array<Character> = [];
		var char:Array<Int> = song.strums[_player].characters;
		if(
			song.strums[_player] != null && 
			song.strums[_player].sections[curSection] != null && 
			song.strums[_player].sections[curSection].changeCharacters
		){char = song.strums[_player].sections[curSection].characters;}
		for(i in char){chars.push(stage.getCharacterById(i)); stage.getCharacterById(i).visible = false;}

		persistentUpdate = false;
		persistentDraw = true;
		canControlle = false;

		var curStrum:StrumLine = strums.members[_player];

		loadSubState("substates.ResultSubstate", [chars, song.style, curStrum.score, curStrum.hits, curStrum.max_combo, curStrum.misses, curStrum.rankList, highscore]);
	}

	override public function onFocusLost():Void {
		super.onFocusLost();

		if (!songStarted || !canPause || !Settings.get("PauseOnLost", "GameSettings")) { return; }

		pauseAndOpen(
			"substates.PauseSubState",
			[
				function(){
					checkScroll();
					startCountdown(function(){
						persistentUpdate = true;
						persistentDraw = true;
						canControlle = true;
						isPaused = false;
						pauseSong(false);
					});
				}
			],
			true
		);
	}

	override function stepHit(){
		super.stepHit();
		
		if(songPlaying && inst.time > conductor.position + 20 || inst.time < conductor.position - 20){resyncVocals();}
		
		//trace('${inst.time} / ${inst.length}');
	}

	override function beatHit(){
		super.beatHit();

		if(Settings.get("BumpingCamera") && defaultBumps){
			if(curBeat % 2 == 0){
				// Beat Icons
				playerIcon.scale.x += 0.1 * iconMult;
				playerIcon.scale.y += 0.1 * iconMult;
				enemyIcon.scale.x += 0.1 * iconMult;
				enemyIcon.scale.y += 0.1 * iconMult;
			}

			if(curBeat % 4 == 0){
				// Beat Cameras
				FlxG.camera.zoom += 0.015 * zoomMult;
				camHUD.zoom += 0.03 * zoomMult;
			}
		}

		if(song.sections[curSection] != null){
			if(song.sections[curSection].changeBPM){
				conductor.changeBPM(song.sections[curSection].bpm);
				FlxG.log.add('CHANGED BPM!');
				trace('Changed BPM');
			}
		}
	}

	function updateStrums():Void {
		for (strum in strums) {
			strum.alpha = 0;
			if (!song.strums[strum.ID].playable) {continue;}
			var cur_char:Character = stage.getCharacterById(Character.getFocus(song, curSection, strum.ID));
			strum.x = (Settings.get("Onlynotes")) ? (strumMiddlePos - strum.width / 2) : ((cur_char.onRight) ? (strumLeftPos) : (strumRightPos - strum.width));
			strum.alpha = 1;
		}
	}

	public function checkScroll():Void {
		healthfront.screenCenter(X);
		healthfront.y = Settings.get("DownScroll") ? 40 : FlxG.height - healthfront.height - 30;

		healthbar.setPosition(healthfront.x + (offsetBar.x * healthfront.scale.x), healthfront.y + (offsetBar.y * healthfront.scale.y));

		playerIcon.y = healthfront.y + (healthfront.height / 2) - (playerIcon.height / 2) + offsetIcons.y;
		enemyIcon.y = healthfront.y + (healthfront.height / 2) - (enemyIcon.height / 2) + offsetIcons.y;

		alpScore.setPosition(
			healthbar.x + healthbar.width - alpScore.width - 10, 
			healthbar.y + healthbar.height
		);

		for(strum in strums){
			strum.y = Settings.get("DownScroll") ? FlxG.height - strum.height - 30 : 30;
			for(n in strum.notelist){n.playAnim(n.animation.curAnim.name, true);}
			for(n in strum.notes.members){n.playAnim(n.animation.curAnim.name, true);}
		}
		
		scripts.call('checkScroll');
	}
}
