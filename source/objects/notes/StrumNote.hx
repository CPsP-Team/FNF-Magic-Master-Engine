package objects.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxShaderColorSwap;
import flixel.system.FlxCustomShader;
import objects.scripts.Script;
import haxe.format.JsonParser;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using utils.Files;

typedef Note_Graphic_Data = {
    var animations:Array<Note_Animation_Data>;
    var antialiasing:Bool;
    var sing_animation:String;
    var color:String;
}

typedef Note_Animation_Data = {
    var anim:String;
    var symbol:String;
    var indices:Array<Int>;

    var fps:Int;
    var loop:Bool;
}

class StrumNote extends FlxSprite {
    public static var IMAGE_DEFAULT:String = "NOTE_assets";
    public static var STYLE_DEFAULT:String = "Default";

    public static var global_suffix:String = "";
    public static var global_prefix:String = "";

    public var splashImage:String = Settings.get("SplashSkin");
    public var type:String = Settings.get("NoteSkin");
    public var image:String = IMAGE_DEFAULT;
    public var style:String = STYLE_DEFAULT;

    public var noteData:Int = 0;
    public var noteKeys:Int = 4;

    public var playColor:FlxColor = FlxColor.TRANSPARENT;
    
    public var useColor(default, set):Bool = true;
    public function set_useColor(value:Bool):Bool {
        shader = value ? FlxShaderColorSwap.get_shader(note_path.getColorNote(), playColor) : null;        
        return useColor = value;
    }

    public var singAnimation:String = null;

    public var note_path:String = "";

	public function new(_data:Int = 0, _keys:Int = 4, ?_image:String, ?_style:String, ?_type:String){
        if(_image != null){image = _image;}
        if(_style != null){style = _style;}
        if(_type != null){type = _type;}
        this.noteData = _data;
        this.noteKeys = _keys;
        super();

        loadNote();
	}

    public function setupData(_data:Int, ?_keys:Int){
        if(_keys != null){noteKeys = _keys;}
        noteData = _data;
        loadNote();
    }

    public function loadNote(?_image:String, ?_style:String, ?_type:String){
        var last_anim:String = (this.animation != null && this.animation.curAnim != null) ? this.animation.curAnim.name : "static";
        if(_image != null){image = _image;} if(_style != null){style = _style;} if(_type != null){type = _type;}

        note_path = Paths.note(image, style, type);

        frames = note_path.getAtlas();
        var n_json:Note_Graphic_Data = (this is Note) ? Files.getDataNote(noteData, noteKeys, type) : Files.getDataStaticNote(noteData, noteKeys, type);
        
        playColor = n_json.color != null ? FlxColor.fromString(n_json.color) : 0xffffff;  
        antialiasing = n_json.antialiasing && !style.contains("pixel-");
        singAnimation = n_json.sing_animation;

        shader = useColor ? FlxShaderColorSwap.get_shader(note_path.getColorNote(), playColor) : null;

        if(frames == null || n_json.animations == null || n_json.animations.length <= 0){return;}

        for(anim in n_json.animations){
            if(anim.indices != null && anim.indices.length > 0){animation.addByIndices(anim.anim, anim.symbol, anim.indices, "", anim.fps, anim.loop);}
            else{animation.addByPrefix(anim.anim, anim.symbol, anim.fps, anim.loop);}
        }

        playAnim(last_anim);
    }
    public function addAnim(anim:String, symbol:String, fps:Int, loop:Bool):Void {
        animation.addByPrefix(anim, symbol, fps, loop);
    }

    public function playAnim(anim:String, force:Bool = false){
		animation.play(anim, force);
	}
}