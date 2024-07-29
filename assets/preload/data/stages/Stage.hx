import utils.Files;
import utils.Paths;
import flixel.FlxSprite;

preset("initChar", 1);
preset("camP_1", [250,180]);
preset("camP_2", [1095,800]);
preset("zoom", 0.9);

var stageback:FlxSprite = null;
var stagefront:FlxSprite = null;
var stagelight1:FlxSprite = null;
var stagelight2:FlxSprite = null;
var stagecurtains:FlxSprite = null;

function cache(list:Array<Dynamic>):Void {
	list.push({type: "IMAGE", instance: Paths.image('stages/stage/stageback')});
	list.push({type: "IMAGE", instance: Paths.image('stages/stage/stagefront')});
	list.push({type: "IMAGE", instance: Paths.image('stages/stage/stage_light')});
	list.push({type: "IMAGE", instance: Paths.image('stages/stage/stage_light')});
	list.push({type: "IMAGE", instance: Paths.image('stages/stage/stagecurtains')});
}

function create():Void {
	stageback = new FlxSprite(-600, -300);
	stageback.loadGraphic(Files.getGraphic(Paths.image('stages/stage/stageback'))); 
	stageback.scrollFactor.set(0.5, 0.5);
	push(stageback);

	stagefront = new FlxSprite(-600, 650);
	stagefront.loadGraphic(Files.getGraphic(Paths.image('stages/stage/stagefront')));
	push(stagefront);

	stagelight1 = new FlxSprite(-125, -100);
	stagelight1.loadGraphic(Files.getGraphic(Paths.image('stages/stage/stage_light')));
	stagelight1.scrollFactor.set(0.9, 0.9);
	push(stagelight1);

	stagelight2 = new FlxSprite(1225, -100);
	stagelight2.flipX = true;
	stagelight2.flipY = false;
	stagelight2.scrollFactor.set(0.9, 0.9);
	stagelight2.loadGraphic(Files.getGraphic(Paths.image('stages/stage/stage_light')));
	push(stagelight2);

	stagecurtains = new FlxSprite(-600, -300);
	stagecurtains.scrollFactor.set(1.3, 1.3);
	stagecurtains.loadGraphic(Files.getGraphic(Paths.image('stages/stage/stagecurtains')));
	push(stagecurtains);
}