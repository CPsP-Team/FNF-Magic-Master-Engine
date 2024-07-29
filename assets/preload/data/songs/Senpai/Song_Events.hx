
import("flixel.tweens.FlxTween", "FlxTween");
import("flixel.tweens.FlxEase", "FlxEase");
import("states.PlayState", "PlayState");
import("flixel.FlxSprite", "FlxSprite");
import("flixel.FlxG", "FlxG");

import("DialogueBox");
import("Files");
import("Paths");

var whiteScreen:FlxSprite;
var dialogue:DialogueBox;

function preload():Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return;}

    whiteScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
    whiteScreen.cameras = [camBHUD];
    whiteScreen.screenCenter();
    whiteScreen.alpha = 0;

    add(whiteScreen);
}

function startSong(startCountdown:Void->Void):Void {
    if(!PlayState.isStoryMode || PlayState.total_plays > 1){return false;}

    FlxG.sound.playMusic(Files.getSound(Paths.music("Lunchbox", "stages/school")));
    FlxG.sound.music.fadeIn();
    
    FlxTween.tween(whiteScreen, {alpha: 0.5}, 3, {ease: FlxEase.linear});
    FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function(twn){
        dialogue = new DialogueBox(Files.getJson(Paths.dialogue(PlayState.SONG.song)), {onComplete: function(){onEndDialogue(startCountdown);}});
        dialogue.cameras = [camBHUD];
        add(dialogue);
    }});

    return true;
}

function onEndDialogue(startCountdown:Void->Void):Void {
    FlxG.sound.music.fadeOut();
    FlxTween.tween(whiteScreen, {alpha: 0}, 1, {ease: FlxEase.linear});
    FlxTween.tween(camHUD, {alpha: 1}, 1, {ease: FlxEase.linear, onComplete: function(twn){startCountdown();}});
}