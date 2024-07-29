import("flixel.group.FlxTypedGroup", "FlxTypedGroup");
import("flixel.util.FlxTimer", "FlxTimer");
import("flixel.FlxSprite", "FlxSprite");
import("PreSettings", "PreSettings");
import("utils.Files", "Files");
import("flixel.FlxG", "FlxG");
import("utils.Paths", "Paths");
import("Type", "Type");

preset("initChar", 4);
preset("camP_1", [250,-1000]);
preset("camP_2", [900,450]);
preset("zoom", 0.9);

var fastCarCanDrive:Bool = true;
var isLeftDancing:Bool = false;
var carTimer:FlxTimer;

var sunset:FlxSprite = null;
var backlimo:FlxSprite = null;
var dancers:FlxTypedGroup<FlxSprite> = null;
var fastcar:FlxSprite = null;
var frontlimo:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('limoSunset','stages/limo')});
	temp.push({type: "IMAGE", instance: Paths.image('bgLimo','stages/limo')});
	temp.push({type: "IMAGE", instance: Paths.image('limoDancer', 'stages/limo')});
	temp.push({type: "IMAGE", instance: Paths.image('fastCarLol','stages/limo')});
	temp.push({type: "IMAGE", instance: Paths.image('limoDrive','stages/limo')});
	temp.push({type: "SOUND", instance: Paths.sound('carPass0','stages/limo')});
	temp.push({type: "SOUND", instance: Paths.sound('carPass1','stages/limo')});
}

function create():Void {
	sunset = new FlxSprite(-350, -300);
	sunset.scrollFactor.set(0.1, 0.1);
	sunset.loadGraphic(Files.getGraphic(Paths.image('limoSunset', 'stages/limo')));
	add(sunset);

	backlimo = new FlxSprite(-380, 400);
	backlimo.frames = Files.getAtlas(Paths.image('bgLimo', 'stages/limo'));
	backlimo.animation.addByPrefix('idle', 'background limo pink');
	if(PreSettings.getPreSetting('Background Animated', 'Graphic Settings')){backlimo.animation.play('idle');}
	backlimo.scrollFactor.set(0.4, 0.4);
	add(backlimo);

	dancers = Type.createInstance(FlxTypedGroup, []);
	for(i in 0...5){
		var dancer:FlxSprite = new FlxSprite(140 + (370 * i), 0);
		dancer.frames = Files.getAtlas(Paths.image('limoDancer', 'stages/limo'));
		dancer.scrollFactor.set(0.4, 0.4);
		dancer.animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], '', 24, false);
		dancer.animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], '', 24, false);
		dancer.animation.play('danceLeft');
		dancers.add(dancer);
	}
	add(dancers);

	fastcar = new FlxSprite(-530, -30);
	fastcar.loadGraphic(Files.getGraphic(Paths.image('fastCarLol', 'stages/limo')));
	add(fastcar);

	frontlimo = new FlxSprite(-350, 300);
	frontlimo.frames = Files.getAtlas(Paths.image('limoDrive', 'stages/limo'));
	frontlimo.animation.addByPrefix('idle', 'Limo stage');
	if(PreSettings.getPreSetting('Background Animated', 'Graphic Settings')){frontlimo.animation.play('idle');}
	add(frontlimo);

	pushGlobal();
	resetFastCar();
}

function beatHit(curBeat:Int):Void {
	if(!PreSettings.getPreSetting("Background Animated", "Graphic Settings")){return;}

	isLeftDancing = !isLeftDancing;
	for(dancer in dancers.members){
		if(isLeftDancing){dancer.animation.play('danceLeft', true);}
		else{dancer.animation.play('danceRight', true);}
	}
	
	if(FlxG.random.bool(10) && fastCarCanDrive){fastCarDrive();}
}

function resetFastCar():Void {
	fastcar.x = -12600;
	fastcar.y = FlxG.random.int(-110, 0);
	fastcar.velocity.x = 0;
	fastCarCanDrive = true;
}

function fastCarDrive(){
	//trace('Car drive');
	FlxG.sound.play(Files.getSound(Paths.soundRandom('carPass', 0, 1, 'stages/limo')), 0.7);
	fastcar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
	fastCarCanDrive = false;
	carTimer = new FlxTimer().start(2, function(tmr:FlxTimer){
		resetFastCar();
		carTimer = null;
	});
}
