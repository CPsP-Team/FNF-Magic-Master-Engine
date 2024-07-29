
import("flixel.tweens.FlxTween", "FlxTween");
import("flixel.util.FlxTimer", "FlxTimer");
import("flixel.tweens.FlxEase", "FlxEase");
import("states.PlayState", "PlayState");
import("flixel.FlxSprite", "FlxSprite");
import("flixel.FlxObject", "FlxObject");
import("haxe.Timer", "Timer");
import("flixel.FlxG", "FlxG");

import("DialogueBox");
import("Files");
import("Paths");

var whiteScreen:FlxSprite;
var redScreen:FlxSprite;
var dialogue:DialogueBox;

var senpaidies:FlxSprite;

var camFollow:FlxObject;

function preload():Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return;}
    
    whiteScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
    whiteScreen.cameras = [getState().camBHUD];
    whiteScreen.screenCenter();
    whiteScreen.alpha = 0;

    redScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFE0000);
    redScreen.cameras = [getState().camBHUD];
    redScreen.screenCenter();
    redScreen.alpha = 0;

    senpaidies = new FlxSprite(0,-120);
    senpaidies.cameras = [getState().camBHUD];
    senpaidies.frames = Files.getAtlas(Paths.image("senpaiCrazy", "stages/schoolEvil"));
    senpaidies.animation.addByPrefix("die", "Senpai Pre Explosion instance 1", 24, false);
    senpaidies.scale.set(6,6); senpaidies.updateHitbox();
    senpaidies.antialiasing = false;
    senpaidies.alpha = 0;

    camFollow = getState().camFollow;

    getState().add(whiteScreen);
    getState().add(redScreen);
    getState().add(senpaidies);
}

function startSong(startCountdown:Void->Void):Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}

    FlxG.sound.play(Files.getSound(Paths.sound("ANGRY_TEXT_BOX", "stages/schoolEvil")));
    
    FlxTween.tween(whiteScreen, {alpha: 0.5}, 3, {ease: FlxEase.linear});
    FlxTween.tween(getState().camHUD, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){
        dialogue = new DialogueBox(Files.getJson(Paths.dialogue(PlayState.SONG.song)), {onComplete: function(){onEndDialogue(startCountdown);}});
        dialogue.cameras = [getState().camBHUD];
        getState().add(dialogue);
    }});

    return true;
}

function endSong(endCountdown:Void->Void):Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}

    getState().camFHUD.fade(0xFFFF0000, 1, true);
    FlxG.sound.play(Files.getSound(Paths.sound("ANGRY", "stages/schoolEvil")));

    FlxTween.tween(getState().camHUD, {alpha: 0}, 2, {ease: FlxEase.linear});
    var evil_timer:FlxTimer = new FlxTimer().start(2, function(tmr:FlxTimer){
        getState().camFHUD.fade(0xFFFF0000, 1, true);
        FlxG.sound.play(Files.getSound(Paths.sound("ANGRY", "stages/schoolEvil")));
        FlxG.sound.playMusic(Files.getSound(Paths.music("LunchboxScary", "stages/schoolEvil")));

        FlxG.sound.music.fadeIn(2, 0, 1, function(twn:FlxTween){
            FlxG.sound.play(Files.getSound(Paths.sound("ANGRY", "stages/schoolEvil")));
            FlxG.sound.play(Files.getSound(Paths.sound("Senpai_Dies", "stages/schoolEvil")), 1, false, null, true, endCountdown);

            getState().camFHUD.fade(0xFFFF0000, 0.8, true);
            redScreen.alpha = 1;
            senpaidies.animation.play("die");
            FlxTween.tween(senpaidies, {alpha: 1}, 1, {ease: FlxEase.linear});
            var fade_timer = new FlxTimer().start(3.2, function(){getState().camFHUD.fade(0xFFFFFFFF, 1.6);});
        });
    });
    
    return true;
}

function onEndDialogue(startCountdown:Void->Void):Void {
    FlxTween.tween(whiteScreen, {alpha: 0}, 1, {ease: FlxEase.linear});
    FlxTween.tween(getState().camHUD, {alpha: 1}, 1, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){startCountdown();}});
}