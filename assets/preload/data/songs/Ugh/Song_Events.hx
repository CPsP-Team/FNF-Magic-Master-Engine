
import("flixel.tweens.FlxTween", "FlxTween");
import("states.PlayState", "PlayState");
import("flixel.FlxSprite", "FlxSprite");
import("flixel.FlxObject", "FlxObject");
import("flixel.FlxG", "FlxG");

import("Character");
import("Paths");
import("Files");
import("Type");

var ughCinematic:FlxSprite;

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
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/ugh", "stages/war")});
    list.push({type: "MUSIC", instance: Paths.music("DISTORTO", "stages/war")});
    list.push({type: "SOUND", instance: Paths.sound("ugh_1", "stages/war")});
    list.push({type: "SOUND", instance: Paths.sound("ugh_2", "stages/war")});
    list.push({type: "SOUND", instance: Paths.sound("ugh_3", "stages/war")});
}

function preload():Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}

    tankman = stage.getCharacterByName("Tankman");
    boyfriend = stage.getCharacterByName("Boyfriend");
    girlfriend = stage.getCharacterByName("Girlfriend");

    ughCinematic = new FlxSprite(tankman.x - 160, tankman.y + 110);
    ughCinematic.frames = Files.getSparrowAtlas(Paths.image("cutscenes/ugh", "stages/war"));
    ughCinematic.animation.addByPrefix("play_1", "TANK TALK 1 P1", 24, false);
    ughCinematic.animation.addByPrefix("play_2", "TANK TALK 1 P2", 24, false);
    ughCinematic.visible = true;
    tankman.add(ughCinematic);

    tankman.c.visible = false;

    camFollow = camFollow;
}

function startSong(_startCountdown:Void->Void):Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}
    startCountdown = _startCountdown;
    onCinematic = true;

    girlfriend.dance();
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

        ughCinematic.animation.play("play_1");
        FlxG.sound.play(Files.getSound(Paths.sound("ugh_1", "stages/war")), 1, false, null, true);
    }else if(total_time >= 3 && total_events == 1){
        total_events++;

        Character.setCameraToCharacter(boyfriend, camFollow, stage);
    }else if(total_time >= 4 && total_events == 2){
        total_events++;

        boyfriend.playAnim("singUP");
        FlxG.sound.play(Files.getSound(Paths.sound("ugh_2", "stages/war")), 1, false, null, true);
    }else if(total_time >= 4.35 && total_events == 3){
        total_events++;

        boyfriend.playAnim("idle");
    }else if(total_time >= 5.35 && total_events == 4){
        total_events++;

        Character.setCameraToCharacter(tankman, camFollow, stage);
        ughCinematic.animation.play("play_2");
        FlxG.sound.play(Files.getSound(Paths.sound("ugh_3", "stages/war")), 1, false, null, true);
    }else if(total_time >= 11.35 && total_events == 5){
        total_events++;

        tankman.c.visible = true;

        ughCinematic.kill();

        FlxG.sound.music.fadeOut();
        FlxTween.tween(camHUD, {alpha: 1}, 0.5);                            
        startCountdown();
    }else if(total_time >= 12 && total_events == 6){
        total_events++;

        tankman.remove(ughCinematic);
        ughCinematic.destroy();
        
        onCinematic = false;
    }
}