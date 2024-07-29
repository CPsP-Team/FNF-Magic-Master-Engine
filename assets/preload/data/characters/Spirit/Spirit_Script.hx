import("flixel.addons.effects.FlxTrail", "FlxTrail");
import("flixel.FlxSprite", "FlxSprite");

var character:FlxSprite = null;
var evil_trail:FlxTrail = null;

function addToLoad(list:Array<Dynamic>){}

function update(elapsed:Float){}
function dance(){}

function load_before_char(){}
function load_after_char(){
    character = instance.c;

    evil_trail = new FlxTrail(character, null, 4, 24, 0.3, 0.069);
    instance.insert(0, evil_trail);
}

function turnLook(toRight:Bool){}
function playkey(keyName:String, Force:Bool){}