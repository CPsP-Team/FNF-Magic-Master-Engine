import("flixel.util.FlxTimer", "FlxTimer");
import("flixel.FlxSprite", "FlxSprite");
import("flixel.FlxG", "FlxG");
import("Files");
import("Paths");

var c:FlxSprite;

function addToLoad(list:Array<Dynamic>){}
function load_before_char(){}
function load_after_char(){
    c = instance.c;
}

function turnLook(toRight:Bool){}

function playkey(keyName:String, Force:Bool){
    if(keyName == "singLEFT"){
        var cur_random:Int = FlxG.random.int(1,2);
        c.keyation.play("left"+cur_random);
        instance.playkey("left"+cur_random, true);
        return true;
    }else if(keyName == "singRIGHT"){
        var cur_random:Int = FlxG.random.int(1,2);
        instance.playkey("right"+cur_random, true);
        return true;
    }
}

function dance(){return true;}
function update(elapsed:Float){}