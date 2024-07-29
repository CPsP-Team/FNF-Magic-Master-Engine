package objects.game;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import objects.songs.Song.Song_File;
import flixel.group.FlxSpriteGroup;
import objects.scripts.Script;
import haxe.format.JsonParser;
import openfl.utils.AssetType;
import states.MusicBeatState;
import haxe.macro.Expr.Catch;
import flixel.util.FlxColor;
import flash.geom.Rectangle;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import openfl.utils.Assets;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import utils.Scripts;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

typedef Character_File = {
	var name:String;

	var image:String;
	var icon:String;
	var color:String;

	var emote:String;
	var sound:String;

	var script:String;

	var onRight:Bool;
	var antialiasing:Bool;
	var danceIdle:Bool;
	var singTime:Float;

	var scale:Float;

	var camera:Array<Float>;
	var position:Array<Float>;
	var animations:Array<Animation_Data>;
}

typedef Animation_Data = {
	var symbol:String;
	var key:String;
	var fps:Int;

	var loop:Bool;
	var loopTime:Int;

	var indices:Array<Int>;
}

class Character extends FlxSpriteGroup {
	public static var list(get, never):Array<String>;
	public static function get_list():Array<String> {
		var charArray = [];
		
		for(path in Paths.readDirectory('assets/characters')){
			charArray.push(path.split("/").pop());
		}

		return charArray;
	}

	public static function parse(charFile:Character_File):Void {
		if(charFile.icon == null){charFile.icon = "face";}

		if(charFile.image == null){charFile.image = "BOYFRIEND";}
		if(charFile.animations == null){charFile.animations = [];}

		if(charFile.position == null){charFile.position = [0, 0];}		
		if(charFile.camera == null){charFile.camera = [0, 0];}
		
		if(charFile.color == null){charFile.color = "#75ff73";}

		if(charFile.emote == null){charFile.emote = "hey";}
		if(charFile.sound == null){charFile.sound = "hey";}
	}

	public static function getFocus(song:Song_File, section:Int, ?strum:Int):Int {
		section = Std.int(Math.min(section, song.sections.length - 1));
		section = Std.int(Math.max(section, 0));
		
		var strum_list = song.strums;
		var focused_strum = strum != null ? strum : song.sections[section].strum;
		var focused_character = song.sections[section].character;

		if(strum_list == null || strum_list[focused_strum] == null){return 0;}
		if(strum_list[focused_strum].sections[section] != null && strum_list[focused_strum].sections[section].changeCharacters){return strum_list[focused_strum].sections[section].characters[focused_character];}
		return strum_list[focused_strum].characters[focused_character];
	}

	public static function setCamera(char:Character, cam:FlxObject, stage:Stage){
		if(char == null){return;} if(cam == null){return;}

		var camMoveX = char.x;
		var camMoveY = char.y;

		camMoveX += char.cameraPosition[0];
		camMoveY += char.cameraPosition[1];
		
		if(stage != null){
			if(stage.camP_1 != null){
				camMoveX = Math.max(camMoveX, stage.camP_1[0]);
				camMoveY = Math.max(camMoveY, stage.camP_1[1]);
			}
			if(stage.camP_2 != null){
				camMoveX = Math.min(camMoveX, stage.camP_2[0]);
				camMoveY = Math.min(camMoveY, stage.camP_2[1]);
			}
		}

		if(Settings.get("MoveCamera")){
			if(char.curAnim.contains("UP")){
				camMoveY -= 25;
			}else if(char.curAnim.contains("DOWN")){
				camMoveY += 25;
			}else if(char.curAnim.contains("LEFT")){
				camMoveX -= 25;
			}else if(char.curAnim.contains("RIGHT")){
				camMoveX += 25;
			}
		}

		if(stage != null){
			if(stage.camP_1 != null){
				camMoveX = Math.max(camMoveX, stage.camP_1[0]);
				camMoveY = Math.max(camMoveY, stage.camP_1[1]);
			}
			if(stage.camP_2 != null){
				camMoveX = Math.min(camMoveX, stage.camP_2[0]);
				camMoveY = Math.min(camMoveY, stage.camP_2[1]);
			}
		}

		
		cam.setPosition(FlxMath.lerp(cam.x, camMoveX, FlxG.elapsed * 20), FlxMath.lerp(cam.y, camMoveY, FlxG.elapsed * 20));
	}

	public static function cache(list:Array<Dynamic>, character:String = 'Boyfriend', aspect:String = 'Default', ?type:String, onlyThis:Bool = false):Void {
		var char_path:String = Paths.character(character, aspect, type);
		var char_file:Character_File = cast char_path.getJson();
		Character.parse(char_file);

		list.push({type: IMAGE, instance: Paths.image('characters/${character}/${char_file.image}')});
		list.push({type: IMAGE, instance: Paths.image('icons/icon-${char_file.icon}')});
		list.push({type: SOUND, instance: Paths.sound('emotes/${char_file.sound}')});

		var script_path:String = Paths._character(character, '${char_file.script}.hx');
		if(Paths.exists(script_path)){Scripts.quick(script_path).call('cache', [list]);}
		
		if(onlyThis){return;}

		if(Paths.exists(Paths.character(character, aspect, "Death"))){Character.cache(list, character, aspect, "Death", true);}
		if(Paths.exists(Paths.character(character, aspect, "Result"))){Character.cache(list, character, aspect, "Result", true);}
	}

	public static var DEFAULT_CHARACTER:String = 'Boyfriend';

	public var data:Character_File;
	public var script:Script;
	public var c:FlxSprite;

	public var curCharacter:String = DEFAULT_CHARACTER;
	public var curAspect:String = "Default";
	public var curType:String = null;
	public var curLayer:Int = 0;

	public var specialAnim:Bool = false;
	public var dancedIdle:Bool = false;
	public var noDance:Bool = false;
	public var onRight:Bool = true;

	public var singTimer:Float = 4;
	public var holdTimer:Float = 0;

	public var animEmote:String = "hey";
	public var soundEmote:String = "hey";

	public var icon:String = 'face';
	public var barcolor:FlxColor = 0xffffff;
	public var animations:Map<String, Animation_Data> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var onDebug:Bool = false;
	public var image:String = '';

	public function new(x:Float, y:Float, ?character:String = 'Boyfriend', ?aspect:String = 'Default', ?type:String):Void {
		this.curCharacter = character;
		this.curAspect = aspect;
		this.curType = type;
		super(x, y);

		setupByFile();
	}

	public function setupByName(?_character:String, ?_aspect:String, ?_type:String):Void {
		if(_character != null){curCharacter = _character;}
		if(_aspect != null){curAspect = _aspect;}
		if(_type != null){curType = _type;}
		setupByFile();
	}

	public function setupByFile(?new_file:Character_File):Void {
		var char_path:String = Paths.character(curCharacter, curAspect, curType);
		if(new_file == null){new_file = cast char_path.getJson();}

		Character.parse(new_file);
		data = new_file;

		curCharacter = data.name;

		this.icon = data.icon;
		this.image = data.image;
		this.animEmote = data.emote;
		this.soundEmote = data.sound;
		this.singTimer = data.singTime;
		this.dancedIdle = data.danceIdle;
		this.cameraPosition = data.camera;
		this.positionArray = data.position;
		this.antialiasing = data.antialiasing;
		this.barcolor = FlxColor.fromString(data.color);

		
		animations.clear();
		for(a in data.animations){animations.set(a.key, a);}

		if(script != null){
			script.destroy();
			script = null;
		}

		if(Paths.exists(Paths._character(curCharacter, '${data.script}.hx'))){
			script = new Script();
			script.name = '${curCharacter}_Script';
			script.setVar("instance", this);
			script.load(Paths._character(curCharacter, '${data.script}.hx'), true);
		}

		setGraphic();

		turnLook(onRight);

		dance();
	}

	public function setGraphic(?_image:String):Void {
		if(_image != null){this.image = _image;}
		this.clear();

		c = new FlxSprite(positionArray[0], positionArray[1]);

		c.antialiasing = data.antialiasing;

		var new_path:String = Paths.image('characters/${curCharacter}/${image}');
		c.frames = new_path.getAtlas();

		if(animations != null){
			for(anim in animations){
				var animAnim:String = '' + anim.key;
				var animName:String = '' + anim.symbol;
				var animFps:Int = anim.fps;
				var animLoop:Bool = anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;

				if(animIndices != null && animIndices.length > 0){
					c.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}else{
					c.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		}

		dance();

		scaleCharacter();

		if(script != null){script.call('preload');}

		this.add(c);

		if(script != null){script.call('postload');}
	}
	
	private var oldBeat:Int = -1;
	override function update(elapsed:Float){
		if(!onDebug && !noDance){
			if(holdTimer > 0){
				holdTimer -= elapsed;
			}else{
				if(MusicBeatState.state.curBeat != oldBeat){
					dance();
				}
			}
		}

		if(curPAnim() != null && curPAnim().finished && getAnim('${curAnim}-loop') != null){
			c.animation.play('${curAnim}-loop');
		}

		oldBeat = MusicBeatState.state.curBeat;
		
		if(curPAnim() != null && curPAnim().finished && specialAnim){specialAnim = false;}

		super.update(elapsed);

		if(script != null){script.call('update', [elapsed]);}
	}

	private var isDanceRight:Bool = false;
	public function dance():Void {
		if(specialAnim || (script != null && script.call('dance') == Stop)){return;}

		if(dancedIdle){
			isDanceRight = !isDanceRight;
			c.animation.play(isDanceRight ? 'danceRight' : 'danceLeft', true);
		}else{
			c.animation.play('idle');
		}

		curAnim = aniName();
	}

	public var curAnim:String = "";
	public function playEmote():Void {
		if((script != null && script.call('emote') == Stop)){return;}
		FlxG.sound.play(Paths.sound('emotes/${soundEmote}').getSound());
		singAnim(animEmote, true);
	}
	public function singAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {
		playAnim(AnimName, Force, Special);
		holdTimer = singTimer;
	}
	public function playAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {
		if(specialAnim && !Special){return;}
		if(script != null && script.call('playAnim', [AnimName, Force])){return;}
		if(c == null){return;}
		if(c.animation.getByName(AnimName) == null){return;}
		
		specialAnim = Special;
		curAnim = '$AnimName';
		
		if(c.flipX){
			if(AnimName.contains("LEFT")){AnimName = AnimName.replace("LEFT", "RIGHT");}
			else{AnimName = AnimName.replace("RIGHT", "LEFT");}
		}
		
		c.animation.play(AnimName, (animations.exists(AnimName) && curPAnim() != null && curPAnim().curFrame >= animations[AnimName].loopTime) || Force);
	}

	public function aniName():String {if(c.animation.curAnim == null){return "";} return c.animation.curAnim.name;}
	public function getAnim(name:String){return c.animation.getByName(name);}
	public function curPAnim(){return c.animation.curAnim;}

	public function turnLook(toRight:Bool = true):Void {
		onRight = toRight;
		c.flipX = onRight ? !data.onRight : data.onRight;
		if(script != null){script.call('turnLook', [toRight]);}
	}

	public function scaleCharacter(_scale:Float = 1):Void {
		var new_scale = _scale * data.scale;
		c.scale.set(new_scale, new_scale);
		c.updateHitbox();
	}

	override public function destroy():Void {
		super.destroy();

		if(script != null){
			script.destroy();
			script = null;
		}
	}
}
