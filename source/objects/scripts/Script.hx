package objects.scripts;

import states.MusicBeatState;
import flixel.FlxBasic;
import hscript.Interp;
import openfl.Lib;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

enum Script_Calls {
    Stop_And_Break;
    Continue;
    Break;
    Stop;
}

class Script extends FlxBasic {
    public var parser = new hscript.Parser();
    public var interp = new hscript.Interp();
    public var program = null;

    public var parent(get, set):Dynamic;
    public function get_parent():Dynamic { return interp.scriptObject; }
    public function set_parent(_parent:Dynamic):Dynamic { return interp.scriptObject = _parent; }

    public var source:String = "";

    public var name:String;
    public var mod:String;

    public override function new(){
		parser.allowMetadata = true;
		parser.allowTypes = true;
		parser.allowJSON = true;
        super();

        preset();
    }

    public function force(path:String, ?doExecute:Bool = false):Void {
		#if sys
		if(!FileSystem.exists(path)){return;}
        setup(File.getContent(path), doExecute);
		#end
    }
    public function load(path:String, ?doExecute:Bool = false):Void {
		if(!Paths.exists(path)){return;}
        setup(path.getText(), doExecute);
    }

    public function setup(script:String, ?doExecute:Bool = false):Void {
        try{
            source = script;
            this.program = parser.parseString(script);
        }catch(e){
            trace('[Script Error]: ${e.message}\n${source}');
            Lib.application.window.alert(e.message, "Script Error!");
        }
        if(doExecute){execute();}
    }

    public function getVar(name:String):Dynamic{return interp.variables.get(name);}
    public function setVar(name:String, toSet:Dynamic){interp.variables.set(name, toSet);}
    public function preset():Void {
        setVar('create', ()->{});
        setVar('preload', ()->{});
        
        setVar('song_started', ()->{});
        setVar('song_paused', ()->{});
        setVar('song_ended', ()->{});
        
        setVar('onClose', ()->{});

        setVar('onFocus', ()->{});
        setVar('onFocusLost', ()->{});
        
        setVar('onOpenSubState', ()->{});
        setVar('onCloseSubState', ()->{});

        setVar('preload_event', ()->{});
        
        setVar('startSong', ()->{});
        setVar('endSong', ()->{});
        
        setVar('update', (elapsed:Float)->{});

        setVar('beatHit', (curBeat:Int)->{});
        setVar('stepHit', (curStep:Int)->{});
        setVar('paused', ()->{});

        setVar("preset", (name:String, func:Any) -> {setVar(name, func);});
        setVar("getset", (name:String) -> {return getVar(name);});

        setVar('destroy', () -> { this.destroy(); });

        setVar("setGlobal", () -> { MusicBeatState.state.scripts.set(this.name, this); });

        setVar('this', this);
        setVar('getMod', () -> { return Mods.get(mod); });
		setVar('getState', () -> { return states.MusicBeatState.state; });
        setVar('getModData', () -> { return Mods.mod_scripts.get(mod); });
        setVar('getScript', (key:String) -> { return states.MusicBeatState.state.scripts.get(key); });

        setVar('Stop_And_Break', Stop_And_Break);
        setVar('Script_Calls', Script_Calls);
        setVar('Continue', Continue);
        setVar('Break', Break);
        setVar('Stop', Stop);
    }
    
    public function execute():Void{if(program == null){trace('Null Program'); return;}interp.execute(program);}
    public function getFunc(name:String){
        if(program == null){trace('${this.name} | {${name}}: Null Script'); return null;}
        if(!interp.variables.exists(name)){trace('{${this.name} | ${name}}: Null Function [${name}]'); return null;}
        return interp.variables.get(name);
    }
    public function call(name:String, ?args:Array<Any>):Dynamic {
        if(program == null){trace('${this.name} | {${name}}: Null Script'); return null;}
        if(!interp.variables.exists(name)){trace('${this.name} | {${name}}: Null Function [${name}]'); return null;}

        var FUNCT = interp.variables.get(name);
        var toReturn = null;
        if(args != null){
            try{
                toReturn = Reflect.callMethod(null, FUNCT, args);
            }catch(e){
                trace('${this.name} | {${name}}: [Function Error](${name}): ${e}');
            }
        }else{
            try{
                toReturn = FUNCT();
            }catch(e){
                trace('${this.name} | {${name}}: [Function Error](${name}): ${e}');
            }
        }

        return toReturn;
    }

    public override function destroy(){
        if(MusicBeatState.state != null){MusicBeatState.state.scripts.remove(name);}
        program = null;
        super.destroy();
    }
}