package flixel.system;

import flixel.util.*;
import flixel.addons.ui.*;
import flixel.addons.ui.interfaces.*;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxCustomShader;
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
import objects.scripts.Script;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using utils.Files;

class FlxShaderColorSwap extends FlxCustomShader {
    public static var shader_list:Array<FlxShaderColorSwap> = [];

    @:glFragmentHeader('
        uniform int checkColor;
        uniform int typeChange;
        uniform vec3 replaceColor;
        uniform vec3 replaceColor2;
    ')
	@:glFragmentSource("
        #pragma header

        vec4 get_grad(vec3 color1, vec3 color2){
            float normalizedX = openfl_TextureCoordv.x / openfl_TextureSize.x;
            vec3 blendedColor = mix(color1, color2, normalizedX);
            return vec4(blendedColor, 1.0);
        }

        vec3 norm_color(vec3 color){
            return vec3(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0);
        }
        
        float transform_color(int rep_color, int check_color, vec4 texColor, vec4 repColor){
            if(rep_color == 0){
                float diff = texColor.r - ((texColor.b + texColor.g) / 2.0);
                if(check_color == 0){
                    return (texColor.b + texColor.g) / 2.0 + (diff * repColor.r);
                }else if(check_color == 1){
                    return texColor.g + (repColor.g * diff);
                }else if(check_color == 2){
                    return texColor.b + (repColor.b * diff);
                }
            }else if(rep_color == 1){
                float diff = texColor.g - ((texColor.r + texColor.b) / 2.0);
                if(check_color == 0){
                    return texColor.r + (repColor.r * diff);
                }else if(check_color == 1){
                    return (texColor.r + texColor.b) / 2.0 + (diff * repColor.g);
                }else if(check_color == 2){
                    return texColor.b + (repColor.b * diff);
                }
            }else if(rep_color == 2){
                float diff = texColor.b - ((texColor.r + texColor.g) / 2.0);
                if(check_color == 0){
                    return texColor.r + (repColor.r * diff);
                }else if(check_color == 1){
                    return texColor.g + (repColor.g * diff);
                }else if(check_color == 2){
                    return (texColor.r + texColor.g) / 2.0 + (diff * repColor.b);
                }
            }else{
                if(check_color == 0){
                    return texColor.r;
                }else if(check_color == 1){
                    return texColor.g;
                }else if(check_color == 2){
                    return texColor.b;
                }
            }
            return 0.0;
        }
        
        void mainImage(out vec4 fragColor, in vec2 fragCoord){    
            vec4 texColor = flixel_texture2D(iChannel0, fragCoord / iResolution.xy);
            
            vec4 repColor;
            if(typeChange == 0){
                repColor = vec4(norm_color(replaceColor), 1.0);
            }else if(typeChange == 1){
                repColor = get_grad(norm_color(replaceColor), norm_color(replaceColor2));
            }
        
            vec4 newColor = vec4(
                transform_color(checkColor, 0, texColor, repColor),
                transform_color(checkColor, 1, texColor, repColor),
                transform_color(checkColor, 2, texColor, repColor),
                texColor.a
            );
        
            fragColor = newColor;
        }
    ")

    public var v_typeChange(default, set):Int = 0;
    public function set_v_typeChange(value:Int):Int {
        this.typeChange.value = [value];
        return v_typeChange = value;
    }

    public var v_checkColor(default, set):String = "Blue";
    public function set_v_checkColor(value:String):String {
        var toSet:Int = -1;
        switch(value){
            case "Red":{toSet = 0;}
            case "Green":{toSet = 1;}
            case "Blue":{toSet = 2;}
        }
        this.checkColor.value = [toSet];
        return v_checkColor = value;
    }
    
    public var v_replaceColor(default, set):FlxColor;
    public function set_v_replaceColor(value:FlxColor):FlxColor {
        this.replaceColor.value = [value.red, value.green, value.blue];
        return v_replaceColor = value;
    }
    public var v_replaceColor2(default, set):FlxColor;
    public function set_v_replaceColor2(value:FlxColor):FlxColor {
        this.replaceColor2.value = [value.red, value.green, value.blue];
        return v_replaceColor2 = value;
    }

    public static function get_shader(new_checkColor:String = "Blue", new_replaceColor:FlxColor, ?new_secondColor:FlxColor):FlxShaderColorSwap {
        for(s in shader_list){
            if(s.v_checkColor != new_checkColor){continue;}
            if(s.v_replaceColor != new_replaceColor){continue;}
            if(new_secondColor != null && s.v_replaceColor2 != new_secondColor){continue;}
            return s;
        }
        return new FlxShaderColorSwap(new_checkColor, new_replaceColor, new_secondColor);
    }
    public function new(new_checkColor:String = "Blue", new_replaceColor:FlxColor, ?new_secondColor:FlxColor):Void {
        super({});
        v_typeChange = 0;
        v_checkColor = new_checkColor;
        v_replaceColor = new_replaceColor;
        if(new_secondColor != null){v_replaceColor2 = new_secondColor; v_typeChange = 1;}

        shader_list.push(this);
    }
}