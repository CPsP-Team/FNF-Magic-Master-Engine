package objects.scripts;

import objects.scripts.Script.Script_Calls;
import objects.scripts.Script;
import utils.Scripts;
import utils.Mods;

class ScriptList {
    public var list:Map<String, Script> = [];
    
    public var call_globals:Bool = true;
    
    public function new(?scripts:Map<String, Script>):Void {
        if(scripts != null){list = scripts;}
    }
    

    public function get(key:String):Script {
        if(call_globals && Scripts.contains(key)){return Scripts.get(key);}
        return list.get(key);
    }

	public function set(key:String, script:Script):Void {
        if(call_globals && Scripts.contains(key)){return;}
		if(list.exists(key)){return;}
        list.set(key, script);
	}
	public function remove(key:String):Void {
		list.remove(key);
	}

    public function load(key:String, file:String):Void {
        if(list.exists(key)){return;}
        var new_script = new Script();
        new_script.load(file, true);
        new_script.name = key;
        if(new_script.program == null){return;}
        list.set(key, new_script);
    }

    public function setVar(name:String, toSet:Dynamic){
        if(call_globals){for(key => s in Scripts.global_scripts){s.interp.variables.set(name, toSet);}}
		for(key => s in list){s.interp.variables.set(name, toSet);}
    }

	public function call(name:String, arguments:Array<Dynamic> = null):Void {
		if(arguments == null){arguments = [];}
        
        if(call_globals){for(key => s in Scripts.global_scripts){s.call(name, arguments);}}
		for(key => s in list){s.call(name, arguments);}
	}

    public function callback(name:String, arguments:Array<Dynamic> = null):Script_Calls {
		if(arguments == null){arguments = [];}

        var toReturn:Script_Calls = Continue;

        if(call_globals){
            for(key => s in Scripts.global_scripts){
                var cur_call:Script_Calls = cast(s.call(name, arguments), Script_Calls);
                if(cur_call == Stop_And_Break){return Stop;}
                if(cur_call == Break){return Break;}
                if(toReturn == Stop){continue;}
                toReturn = cur_call;
            }
        }
		for(key => s in list){
            var cur_call:Script_Calls = cast(s.call(name, arguments), Script_Calls);
            if(cur_call == Stop_And_Break){return Stop;}
            if(cur_call == Break){return Break;}
            if(toReturn == Stop){continue;}
            toReturn = cur_call;
        }

        return toReturn;
    }
}