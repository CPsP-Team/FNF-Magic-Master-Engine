package states;

import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets as LimeAssets;
import flixel.addons.util.FlxAsyncLoop;
import objects.notes.Note.Event_Data;
import objects.notes.Note.Note_Data;
import objects.songs.Song.Song_File;
import lime.utils.AssetManifest;
import objects.notes.StrumLine;
import flixel.util.FlxGradient;
import lime.utils.AssetLibrary;
import objects.game.Character;
import objects.scripts.Script;
import openfl.utils.AssetType;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import objects.game.Stage;
import objects.notes.Note;
import sys.thread.Thread;
import flixel.FlxSprite;
import lime.app.Promise;
import flixel.ui.FlxBar;
import flixel.FlxState;
import lime.app.Future;
import utils.Language;
import utils.Scripts;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class LoadingState extends MusicBeatState {
	public static var globalStuff:Array<Dynamic> = [];
	public var toLoadStuff:Array<Dynamic> = [];

	public var sprBackground:FlxSprite;
	public var sprShape1:FlxSprite;
	public var sprShape2:FlxSprite;
	public var sprShape3:FlxSprite;
	public var sprShape4:FlxSprite;

	private var tempLoadingStuff:Array<Dynamic> = [];
	private var totalCount:Int = 0;
	
	private var WithMusic:Bool = false;
	
	private var thdLoading:Thread;
	private var loadedAll:Bool = false;

	public var TARGET:MusicBeatState;

	public function new(_target:MusicBeatState, _toLoadStuff:Array<Dynamic>, withMusic:Bool = false):Void {
		if(_toLoadStuff == null){_toLoadStuff = [];}
		this.toLoadStuff = _toLoadStuff;
		this.WithMusic = withMusic;
		this.TARGET = _target;

		for(i in globalStuff){toLoadStuff.push(i);}

		super();
	}

	override function create():Void {
		FlxG.mouse.visible = false;

		if(!WithMusic && FlxG.sound.music != null){FlxG.sound.music.stop();}
		
		sprBackground = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		sprBackground.setGraphicSize(FlxG.width, FlxG.height);
        sprBackground.color = 0xffff8cf7;
		sprBackground.screenCenter();
		add(sprBackground);

		sprShape1 = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, FlxColor.BLACK); add(sprShape1);
        sprShape2 = new FlxSprite(0, 105).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(sprShape2);
        sprShape3 = new FlxSprite(0, FlxG.height - 110).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(sprShape3);
        sprShape4 = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, FlxColor.BLACK); add(sprShape4);
				
		super.create();
		
		preLoadStuff();
		totalCount = tempLoadingStuff.length;
		loadStuff();
	}

	override function update(elapsed:Float){
		super.update(elapsed);
	}

	private function preLoadStuff():Void {
		tempLoadingStuff.push({type:MUSIC,instance:Paths.music("breakfast", "shared")});
		tempLoadingStuff.push({type:IMAGE,instance:Paths.image("icons/icon-face")});
		tempLoadingStuff.push({type:SOUND,instance:Paths.sound("confirmMenu")});
		tempLoadingStuff.push({type:MUSIC,instance:Paths.music("break_song")});
		tempLoadingStuff.push({type:MUSIC,instance:Paths.music("freakyMenu")});
		tempLoadingStuff.push({type:SOUND,instance:Paths.sound("cancelMenu")});
		tempLoadingStuff.push({type:SOUND,instance:Paths.sound("scrollMenu")});
		tempLoadingStuff.push({type:IMAGE,instance:Paths.image("alphabet")});
		
		for(stuff in toLoadStuff){
			if(stuff.type == IMAGE || stuff.type == SOUND || stuff.type == MUSIC || stuff.type == TEXT){ continue; }
			
			switch(stuff.type){
				case "SONG":{
					var _song:Song_File = cast stuff.instance;
					
					tempLoadingStuff.push({ type: SOUND, instance:Paths.inst(_song.song, _song.category)});
					
					if(_song.voices){
						for(i in 0..._song.strums.length){
							if(_song.strums[i].characters.length <= 0){continue;}
							if(_song.characters.length <= _song.strums[i].characters[0]){continue;}
							var voice_path:String = Paths.voice(i, _song.characters[_song.strums[i].characters[0]][0], _song.song, _song.category);
							if(!Paths.exists(voice_path)){continue;}
							tempLoadingStuff.push({type: SOUND, instance: voice_path});
						}
					}

					for(p in StrumLine.ranks){
						tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage(p.popup, _song.style, 'shared') });
					}

					if((TARGET is PlayState)){
						for(p in cast(TARGET, PlayState).introAssets){
							if(p.asset != null){tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage(p.asset, _song.style, 'shared') });}
							if(p.sound != null){tempLoadingStuff.push({ type: SOUND, instance: Paths.styleSound(p.sound, _song.style, 'shared') });}
						}
					}

					tempLoadingStuff.push({type: SOUND, instance: Paths.styleSound('fnf_loss_sfx', _song.style, 'shared')});
					tempLoadingStuff.push({type: MUSIC, instance: Paths.styleMusic('gameOverEnd', _song.style, 'shared')});
					tempLoadingStuff.push({type: SOUND, instance: Paths.styleSound('missnote1', _song.style, 'shared')});
					tempLoadingStuff.push({type: SOUND, instance: Paths.styleSound('missnote2', _song.style, 'shared')});
					tempLoadingStuff.push({type: SOUND, instance: Paths.styleSound('missnote3', _song.style, 'shared')});
					tempLoadingStuff.push({type: MUSIC, instance: Paths.styleMusic('gameOver', _song.style, 'shared')});
					tempLoadingStuff.push({type: MUSIC, instance: Paths.styleMusic('results', _song.style, 'shared')});
					
					var stage_script:Script = Scripts.quick(Paths.stage(_song.stage));
					if(stage_script != null){stage_script.call("cache", [tempLoadingStuff]);}
					
					var song_script:Script = Scripts.quick(Paths.song(_song.song, 'Song_Events.hx'));
					if (song_script != null) {
						song_script.parent = TARGET;
						TARGET.scripts.set("Script_Song", song_script);
					}

					for(char in _song.characters){
						Character.cache(tempLoadingStuff, char[0], char[4]);
					}

					for(event in _song.events){
						var cur_Event:Event_Data = Note.getEventData(event);
						if(cur_Event == null || cur_Event.isBroken){continue;}
						for(cur_action in cur_Event.eventData){
							if(!Paths.exists(Paths.event(cur_action[0]))){continue;}
							var script_event:Script = TARGET.scripts.get(cur_action[0]);
							if(script_event == null){
								var script_event:Script = Scripts.quick(Paths.event(cur_action[0]));
								TARGET.scripts.set(cur_action[0], script_event);
								continue;
							}
							tempLoadingStuff.push({type: "FUNCTION", instance: function(){
								script_event.call("preload_event", cast(cur_action[1], Array<Dynamic>));
							}});
						}
					}

					for(strum in _song.strums){
						for(section in strum.sections){
							for(note in section.notes){
								var cur_Note:Note_Data = Note.getNoteData(note);
								var note_events:Array<Dynamic> = [];
								if(cur_Note.eventData != null){note_events = cur_Note.eventData.copy();}

								if(cur_Note.preset != null && cur_Note.preset != "Default"){
									var preset_path:String = Paths.preset(cur_Note.preset);
									if(Paths.exists(preset_path)){
										for(event in cast(preset_path.getJson().Events, Array<Dynamic>)){
											note_events.push(event);
										}
									}
								}

								for(cur_action in note_events){
									if(!Paths.exists(Paths.event(cur_action[0]))){continue;}
									var script_event:Script = TARGET.scripts.get(cur_action[0]);
									if(script_event == null){
										var script_event:Script = Scripts.quick(Paths.event(cur_action[0]));
										TARGET.scripts.set(cur_action[0], script_event);
										continue;
									}
									tempLoadingStuff.push({type: "FUNCTION", instance: function(){
										script_event.call("preload_event", cast(cur_action[1], Array<Dynamic>));
									}});
								}
							}
						}
					}

					continue;
				}
				case "PRELOAD":{
					if(stuff.instance != null){stuff.instance(this);}
					
					continue;
				}
			}

			tempLoadingStuff.push(stuff);
		}
		
		TARGET.scripts.call("cache", [tempLoadingStuff]);
	}

	private function loadStuff():Void {
		thdLoading = Thread.create(() -> {
			while(true){
				if(tempLoadingStuff.length <= 0){onLoad(); return;}
				var _stuff:Dynamic = tempLoadingStuff.shift(); //trace(tempLoadingStuff.length);
				if(_stuff.type == null || _stuff.instance == null){ trace("Error | " + _stuff); return;}

				switch(_stuff.type){
					default: { trace(_stuff); }
					case IMAGE: {if(!Settings.get("UseGpu")){Files.getGraphic(_stuff.instance);}}
					case SOUND, MUSIC: {Files.getSound(_stuff.instance);}
					case TEXT: {Files.getText(_stuff.instance);}
					case "FUNCTION":{_stuff.instance();}
				}
			}
		});
	}

	private function onLoad():Void {
		if(loadedAll){return;} loadedAll = true;
		trace('Loaded All -> $TARGET');
		VoidState.clearAssets = false;
		MusicBeatState._switchState(TARGET);
	}
}