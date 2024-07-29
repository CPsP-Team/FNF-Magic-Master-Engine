import("flixel.FlxSprite", "FlxSprite");
import("PreSettings", "PreSettings");
import("utils.Files", "Files");
import("flixel.FlxG", "FlxG");
import("utils.Paths", "Paths");

preset("initChar", 0);
preset("camP_1", [400,230]);
preset("camP_2", [1300,570]);
preset("zoom", 1.1);

var background:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('halloween_bg','stages/spooky')});
	temp.push({type: "SOUND", instance: Paths.image('thunder_1','stages/spooky')});
	temp.push({type: "SOUND", instance: Paths.image('thunder_2','stages/spooky')});
}

function create():Void {
	background = new FlxSprite(-200, -110);
	background.frames = Files.getAtlas(Paths.image('halloween_bg', 'stages/spooky'));
	background.animation.addByPrefix('idle', 'halloweem bg lightning strike', 30, false);
	background.animation.play('idle');
	add(background);

	pushGlobal();
}

var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;
function beatHit(curBeat:Int):Void {
	if(!PreSettings.getPreSetting("Background Animated", "Graphic Settings")){return;}
    if(FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset){lightningStrikeShit(curBeat);}
}

function lightningStrikeShit(curBeat:Int):Void {
	FlxG.sound.play(Files.getSound(Paths.soundRandom('thunder_', 1, 2, 'stages/spooky')));
	background.animation.play('idle');
	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);
    for(i in 0...getState().stage.character_Length){getState().stage.getCharacterById(i).singAnim('scared');}
}