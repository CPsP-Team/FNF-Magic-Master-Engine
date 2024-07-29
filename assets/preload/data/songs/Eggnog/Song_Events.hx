
import("flixel.util.FlxTimer", "FlxTimer");
import("flixel.FlxSprite", "FlxSprite");
import("haxe.Timer", "Timer");
import("flixel.FlxG", "FlxG");

import("Paths");

var blackScreen:FlxSprite;

preset("endCountdown", true);

function preload():Void {
    blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    blackScreen.cameras = [camFHUD];
    blackScreen.visible = false;
    blackScreen.screenCenter();
    add(blackScreen);
}

function endSong(endCountdown:Void->Void):Void {
    blackScreen.visible = true;
    FlxG.sound.play(Paths.sound("Lights_Shut_off","stages/mall"));

    new FlxTimer().start(1, function(tmr:FlxTimer){endCountdown();});   
}