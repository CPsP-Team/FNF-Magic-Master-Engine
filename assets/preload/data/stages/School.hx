import("PreSettings", "PreSettings");
import("utils.Files", "Files");
import("utils.Paths", "Paths");
import("flixel.FlxSprite", "FlxSprite");
import("states.PlayState", "PlayState");

preset("initChar", 6);
preset("camP_1", [380,310]);
preset("camP_2", [930,530]);
preset("zoom", 1);

var sky:FlxSprite = null;
var school:FlxSprite = null;
var street:FlxSprite = null;
var backtrees:FlxSprite = null;
var fronttrees:FlxSprite = null;
var petals:FlxSprite = null;
var girls:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('weebSky','stages/school')});
	temp.push({type: "IMAGE", instance: Paths.image('weebSchool','stages/school')});
	temp.push({type: "IMAGE", instance: Paths.image('weebStreet','stages/school')});
	temp.push({type: "IMAGE", instance: Paths.image('weebTreesBack','stages/school')});
	temp.push({type: "IMAGE", instance: Paths.image('weebTrees','stages/school')});
	temp.push({type: "IMAGE", instance: Paths.image('petals','stages/school')});
	temp.push({type: "IMAGE", instance: Paths.image('bgFreaks','stages/school')});
}

function create():Void {
	sky = new FlxSprite(500, 350);
	sky.scale.set(6, 6);
	sky.updateHitbox();
	sky.scrollFactor.set(0.1, 0.1);
	sky.loadGraphic(Files.getGraphic(Paths.image('weebSky', 'stages/school')));
	sky.antialiasing = false;
	add(sky);

	school = new FlxSprite(-277, 0);
	school.antialiasing = false;
	school.loadGraphic(Files.getGraphic(Paths.image('weebSchool', 'stages/school')));
	school.scale.set(6, 6);
	school.updateHitbox();
	school.scrollFactor.set(0.3, 1);
	add(school);

	street = new FlxSprite(-277, 0);
	street.antialiasing = false;
	street.loadGraphic(Files.getGraphic(Paths.image('weebStreet', 'stages/school')));
	street.scale.set(6, 6);
	street.updateHitbox();
	add(street);

	backtrees = new FlxSprite(-277, 0);
	backtrees.loadGraphic(Files.getGraphic(Paths.image('weebTreesBack', 'stages/school')));
	backtrees.scale.set(6, 6);
	backtrees.updateHitbox();
	backtrees.antialiasing = false;
	add(backtrees);

	fronttrees = new FlxSprite(-890, -1110);
	fronttrees.antialiasing = false;
	fronttrees.frames = Files.getAtlas(Paths.image('weebTrees', 'stages/school'));
	fronttrees.animation.addByPrefix('idle', 'trees');
	if(PreSettings.getPreSetting('Background Animated', 'Graphic Settings')){fronttrees.animation.play('idle');}
	fronttrees.scale.set(6, 6);
	fronttrees.updateHitbox();
	add(fronttrees);

	petals = new FlxSprite(500, 450);
	petals.antialiasing = false;
	petals.scale.set(6, 6);
	petals.updateHitbox();
	petals.frames = Files.getAtlas(Paths.image('petals', 'stages/school'));
	petals.animation.addByPrefix('idle', 'PETALS ALL');
	if(PreSettings.getPreSetting('Background Animated', 'Graphic Settings')){petals.animation.play('idle');}
	add(petals);

	girls = new FlxSprite(502, 351);
	girls.antialiasing = false;
	girls.scale.set(6, 6);
	girls.updateHitbox();
	girls.frames = Files.getAtlas(Paths.image('bgFreaks', 'stages/school'));
	girls.animation.addByPrefix('idle', 'BG girls group');
	girls.animation.addByPrefix('freak', 'BG fangirls dissuaded');
	if(PreSettings.getPreSetting('Background Animated', 'Graphic Settings')){
		girls.animation.play('idle');
		if(PlayState.SONG.song == "Roses"){
			girls.animation.play('freak');
		}
	}
	add(girls);
}