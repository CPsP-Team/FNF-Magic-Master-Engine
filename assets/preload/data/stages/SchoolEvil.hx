import("PreSettings", "PreSettings");
import("utils.Files", "Files");
import("utils.Paths", "Paths");
import("flixel.FlxSprite", "FlxSprite");

preset("initChar", 1);
preset("camP_1", [430,310]);
preset("camP_2", [1080,600]);
preset("zoom", 1.1);

var sky:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('animatedEvilSchool','stages/schoolEvil')});
}

function create():Void {
	sky = new FlxSprite(500, 200);
	sky.scale.set(6, 6);
	sky.updateHitbox();
	sky.antialiasing = false;
	sky.frames = Files.getAtlas(Paths.image('animatedEvilSchool', 'stages/schoolEvil'));
	sky.animation.addByPrefix('idle', 'background 2 instance 1');
	if(PreSettings.getPreSetting('Background Animated', 'Graphic Settings')){sky.animation.play('idle');}
	add(sky);

}