package flixel.system;

import flixel.ui.*;
import flixel.util.*;
import flixel.addons.ui.*;
import flixel.addons.ui.interfaces.*;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import openfl.display.Shader;
import flixel.sound.FlxSound;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import openfl.display.GraphicsShader;
import flixel.addons.text.FlxTypeText;
import flixel.addons.ui.FlxUI.NamedFloat;
import flixel.system.FlxAssets.FlxShader;

using utils.Files;
using StringTools;

#if FLX_DRAW_QUADS
class FlxCustomShader extends FlxShader {
    public static var shaders:Array<FlxCustomShader> = [];

    @:glFragmentHeader('
        #define iResolution openfl_TextureSize
        #define iChannel0 bitmap
        
        uniform float iTime;
        uniform vec2 iScroll;
        uniform vec4 iMouse;
        uniform float iFrame;
        uniform float iTimeDelta;

        uniform vec3 iGlobalResolution;
    ')
	@:glFragmentSource("
        #pragma header
    ")

    public function new(options:{?fragmentsrc:String, ?vertexsrc:String}){
        if(options.fragmentsrc != null){this.glFragmentSource += '${options.fragmentsrc}';}
        if(options.vertexsrc != null){this.glVertexSource += '${options.vertexsrc}';}
        this.glFragmentSource += '
            void main(){
                gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
                vec2 coord = openfl_TextureCoordv;
                vec2 fragCoord = (coord * openfl_TextureSize);
                mainImage(gl_FragColor, fragCoord);
            }
        ';
        super();
        
		iTime.value = [0.0];
		iTimeDelta.value = [0.0];
        iScroll.value = [0.0, 0.0];
		iMouse.value = [0.0, 0.0, 0.0, 0.0];
		iFrame.value = [FlxG.game.focusLostFramerate];
		iGlobalResolution.value = [FlxG.width, FlxG.height, 0];

        FlxCustomShader.shaders.push(this);
    }

    public function update(elapsed:Float):Void {
        iTime.value[0] += elapsed;
        iTimeDelta.value[0] = elapsed;

        iMouse.value[0] = FlxG.mouse.screenX;
        iMouse.value[1] = FlxG.mouse.screenY;
        iMouse.value[2] = FlxG.mouse.pressed ? FlxG.mouse.screenX : 0.0;
        iMouse.value[2] = FlxG.mouse.pressed ? FlxG.mouse.screenY : 0.0;
        
        iScroll.value = [FlxG.camera.scroll.x, FlxG.camera.scroll.y];
    }

    public function set_value(field:String, value:Dynamic):Void {
        if(!Reflect.hasField(this, field)){return;}
        Reflect.getProperty(this, field).value = [value];
    }
}
#end