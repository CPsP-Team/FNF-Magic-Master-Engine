package substates;

import flixel.group.FlxGroup.FlxTypedGroup;
import objects.scripts.Script;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import states.MusicBeatState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import states.VoidState;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.FlxG;

using utils.Files;

class FadeSubState extends FlxSubState {
	public static var fade:FlxSprite;

    public var targetState:FlxState;

	private var curCamera:FlxCamera;
    
    public function new(?_targetState:FlxState){
        this.targetState = _targetState;
		curCamera = new FlxCamera();
		curCamera.bgColor = FlxColor.BLACK;
		curCamera.bgColor.alpha = 0;
		FlxG.cameras.add(curCamera);
        super();
	}

    override function create():Void {
        fade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        fade.alpha = (targetState != null) ? 0 : 1;
        fade.cameras = [curCamera];
        
        var doTransition:Void->Void = function(){
            add(fade);
    
            FlxTween.tween(fade, {alpha: (targetState != null) ? 1 : 0}, 0.5, {onComplete: function(twn:FlxTween) {
                if(targetState != null){
                    MusicBeatState.state.persistentDraw = false;
                    FlxG.switchState(new VoidState(targetState));
                }else{
                    MusicBeatState.state.persistentUpdate = true;
                    close();
                }
            }, ease: FlxEase.linear});
        };

        var tans_script:Script = null;
        for(s in Mods.mod_scripts){if(s.getFunc("transition") == null){continue;} tans_script = s; break;}
        if(tans_script != null){if(tans_script.call("transition", [doTransition])){return;}}
        doTransition();
    }
    
	override function close():Void {
		FlxG.cameras.remove(curCamera);
		curCamera.destroy();

		super.close();
	}
}