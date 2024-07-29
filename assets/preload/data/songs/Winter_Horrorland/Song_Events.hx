
import("flixel.tweens.FlxTween", "FlxTween");
import("flixel.util.FlxTimer", "FlxTimer");
import("flixel.tweens.FlxEase", "FlxEase");
import("flixel.FlxSprite", "FlxSprite");
import("haxe.Timer", "Timer");
import("flixel.FlxG", "FlxG");

import("Files");
import("Paths");

var blackScreen:FlxSprite;

function preload():Void {
    blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x000000);
    blackScreen.cameras = [camHUD];
    blackScreen.screenCenter();
    add(blackScreen);

    camFollow.setPosition(970, -800);
}

function startSong(startCountdown:Void->Void):Void {
    camHUD.visible = false;
    FlxG.camera.zoom = 1.5;

    FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) {remove(blackScreen);}});
    FlxG.sound.play(Files.getSound(Paths.sound("Lights_Turn_On","stages/mallEvil")));

    new FlxTimer().start(0.8, function(tmr:FlxTimer){
        camHUD.visible = true;
        remove(blackScreen);
        FlxTween.tween(FlxG.camera, {zoom: stage.zoom}, 2.5, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween){startCountdown();}});
    });

    return true;
}