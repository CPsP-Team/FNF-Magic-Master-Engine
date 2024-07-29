
import("flixel.tweens.FlxTween", "FlxTween");
import("states.PlayState", "PlayState");
import("flixel.FlxSprite", "FlxSprite");
import("flixel.FlxObject", "FlxObject");
import("flixel.FlxG", "FlxG");

import("Files");
import("Character");
import("Paths");
import("Type");

var gunsCinematic:FlxSprite;

var tankman:Character;
var boyfriend:Character;
var girlfriend:Character;

var camFollow:FlxObject;

var onCinematic:Bool = false;
var total_time:Float = 0;
var total_events:Int = 0;
var startCountdown:Void->Void = function(){};

function addToLoad(list:Array<Dynamic>){
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return;}
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/guns", "stages/war")});
    list.push({type: "MUSIC", instance: Paths.music("DISTORTO", "stages/war")});
    list.push({type: "SOUND", instance: Paths.sound("guns_1", "stages/war")});
}

function preload():Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return;}
    tankman = stage.getCharacterByName("Tankman");
    boyfriend = stage.getCharacterByName("Boyfriend");
    girlfriend = stage.getCharacterByName("Girlfriend");

    gunsCinematic = new FlxSprite(tankman.x - 160, tankman.y + 110);
    gunsCinematic.frames = Files.getSparrowAtlas(Paths.image("cutscenes/guns", "stages/war"));
    gunsCinematic.animation.addByPrefix("play", "TANK TALK 2", 24, false);
    tankman.add(gunsCinematic);

    tankman.c.visible = false;

    camFollow = camFollow;
}

function startSong(_startCountdown:Void->Void):Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}
    startCountdown = _startCountdown;
    onCinematic = true;

    Character.setCameraToCharacter(tankman, camFollow, stage);

    FlxG.sound.playMusic(Files.getSound(Paths.music("DISTORTO", "stages/war")));
    FlxG.sound.music.fadeIn();

    FlxTween.tween(camHUD, {alpha: 0}, 0.5);

    return true;
}

function update(elapsed:Float){
    if(!onCinematic){return;}
    total_time += elapsed;

    if(total_time >= 0.5 && total_events == 0){
        total_events++;

        gunsCinematic.animation.play("play");
        FlxG.sound.play(Files.getSound(Paths.sound("guns_1", "stages/war")), 1, false, null, true);
    }else if(total_time >= 4.65 && total_events == 1){
        total_events++;

        girlfriend.playAnim("sad", true, true, false, 0);
    }else if(total_time >= 11.5 && total_events == 2){
        total_events++;

        tankman.c.visible = true;

        gunsCinematic.kill();

        FlxG.sound.music.fadeOut();
        FlxTween.tween(camHUD, {alpha: 1}, 0.5);
        startCountdown();
    }else if(total_time >= 12 && total_events == 3){
        total_events++;
        
        tankman.remove(gunsCinematic);
        gunsCinematic.destroy();

        onCinematic = false;
    }
}