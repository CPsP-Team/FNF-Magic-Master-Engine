import("flixel.FlxG", "FlxG");

import("String");
import("Std");

preset("defaultValues", [
    {name:"Id",type:"Int",value:0},
    {name:"Function",type:"String",value:""},
    {name:"Arguments",type:"Array",value:[]}
]);

function execute(id:Int, func:String, args:Array<Dynamic>):Void {
    if(getState().stage == null){return;}
    var _character:Character = getState().stage.getCharacterById(id);
    if(_character == null){return;}
    _character.charScript.exFunction(func, args);
}