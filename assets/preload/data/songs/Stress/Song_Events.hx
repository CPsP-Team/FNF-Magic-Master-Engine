
import("flixel.tweens.FlxTween", "FlxTween");
import("flixel.tweens.FlxEase", "FlxEase");
import("states.PlayState", "PlayState");
import("flixel.FlxSprite", "FlxSprite");
import("flixel.FlxObject", "FlxObject");
import("flixel.FlxG", "FlxG");

import("Character");
import("Files");
import("Paths");
import("Stage");
import("Type");

var gf_idle:FlxSprite;
var bf_idle:FlxSprite;
var gf_demon_1:FlxSprite;
var gf_demon_2:FlxSprite;
var pico_arrives_1:FlxSprite;
var pico_arrives_2:FlxSprite;
var pico_arrives_3:FlxSprite;
var stressCinematic1:FlxSprite;
var stressCinematic2:FlxSprite;

var tankman:Character;
var boyfriend:Character;
var girlfriend:Character;

var camFollow:FlxObject;
var stage:Stage;

var onCinematic:Bool = false;
var total_time:Float = 0;
var total_events:Int = 0;
var startCountdown:Void->Void = function(){};

function addToLoad(list:Array<Dynamic>){
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return;}
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/Pico_Arrives_1", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/Pico_Arrives_2", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/Pico_Arrives_3", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/Gf_Demon_1", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/Gf_Demon_2", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/stress2", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("cutscenes/stress", "stages/war")});
    list.push({type: "MUSIC", instance: Paths.music("DISTORTO", "stages/war")});
    list.push({type: "SOUND", instance: Paths.sound("stress_1", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("GF_IDLE", "stages/war")});
    list.push({type: "IMAGE", instance: Paths.image("BF_IDLE", "stages/war")});
}

function preload():Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}

    tankman = stage.getCharacterByName("Tankman");
    boyfriend = stage.getCharacterByName("Boyfriend");
    girlfriend = stage.getCharacterByName("Pico");

    camFollow = camFollow;
    stage = stage;

    // Tankman Assets
    stressCinematic1 = new FlxSprite(tankman.x - 160, tankman.y + 110);
    stressCinematic1.frames = Files.getSparrowAtlas(Paths.image("cutscenes/stress", "stages/war"));
    stressCinematic1.animation.addByPrefix("play", "TANK TALK 3 P1 UNCUT", 24, false);
    tankman.add(stressCinematic1);
    
    stressCinematic2 = new FlxSprite(tankman.x - 160, tankman.y + 110);
    stressCinematic2.frames = Files.getSparrowAtlas(Paths.image("cutscenes/stress2", "stages/war"));
    stressCinematic2.animation.addByPrefix("play", "TANK TALK 3 P2 UNCUT", 24, false);
    stressCinematic2.visible = false;
    tankman.add(stressCinematic2);
    
    // Pico Assets
    gf_idle = new FlxSprite(-247, 83).loadGraphic(Files.getGraphic(Paths.image("cutscenes/GF_IDLE", "stages/war")));
    girlfriend.add(gf_idle);

    gf_demon_1 = new FlxSprite(-140, 76);
    gf_demon_1.frames = Files.getAtlas(Paths.image("cutscenes/Gf_Demon_1", "stages/war"));
    gf_demon_1.animation.addByPrefix("play", "GF STARTS TO TURN PART 1", 24, false);
    gf_demon_1.visible = false;
    girlfriend.add(gf_demon_1);

    gf_demon_2 = new FlxSprite(-141, 74);
    gf_demon_2.frames = Files.getAtlas(Paths.image("cutscenes/Gf_Demon_2", "stages/war"));
    gf_demon_2.animation.addByPrefix("play", "GF STARTS TO TURN PART 2", 24, false);
    gf_demon_2.visible = false;
    girlfriend.add(gf_demon_2);
        
    pico_arrives_1 = new FlxSprite(-141, 73);
    pico_arrives_1.frames = Files.getAtlas(Paths.image("cutscenes/Pico_Arrives_1", "stages/war"));
    pico_arrives_1.animation.addByPrefix("play", "PICO ARRIVES PART 1", 24, false);
    pico_arrives_1.visible = false;
    girlfriend.add(pico_arrives_1);
    
    pico_arrives_2 = new FlxSprite(-138, 74);
    pico_arrives_2.frames = Files.getAtlas(Paths.image("cutscenes/Pico_Arrives_2", "stages/war"));
    pico_arrives_2.animation.addByPrefix("play", "PICO ARRIVES PART 2", 24, false);
    pico_arrives_2.visible = false;
    girlfriend.add(pico_arrives_2);
    
    pico_arrives_3 = new FlxSprite(-141, 74);
    pico_arrives_3.frames = Files.getAtlas(Paths.image("cutscenes/Pico_Arrives_3", "stages/war"));
    pico_arrives_3.animation.addByPrefix("play", "PICO ARRIVES PART 3", 24, false);
    pico_arrives_3.visible = false;
    girlfriend.add(pico_arrives_3);

    // Boyfriend Assets
    bf_idle = new FlxSprite(2, 341).loadGraphic(Files.getGraphic(Paths.image("cutscenes/BF_IDLE", "stages/war")));
    boyfriend.add(bf_idle);

    tankman.c.visible = false;
    boyfriend.c.visible = false;
    girlfriend.c.visible = false;
}

function startSong(_startCountdown:Void->Void):Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}
    startCountdown = _startCountdown;

    Character.setCameraToCharacter(tankman, camFollow, stage);
    FlxTween.tween(camHUD, {alpha: 0}, 0.5);

    onCinematic = true;

    return true;
}

function update(elapsed:Float){
    if(!onCinematic){return;}
    total_time += elapsed;
    
    if(total_time >= 0.5 && total_events == 0){
        total_events++;

        stressCinematic1.animation.play("play");
        FlxG.sound.play(Files.getSound(Paths.sound("stress_1", "stages/war")), 1, false, null, true);
    }else if(total_time >= 15.25 && total_events == 1){
        total_events++;

        gf_idle.visible = false;
        gf_demon_1.visible = true;
        gf_demon_1.animation.play("play");
        Character.setCameraToCharacter(girlfriend, camFollow, stage);
        FlxTween.tween(FlxG.camera, {zoom: 1.25}, 1, {ease: FlxEase.quadInOut});
    }else if(total_time >= 16.784 && total_events == 2){
        total_events++;

        gf_demon_2.visible = true;
        gf_demon_1.visible = false;
        gf_demon_2.animation.play("play");
    }else if(total_time >= 17.737  && total_events == 3){
        total_events++;

        FlxTween.tween(FlxG.camera, {zoom: stage.zoom}, 1, {ease: FlxEase.quadInOut});
        
        bf_idle.visible = false;
        gf_demon_2.visible = false;
        boyfriend.c.visible = true;
        pico_arrives_1.visible = true;
        pico_arrives_1.animation.play("play");
        boyfriend.playAnim("catch");
    }else if(total_time >= 18.745  && total_events == 4){
        total_events++;

        pico_arrives_2.visible = true;
        pico_arrives_1.visible = false;
        pico_arrives_2.animation.play("play");
    }else if(total_time >= 19.75  && total_events == 5){
        total_events++;

        stressCinematic2.visible = true;
        stressCinematic1.visible = false;
        stressCinematic2.animation.play("play");
        Character.setCameraToCharacter(tankman, camFollow, stage);
    }else if(total_time >= 20.12  && total_events == 6){
        total_events++;

        pico_arrives_3.visible = true;
        pico_arrives_2.visible = false;
        pico_arrives_3.animation.play("play");
    }else if(total_time >= 21.748  && total_events == 7){
        total_events++;

        pico_arrives_3.visible = false;
        girlfriend.c.visible = true;
        girlfriend.playAnim("right1-loop");
    }else if(total_time >= 32.75  && total_events == 8){
        total_events++;

        Character.setCameraToCharacter(boyfriend, camFollow, stage);
        boyfriend.playAnim("singUPmiss");
    }else if(total_time >= 35  && total_events == 9){
        total_events++;
        
        girlfriend.c.visible = true;
        tankman.c.visible = true;
        
        gf_idle.kill();
        gf_demon_1.kill();
        pico_arrives_1.kill();
        pico_arrives_2.kill();
        pico_arrives_3.kill();
        stressCinematic1.kill();
        stressCinematic2.kill();

        boyfriend.specialAnim = false;
        girlfriend.specialAnim = false;
        tankman.specialAnim = false;

        girlfriend.dance();
        boyfriend.dance();
        tankman.dance();

        FlxTween.tween(camHUD, {alpha: 1}, 0.5);

        startCountdown();
    }else if(total_time >= 36  && total_events == 10){
        total_events++;
        
        girlfriend.remove(gf_idle);
        girlfriend.remove(gf_demon_1);
        girlfriend.remove(pico_arrives_1);
        girlfriend.remove(pico_arrives_2);
        girlfriend.remove(pico_arrives_3);
        tankman.remove(stressCinematic2);
        tankman.remove(stressCinematic1);

        gf_idle.destroy();
        gf_demon_1.destroy();
        pico_arrives_1.destroy();
        pico_arrives_2.destroy();
        pico_arrives_3.destroy();
        stressCinematic2.destroy();
        stressCinematic1.destroy();
        
        Files.clearAsset(Paths.image("cutscenes/Pico_Arrives_1", "stages/war"), false);
        Files.clearAsset(Paths.image("cutscenes/Pico_Arrives_2", "stages/war"), false);
        Files.clearAsset(Paths.image("cutscenes/Pico_Arrives_3", "stages/war"), false);
        Files.clearAsset(Paths.image("cutscenes/Gf_Demon_1", "stages/war"), false);
        Files.clearAsset(Paths.image("cutscenes/Gf_Demon_2", "stages/war"), false);
        Files.clearAsset(Paths.image("cutscenes/stress2", "stages/war"), false);
        Files.clearAsset(Paths.image("cutscenes/stress", "stages/war"), false);
        Files.clearAsset(Paths.sound("stress_1", "stages/war"), false);
        Files.clearAsset(Paths.image("GF_IDLE", "stages/war"), false);
        Files.clearAsset(Paths.image("BF_IDLE", "stages/war"));

        onCinematic = false;
    }
}