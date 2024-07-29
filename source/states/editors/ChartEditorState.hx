package states.editors;

import substates.editors.CharacterEditorSubState;
import objects.songs.Conductor.BPMChangeEvent;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUINumericStepper;
import substates.editors.SingEditorSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITabMenu;
import objects.songs.Song.Strum_Data;
import flixel.addons.ui.FlxUIButton;
import objects.songs.Song.Song_File;
import objects.notes.Note.Note_Data;
import objects.ui.UINumericStepper;
import flixel.addons.ui.FlxUIGroup;
import flixel.sound.FlxSoundGroup;
import objects.notes.StaticNotes;
import flixel.ui.FlxCustomButton;
import openfl.net.FileReference;
import objects.notes.StrumEvent;
import substates.PopUpSubState;
import objects.utils.SaverFile;
import objects.notes.StrumLine;
import flixel.addons.ui.FlxUI;
import objects.game.Character;
import flixel.tweens.FlxTween;
import objects.game.Alphabet;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.input.FlxInput;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import objects.ui.UIButton;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import objects.songs.Song;
import objects.game.Stage;
import objects.notes.Note;
import lime.ui.FileDialog;
import lime.utils.Assets;
import objects.ui.UIList;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxBasic;
import haxe.Exception;
import flixel.FlxG;
import haxe.Timer;
import openfl.Lib;
import haxe.Json;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class ChartEditorState extends MusicBeatState {
    public static var song:Song_File;
    
    public var stage:Stage;

    public static var lastSection:Int = 0;
    var curSection:Int = 0;
    var curStrum:Int = 0;

	var tempBpm:Float = 0;

    var strumLineEvent:FlxSprite;
    var strumLine:FlxSprite;
    var strumStatics:FlxTypedGroup<StaticNotes>;

    var eveGrid:FlxSprite;
    var curGrid:FlxSprite;
    var focusStrum:FlxSprite;
    var cursor_Arrow:FlxSprite;

    var _saved:Alphabet;

    var backGroup:FlxTypedGroup<Dynamic>;
    var gridGroup:FlxTypedGroup<FlxSprite>;
    var stuffGroup:FlxTypedGroup<Dynamic>;
    
    public static var sHitsArray:Array<Bool> = [];
    var renderedEvents:FlxTypedGroup<StrumEvent>;
    var renderedSustains:FlxTypedGroup<Note>;
    var notesCanHit:Array<Array<Note>> = [];
    var renderedNotes:FlxTypedGroup<Note>;
    var sVoicesArray:Array<Bool> = [];
    var singArray:Array<Array<Int>> = [];
    
    var selNote:Note_Data = Note.getNoteData();
    var selEvent:Event_Data = Note.getEventData();

    //var tabsUI:FlxUIMenuCustom;

    var genFollow:FlxObject;
    var backFollow:FlxObject;
    //-------

    var voices:FlxSoundGroup;
    var inst:FlxSound = new FlxSound();

    var DEFAULT_KEYSIZE:Int = 60;
    var KEYSIZE:Int = 60;

    var MENU:FlxUITabMenu;

    var arrayFocus:Array<FlxUIInputText> = [];
    var copySection:Array<Dynamic> = null;

    var lblSongInfo:FlxText;

    var saveTimer:Timer = new Timer(60000);

    override function destroy() {
        saveTimer.stop();
		super.destroy();
	}

    override function create(){
        if(FlxG.sound.music != null){FlxG.sound.music.stop();}

        if(song == null){song = PlayState.song;}
        if(song == null){song = Song.load("Test-Normal-Normal");}

        saveTimer.run = autoSave;

		#if desktop
		// Updating Discord Rich Presence
		Discord.change('[${song.song}-${song.category}-${song.difficulty}]', '[Charting]');
		Magic.setWindowTitle('Charting [${song.song}-${song.category}-${song.difficulty}]', 1);
		#end

        curSection = lastSection;
		tempBpm = song.bpm;
        
        stage = new Stage(song.stage, song.characters);
        stage.cameras = [camBHUD];
        add(stage);

        backGroup = new FlxTypedGroup<Dynamic>(); backGroup.cameras = [camHUD]; add(backGroup);
        gridGroup = new FlxTypedGroup<FlxSprite>(); gridGroup.cameras = [camHUD]; add(gridGroup);
        focusStrum = new FlxSprite().makeGraphic(KEYSIZE, KEYSIZE, FlxColor.YELLOW); focusStrum.cameras = [camHUD]; focusStrum.alpha = 0.3; add(focusStrum);
        strumStatics = new FlxTypedGroup<StaticNotes>(); strumStatics.cameras = [camHUD]; add(strumStatics);
        stuffGroup = new FlxTypedGroup<Dynamic>(); stuffGroup.cameras = [camHUD]; add(stuffGroup);

        renderedSustains = new FlxTypedGroup<Note>(); renderedSustains.cameras = [camHUD]; add(renderedSustains);
        renderedNotes = new FlxTypedGroup<Note>(); renderedNotes.cameras = [camHUD]; add(renderedNotes);
        renderedEvents = new FlxTypedGroup<StrumEvent>(); renderedEvents.cameras = [camHUD]; add(renderedEvents);

        cursor_Arrow = new FlxSprite().makeGraphic(KEYSIZE,KEYSIZE);
        cursor_Arrow.cameras = [camHUD];
        add(cursor_Arrow);

        strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width), 4);
        strumLine.cameras = [camHUD];
		//strumLine.visible = false;
		add(strumLine);
        
        strumLineEvent = new FlxSprite(0, 50).makeGraphic(KEYSIZE, 4);
        strumLineEvent.cameras = [camHUD];
		add(strumLineEvent);

        var menuTabs = [
            {name: "1Settings", label: 'Settings'},
            {name: "2Event", label: 'Event'},
            {name: "3Note", label: 'Note'},
            {name: "4Section", label: 'Section'},
            {name: "5Song", label: 'Song'}
        ];
        MENU = new FlxUITabMenu(null, menuTabs, true);
        MENU.resize(300, Std.int(FlxG.height) - 180);
		MENU.x = FlxG.width - MENU.width;
        MENU.camera = camFHUD;
        addMENUTABS();        
        add(MENU);

        lblSongInfo = new FlxText(0, 50, 300, "", 16);
        lblSongInfo.scrollFactor.set();
        lblSongInfo.camera = camFHUD;
        add(lblSongInfo);

        voices = new FlxSoundGroup();
        loadAudio(song.song, song.category);
        conductor.changeBPM(song.bpm);
		conductor.mapBPMChanges(song);

        _saved = new Alphabet(0,0,[{scale:0.3,bold:true,text:"Song Saved"}]);
        _saved.alpha = 0;
        _saved.cameras = [camFHUD];
        add(_saved);

        super.create();

        FlxG.mouse.visible = true;
        
        //camBHUD.alpha = 0;
        camBHUD.zoom = 0.5;

        backFollow = new FlxObject(0, 0, 1, 1);
        backFollow.screenCenter();
		camBHUD.follow(backFollow, LOCKON, 0.04);

        genFollow = new FlxObject(0, 0, 1, 1);
        FlxG.camera.follow(genFollow, LOCKON);
        camHUD.follow(genFollow, LOCKON);
        camBHUD.zoom = stage.zoom;
        
		changeSection(lastSection);
        changeStrum();
    }
    
    function updateSection():Void {
        //trace(song.characters);
        sHitsArray.resize(song.strums.length);
        
		if(song.sections[curSection].changeBPM && song.sections[curSection].bpm > 0){
			conductor.changeBPM(song.sections[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
        }else{
			// get last bpm
			var daBPM:Float = song.bpm;
			for(i in 0...curSection){if(song.sections[i].changeBPM){daBPM = song.sections[i].bpm;}}
			conductor.changeBPM(daBPM);
		}

        for(i in 0...song.strums.length){
            var s = song.strums[i];
            singArray[i] = s.sections[curSection].changeCharacters ? s.sections[curSection].characters : singArray[i] = s.characters;
        }

        reloadChartGrid();
                
        renderedEvents.clear();
        var eventsInfo:Array<Dynamic> = song.events.copy();
        if(eventsInfo != null){
            for(e in eventsInfo){
                var eData:Event_Data = Note.getEventData(e);
                if(eData.strumTime < sectionStartTime()){continue;}
                if(eData.strumTime > sectionStartTime(1)){continue;}

                var isSelected:Bool = Note.compare(eData, selEvent, false);
        
                var note:StrumEvent = new StrumEvent(eData.strumTime, conductor, eData.isExternal, eData.isBroken);
                setupNote(note, -1);
                note.alpha = isSelected || inst.playing ? 1 : 0.5;
    
                renderedEvents.add(note);
            }
        }

        notesCanHit = [];
        renderedNotes.clear();
        renderedSustains.clear();
        for(ii in 0...song.strums.length){
            notesCanHit.push([]);

            var sectionInfo:Array<Dynamic> = song.strums[ii].sections[curSection].notes.copy();
            for(n in sectionInfo){if(n[1] < 0 || n[1] >= song.strums[ii].keys){sectionInfo.remove(n);}}
            
            var cSection = song.strums[ii];
            for(n in sectionInfo){
                var nData:Note_Data = Note.getNoteData(n);
                var isSelected:Bool = Note.compare(nData, selNote);
        
                var note:Note = new Note(nData, song.strums[ii].keys, null, cSection.style);
                setupNote(note, ii);
                note.alpha = isSelected || inst.playing ? 1 : 0.5;

                if(note.otherData.length > 0){
                    var iconEvent:StrumEvent = new StrumEvent(nData.strumTime, conductor);
                    iconEvent.setPosition(note.x, note.y);
                    iconEvent.setGraphicSize(Std.int(KEYSIZE / 3), Std.int(KEYSIZE / 3));
                    iconEvent.updateHitbox();
                    iconEvent.alpha = note.alpha;
                    renderedEvents.add(iconEvent);
                }
                        
                renderedNotes.add(note);
                if(note.strumTime > conductor.position || inst.playing){notesCanHit[ii].push(note);}
        
                if(nData.sustainLength <= 0){continue;}
        
                if(nData.multiHits > 0){
                    var totalHits:Int = nData.multiHits + 1;
                    var hits:Int = nData.multiHits;
                    var curHits:Int = 1;
                    note.noteHits = 0;
                    nData.multiHits = 0;
        
                    while(hits > 0){
                        var newStrumTime = nData.strumTime + (nData.sustainLength * curHits);
                        var nSData:Note_Data = Note.getNoteData(Note.convNoteData(nData));
                        nSData.strumTime = newStrumTime;

                        var hitNote:Note = new Note(nSData, song.strums[ii].keys, null, cSection.style);
                        setupNote(hitNote, ii);
                        hitNote.alpha = isSelected || inst.playing ? 1 : 0.5;

                        renderedNotes.add(hitNote);
                        if(hitNote.strumTime > conductor.position || inst.playing){notesCanHit[ii].push(hitNote);}

                        hits--;
                        curHits++;
                    }
                }else{
                    var cSusNote:Int = Std.int(Math.max(Math.floor(nData.sustainLength / conductor.stepCrochet), 1));

                    var nSData:Note_Data = Note.getNoteData(Note.convNoteData(nData));
                    nSData.strumTime += (conductor.stepCrochet / 2);
                    var nSustain:Note = new Note(nSData, song.strums[ii].keys, null, cSection.style);
                    nSustain.typeNote = "Sustain";
                    nSustain.typeHit = "Hold";
                    note.nextNote = nSustain;
                    nSustain.playAnim("sustain");
                    setupNote(nSustain, ii);
                    nSustain.alpha = isSelected || inst.playing ? 0.5 : 0.3;
                    nSustain.setGraphicSize(KEYSIZE, (KEYSIZE * (cSusNote + 0.25))); nSustain.updateHitbox();
                    renderedSustains.add(nSustain);
                    if(nSustain.strumTime > conductor.position || inst.playing){notesCanHit[ii].push(nSustain);}
                    
                    var nEData:Note_Data = Note.getNoteData(Note.convNoteData(nData));
                    nEData.strumTime += conductor.stepCrochet * (cSusNote + 0.75);
                    var nSustainEnd:Note = new Note(nEData, song.strums[ii].keys, null, cSection.style);
                    nSustainEnd.typeNote = "Sustain";
                    nSustainEnd.typeHit = "Hold";
                    nSustain.nextNote = nSustainEnd;
                    setupNote(nSustainEnd, ii);
                    nSustainEnd.playAnim("end");
                    nSustainEnd.alpha = isSelected || inst.playing ? 0.5 : 0.3;
                    renderedSustains.add(nSustainEnd);
                    if(nSustainEnd.strumTime > conductor.position || inst.playing){notesCanHit[ii].push(nSustainEnd);}
                }
            }
        }
        
        updateValues();
    }
    
    var s_Characters:Array<Dynamic> = [];
    function updateStage():Void {
        if(stage.curStage == song.stage && s_Characters == song.characters){return;}
        s_Characters = song.characters.copy();

        stage.load(song.stage);
        stage.setCharacters(song.characters);
        camBHUD.zoom = stage.zoom;
    }

    var g_STRUMS:Int = 0; var g_KEYSIZE:Int = 0; var g_STEPSLENGTH:Int = 0; var g_STRUMKEYS:Array<Int> = [];
    function reloadChartGrid(force:Bool = false):Void {
        var toChange:Bool = force;

        g_STRUMKEYS.resize(song.strums.length);
        for(i in 0...g_STRUMKEYS.length){if(song.strums[i].keys != g_STRUMKEYS[i]){toChange = true; break;}}
        if(song.sections[curSection].lengthInSteps != g_STEPSLENGTH){toChange = true;}
        if(g_STRUMS != song.strums.length){toChange = true;}
        if(KEYSIZE != g_KEYSIZE){toChange = true;}
        
        if(!toChange){return;}

        while(gridGroup.members.length > song.strums.length + 1){gridGroup.remove(gridGroup.members[gridGroup.members.length - 1], true);}
        while(gridGroup.members.length < song.strums.length + 1){gridGroup.add(new FlxSprite());}
        
        if(chkHideStrums.checked){strumStatics.clear();}else{
            while(strumStatics.members.length > song.strums.length){strumStatics.remove(strumStatics.members[strumStatics.members.length - 1], true);}
            while(strumStatics.members.length < song.strums.length){strumStatics.add(new StaticNotes(0,0));}
        }

        singArray = [];
        backGroup.clear();
        stuffGroup.clear();
        
        var lastWidth:Float = 0;
        var daLehgthSteps:Int = song.sections[curSection].lengthInSteps;

        // EVENT GRID STRUFF
        var evGrid = gridGroup.members[0];
        evGrid = FlxGridOverlay.create(KEYSIZE, Std.int(KEYSIZE / 2), KEYSIZE, KEYSIZE * daLehgthSteps, true, 0xff4d4d4d, 0xff333333);
        evGrid.x -= KEYSIZE * 1.5;
        if(inst.playing){evGrid.alpha = 0.5;} 
        gridGroup.members[0] = evGrid;

        eveGrid = gridGroup.members[0];
        strumLineEvent.makeGraphic(KEYSIZE, 4); strumLineEvent.x = eveGrid.x;

        var line_1 = new FlxSprite(evGrid.x - 1,0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_1.scrollFactor.set(1, 0); stuffGroup.add(line_1);
        var eBack = new FlxSprite(evGrid.x,0).makeGraphic(KEYSIZE, FlxG.height, FlxColor.BLACK); eBack.alpha = 0.5; eBack.scrollFactor.set(1, 0); backGroup.add(eBack);
        var line_2 = new FlxSprite(evGrid.x + KEYSIZE - 1,0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_2.scrollFactor.set(1, 0); stuffGroup.add(line_2);

        var line_3 = new FlxSprite(-1, 0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_3.scrollFactor.set(1, 0); stuffGroup.add(line_3);
        for(i in 0...song.strums.length){
            var daGrid = gridGroup.members[i + 1];
            var daKeys:Int = song.strums[i].keys;
            singArray.push(song.strums[i].characters);

            if(daGrid != null && daGrid.width == daKeys * KEYSIZE && !toChange){continue;}

            daGrid = FlxGridOverlay.create(KEYSIZE, KEYSIZE, KEYSIZE * daKeys, KEYSIZE * daLehgthSteps, true, 0xffe7e6e6, 0xffd9d5d5);
            if(i != curStrum || inst.playing){daGrid.alpha = 0.5;}
            daGrid.x = lastWidth; daGrid.ID = i;

            if(!chkHideStrums.checked){
                var curStatics = strumStatics.members[i];
                curStatics.style = song.strums[i].style;
                curStatics.changeKeys(daKeys, Std.int(KEYSIZE * daKeys), true);
                curStatics.x = lastWidth;
            }

            lastWidth += daGrid.width;

            var new_line = new FlxSprite(lastWidth - 1, 0).makeGraphic(2, FlxG.height, FlxColor.BLACK); new_line.scrollFactor.set(1, 0); stuffGroup.add(new_line);

            gridGroup.members[i + 1] = daGrid;
        }

        var genBack = new FlxSprite().makeGraphic(Std.int(lastWidth), FlxG.height, FlxColor.BLACK); genBack.alpha = 0.5; genBack.scrollFactor.set(1, 0); backGroup.add(genBack);
                
        g_STRUMS = song.strums.length; g_KEYSIZE = KEYSIZE; g_STEPSLENGTH = daLehgthSteps; for(i in 0...g_STRUMKEYS.length){g_STRUMKEYS[i] = song.strums[i].keys;}
    }

    var pressedNotes:Array<Note_Data> = [];
    override function update(elapsed:Float){
        curStep = recalculateSteps();
        
        if(inst.time < 0) {
			inst.pause();
			inst.time = 0;
		}else if(inst.time > inst.length) {
			inst.pause();
			inst.time = 0;
			changeSection();
		}

        conductor.position = inst.time;

        if(song.sections[curSection] != null){strumLine.y = getYfromStrum((conductor.position - sectionStartTime()));}
        for(strums in strumStatics){strums.y = strumLine.y;} strumLineEvent.y = strumLine.y;

        if(song.sections[curSection + 1] == null){addGenSection();}
        for(i in 0...song.strums.length){if(song.strums[i].sections[curSection + 1] == null){addSection(i, song.sections[curSection].lengthInSteps, song.strums[i].keys);}}

        if(Math.ceil(strumLine.y) >= curGrid.height){changeSection(curSection + 1, false);}
        if(strumLine.y <= -10){changeSection(curSection - 1, false);}
    
        FlxG.watch.addQuick('daBeat', curBeat);
        FlxG.watch.addQuick('daStep', curStep);

        lblSongInfo.text = 
        "Time: " + Std.string(FlxMath.roundDecimal(conductor.position / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(inst.length / 1000, 2)) +
		"\n\nSection: " + curSection +
		"\nBeat: " + curBeat +
		"\nStep: " + curStep;

        if(inst.playing){
            Character.setCamera(stage.getCharacterById(Character.getFocus(song, curSection)), backFollow, stage);

            for(i in 0...notesCanHit.length){
                for(n in notesCanHit[i]){
                    if(n.strumTime > conductor.position){continue;}
                    notesCanHit[i].remove(n);

                    if(n.hitMiss){continue;}
                    if(!chkHideStrums.checked){strumStatics.members[i].playId((n.noteData % song.strums[i].keys), "confirm", true);}
                    if(!chkMuteHitSounds.checked && sHitsArray[i] && n.typeHit != "Hold"){FlxG.sound.play(Paths.sound("CLAP").getSound());}

                    var song_animation:String = n.singAnimation;
                    if(song.strums[i].sections[curSection].changeAlt){song_animation += '-alt';}

                    for(ii in singArray[i]){
                        if(stage.getCharacterById(ii) == null){continue;}
                        stage.getCharacterById(ii).singAnim(song_animation, true);
                    }
                }
            }
        }else{
            Character.setCamera(stage.getCharacterById(Character.getFocus(song, curSection, curStrum)), backFollow, stage);
        }

        var arrayControlle = true;
        for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}

        if(canControlle && arrayControlle){
		    song.bpm = tempBpm;

            if(!inst.playing){
                if(!chkHideChart.checked && FlxG.mouse.overlaps(eveGrid)){
                    cursor_Arrow.alpha = 0.5;

                    cursor_Arrow.x = eveGrid.x;
                    cursor_Arrow.y = Math.floor(FlxG.mouse.y / (KEYSIZE / 2)) * (KEYSIZE / 2);
                    if(FlxG.keys.pressed.SHIFT){cursor_Arrow.y = FlxG.mouse.y;}
                    
                    if(FlxG.mouse.justPressed){
                        if(FlxG.keys.pressed.CONTROL){reloadSelectedEvent();}
                        else{checkToAddEvent();}
                    }
                }else if(!chkHideChart.checked && FlxG.mouse.overlaps(curGrid)){
                    cursor_Arrow.alpha = 0.5;
                    
                    cursor_Arrow.x = Math.floor(FlxG.mouse.x / KEYSIZE) * KEYSIZE;        
                    cursor_Arrow.y = Math.floor(FlxG.mouse.y / (KEYSIZE / 2)) * (KEYSIZE / 2);
                    if(FlxG.keys.pressed.SHIFT){cursor_Arrow.y = FlxG.mouse.y;}
        
                    if(FlxG.mouse.justPressed){
                        if(FlxG.keys.pressed.CONTROL){reloadSelectedNote();}
                        else{checkToAddNote();}
                    }
                }else{cursor_Arrow.alpha = 0;}
            }

            if(FlxG.keys.justPressed.SPACE){changePause(inst.playing);}
            if(FlxG.keys.anyJustPressed([UP, DOWN, W, S, R, E, Q]) || FlxG.mouse.wheel != 0 && inst.playing){changePause(true);}

            if(FlxG.keys.justPressed.R){
                if(FlxG.keys.pressed.CONTROL){KEYSIZE = DEFAULT_KEYSIZE; cursor_Arrow.setGraphicSize(KEYSIZE,KEYSIZE); cursor_Arrow.updateHitbox(); updateSection();}
                else if(FlxG.keys.pressed.SHIFT){resetSection(true);}
                else{resetSection();}
            }

            if(FlxG.mouse.wheel != 0){
                if(FlxG.keys.pressed.CONTROL){KEYSIZE += Std.int(FlxG.mouse.wheel * (KEYSIZE / 5)); cursor_Arrow.setGraphicSize(KEYSIZE,KEYSIZE); cursor_Arrow.updateHitbox(); updateSection();}
                else if(FlxG.keys.pressed.SHIFT){inst.time -= (FlxG.mouse.wheel * conductor.stepCrochet * 0.5);}
                else{inst.time -= (FlxG.mouse.wheel * conductor.stepCrochet * 1);}
            }
    
            if(!FlxG.keys.pressed.SHIFT){    
                if(FlxG.keys.justPressed.E){changeNoteSustain(1);}
                if(FlxG.keys.justPressed.Q){changeNoteSustain(-1);}
    
                if(!inst.playing){
                    if(FlxG.keys.anyPressed([UP, W])){
                        var daTime:Float = conductor.stepCrochet * 0.1;
                        inst.time -= daTime;
                    }
                    if(FlxG.keys.anyPressed([DOWN, S])){
                        var daTime:Float = conductor.stepCrochet * 0.1;
                        inst.time += daTime;
                    }
                }
        
                if(FlxG.keys.anyJustPressed([LEFT, A])){changeSection(curSection - 1);}
                if(FlxG.keys.anyJustPressed([RIGHT, D])){changeSection(curSection + 1);}
            }else{    
                if(FlxG.keys.justPressed.E){changeNoteHits(1);}
                if(FlxG.keys.justPressed.Q){changeNoteHits(-1);}
        
                if(!inst.playing){
                    if(FlxG.keys.anyPressed([UP, W])){
                        var daTime:Float = conductor.stepCrochet * 0.05;
                        inst.time -= daTime;
                    }
                    if(FlxG.keys.anyPressed([DOWN, S])){
                        var daTime:Float = conductor.stepCrochet * 0.05;
                        inst.time += daTime;
                    }
                }
        
                if(FlxG.keys.anyJustPressed([LEFT, A])){changeStrum(-1);}
                if(FlxG.keys.anyJustPressed([RIGHT, D])){changeStrum(1);}
            }
    
            if(FlxG.mouse.justPressed){
                if(FlxG.mouse.overlaps(gridGroup) && !FlxG.mouse.overlaps(MENU)){
                    for(g in gridGroup){
                        if(gridGroup.members[0] == g){continue;}
                        if(!FlxG.mouse.overlaps(g)){continue;}
                        if(g.ID == curStrum){continue;}
                        changeStrum(g.ID, true);
                        break;
                    }
                }
            }
            
            if(FlxG.keys.justPressed.ENTER && onConfirm == null){
                FlxG.save.data.autosave = song;
                lastSection = curSection;
                Songs.quickPlay(song);
            }
        }

        var fgrid:FlxSprite = gridGroup.members[song.sections[curSection].strum + 1];
        focusStrum.setPosition(FlxMath.lerp(focusStrum.x, fgrid.x, 0.5), fgrid.y);
        if(focusStrum.width != fgrid.width || focusStrum.height != fgrid.height){focusStrum.makeGraphic(Std.int(FlxMath.lerp(focusStrum.width, fgrid.width, 0.5)), Std.int(FlxMath.lerp(focusStrum.height, fgrid.height, 0.5)), FlxColor.YELLOW);}

        strumLine.x = curGrid.x;
        genFollow.setPosition(FlxMath.lerp(genFollow.x, curGrid.x + (curGrid.width / 2) + (MENU.width / 2), 0.50), strumLine.y);
        super.update(elapsed);
    }

    function changePause(toPause:Bool):Void {
        updateSection();

        if(toPause){
            inst.pause();
            for(voice in voices.sounds){voice.pause();}
        }else{
            inst.play(false, inst.time);
            for(voice in voices.sounds){voice.play(false, inst.time);}
        }
        for(voice in voices.sounds){voice.time = inst.time;}

        if(inst.playing){
            eveGrid.alpha = 0.5;
            cursor_Arrow.alpha = 0;
            for(grid in gridGroup){grid.alpha = 0.5;}
        }else{
            eveGrid.alpha = 1;
            cursor_Arrow.alpha = 0.5;
            Magic.doToMember(cast gridGroup, curStrum + 1, function(grid){grid.alpha = 1;}, function(grid){grid.alpha = 0.5;});
        }

    }

    function updateNoteValues():Void {
        if(selNote != null){
            stpStrumLine.value = selNote.strumTime;
            stpNoteLength.value = selNote.sustainLength;
            stpNoteHits.value = selNote.multiHits;
            clNotePressets.setLabel(selNote.preset, true);
            var event_list:Array<String> = []; for(e in selNote.eventData){event_list.push(e[0]);} clNoteEventList.setData(event_list);
            clNoteEventList.setLabel(clNoteEventList.getSelectedLabel(), false, true);
        }else{
            stpStrumLine.value = 0;
            stpNoteLength.value = 0;
            stpNoteHits.value = 0;
            clNotePressets.setLabel("Default", true);
            clNoteEventList.setData([]); clNoteEventList.setLabel(clNoteEventList.getSelectedLabel(), false, true);
        }

        if(selEvent != null){
            stpEventStrumLine.value = selEvent.strumTime;
            var event_list:Array<String> = []; for(e in selEvent.eventData){event_list.push(e[0]);} clEventListEvents.setData(event_list);
            clEventListEvents.setLabel(clEventListEvents.getSelectedLabel(), false, true);
            btnChangeEventFile.label.text = selEvent.isExternal ? "Global Event" : "Local Event";
            if(selEvent.isExternal){
                btnBrokeExternalEvent.active = true;
                btnBrokeExternalEvent.alpha = 1;
                btnBrokeExternalEvent.label.text = selEvent.isBroken ? "Event Broken" : "Event Active";
            }else{
                btnBrokeExternalEvent.active = false;
                btnBrokeExternalEvent.alpha = 0.5;
                btnBrokeExternalEvent.label.text = "Event is Local";
            }
        }else{
            stpEventStrumLine.value = 0;
            clEventListEvents.setData([]); clEventListEvents.setLabel(clEventListEvents.getSelectedLabel(), false, true);
        }
    }

    function updateValues():Void {
        var arrChars = []; for(c in song.characters){arrChars.push(c[0]);}
        
        if(song.strums.length == 2){stpSwapSec.value = curStrum == 1 ? 0 : 1;}

        clEventListToNote.setData(Note.getEvents(true,song.stage));
        clEventListToEvents.setData(Note.getEvents(song.stage));

        if(voices.sounds.length <= 1){chkMuteVocal.kill();}else{chkMuteVocal.revive();}
        chkMuteVocal.checked = sVoicesArray[curStrum];
        chkDoHits.checked = sHitsArray[curStrum];
        
        if(song.strums[curStrum] != null){
            chkPlayable.checked = song.strums[curStrum].playable;
            stpSrmKeys.value = song.strums[curStrum].keys;
            clNoteStyle.setLabel(song.strums[curStrum].style, true);
        }

        if(song.strums[curStrum].sections[curSection] != null){
            chkALT.checked = song.strums[curStrum].sections[curSection].changeAlt;
        }

        if(song.sections[curSection] != null){
            stpSecBPM.value = song.sections[curSection].bpm;
            chkBPM.checked = song.sections[curSection].changeBPM;
            stpLength.value = song.sections[curSection].lengthInSteps;
            stpSecStrum.value = song.sections[curSection].strum;
    
            var arrGenChars = [];
            for(c in song.strums[song.sections[curSection].strum].characters){arrGenChars.push(arrChars[c]);}
            clGenFocusChar.setData(arrGenChars);    
        }
    }

    override function stepHit(){super.stepHit();}
    override function beatHit(){super.beatHit();}

    function setupNote(note:Dynamic, ?grid:Int):Void {
        note.setGraphicSize(KEYSIZE, KEYSIZE);
        note.updateHitbox();

        note.y = Math.floor(getYfromStrum((note.strumTime - sectionStartTime())));
        note.x = gridGroup.members[grid + 1].x;
        if(!(note is StrumEvent)){note.x += Math.floor(note.noteData * KEYSIZE);}
    }

    function changeStrum(value:Int = 0, force:Bool = false):Void{
        curStrum = !force ? curStrum + value : value;

        if(curStrum >= song.strums.length){curStrum = song.strums.length - 1;}
        if(curStrum < 0){curStrum = 0;}

        curGrid = gridGroup.members[curStrum + 1];
        if(curGrid == null){return;}
        
        if(!inst.playing){
            for(g in gridGroup){g.alpha = 0.5;}
            curGrid.alpha = 1;
        }

        if(strumLine.width != Std.int(curGrid.width)){strumLine.makeGraphic(Std.int(curGrid.width), 4);}
        
        updateValues();
    }

    
    function loadSong(daSong:String, cat:String, diff:String) {
        resetSection(true);

		persistentUpdate = false;

        song = Song.load(Song.format(daSong, cat, diff));
		MusicBeatState.loadState("states.editors.ChartEditorState", [this.onConfirm, this.onBack], [[{type:"SONG",instance:song}], false]);
    }

    function loadAudio(daSong:String, cat:String):Void {
		if(inst != null){inst.stop();}

        inst = new FlxSound().loadEmbedded(Paths.inst(daSong, cat).getSound());
        FlxG.sound.list.add(inst);

        sVoicesArray = [];
        voices.sounds = [];
        if(song.voices){
            for(i in 0...song.strums.length){
				if(song.strums[i].characters.length <= 0){continue;}
				if(song.characters.length <= song.strums[i].characters[0]){continue;}
				var voice_path:String = Paths.voice(i, song.characters[song.strums[i].characters[0]][0], daSong, cat);
                if(!Paths.exists(voice_path)){continue;}
                var voice = new FlxSound().loadEmbedded(voice_path.getSound());
                FlxG.sound.list.add(voice);
                sVoicesArray.push(false);
                voices.add(voice);
            }
        }

		inst.onComplete = function(){
			voices.pause();
			inst.pause();
			inst.time = 0;
            for(voice in voices.sounds){voice.time = 0;}
			changeSection();
		};
	}

    function recalculateSteps():Int{
        var lastChange:BPMChangeEvent = {
            stepTime: 0,
            songTime: 0,
            bpm: 0
        }

        for(i in 0...conductor.bpmChangeMap.length){
            if(inst.time > conductor.bpmChangeMap[i].songTime){
                lastChange = conductor.bpmChangeMap[i];
            }
        }
    
        curStep = lastChange.stepTime + Math.floor((inst.time - lastChange.songTime) / conductor.stepCrochet);
        updateBeat();
    
        return curStep;
    }

    function resetSection(songBeginning:Bool = false):Void{
        updateSection();
    
        inst.pause();
        for(voice in voices.sounds){voice.pause();}
    
        // Basically old shit from changeSection???
        inst.time = sectionStartTime();
    
        if(songBeginning){
            inst.time = 0;
            curSection = 0;
        }
    
        for(voice in voices.sounds){voice.time = inst.time;}
        updateCurStep(); updateSection();
    }

    function changeNoteSustain(value:Int):Void{
        updateSelectedNote(function(curNote){
            curNote.sustainLength += conductor.stepCrochet * value;
            curNote.sustainLength = Math.max(curNote.sustainLength, 0);
    
            if(curNote.sustainLength <= 0 && curNote.multiHits > 0){curNote.multiHits = 0;}
        });
    }

    function changeNoteHits(value:Int):Void{
        updateSelectedNote(function(curNote){
            curNote.multiHits += value;
            curNote.multiHits = Std.int(Math.max(curNote.multiHits, 0));
            
            if(curNote.multiHits > 0 && curNote.sustainLength <= 0){changeNoteSustain(1);}
        });
    }

    function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void{
		if(song.sections[sec] == null){trace("Null Section"); return;}
        
        curSection = sec;
        updateSection();

		if(updateMusic){
			inst.pause();
			voices.pause();

			inst.time = sectionStartTime();
            for(voice in voices.sounds){voice.time = inst.time;}
			updateCurStep();
		}
	}

    private function addGenSection(lengthInSteps:Int = 16):Void{
        var genSec:GeneralSection_Data = {
            bpm: song.bpm,
            changeBPM: false,
    
            lengthInSteps: lengthInSteps,
    
            strum: song.sections[Std.int(Math.min(curSection, song.sections.length - 1))].strum,
            character: song.sections[Std.int(Math.min(curSection, song.sections.length - 1))].character
        };

        song.sections.push(genSec);
    }

    private function addSection(strum:Int = 0, lengthInSteps:Int = 16, keys:Int = 4):Void{
        var sec:Section_Data = {
            characters: song.strums[strum].characters,
            changeCharacters: false,
    
            changeAlt: false,
    
            notes: []
        };

        song.strums[strum].sections.push(sec);
    }

    private function getSwagEvent(event:Array<Dynamic>):Array<Dynamic> {
        if(song.events == null){return null;}
        for(e in song.events){if(Note.compare(Note.getEventData(event), Note.getEventData(e), false)){return e;}}
        return null;
    }
    private function getSwagNote(note:Array<Dynamic>, ?strum:Int):Array<Dynamic> {
        if(strum == null){strum = curStrum;}
        if(song.strums[strum] == null || song.strums[strum].sections[curSection] == null || song.strums[strum].sections[curSection].notes == null){return null;}
        for(n in song.strums[strum].sections[curSection].notes){if(Note.compare(Note.getNoteData(note), Note.getNoteData(n))){return n;}}
        return null;
    }
    
    private function updateSelectedEvent(func:Event_Data->Void, nuFunc:Void->Void = null, updateValues:Bool = true):Void {
        var e = getSwagEvent(Note.convEventData(selEvent));
        if(e == null){
            if(nuFunc != null){nuFunc();}
        }else{
            var curEvent:Event_Data = Note.getEventData(e);
            func(curEvent);        
            Note.set_note(e, Note.convEventData(curEvent));
            selEvent = Note.getEventData(Note.convEventData(curEvent));
        }

        if(updateValues){updateNoteValues(); updateSection();}
    }
    private function updateSelectedNote(func:Note_Data->Void, nuFunc:Void->Void = null, updateValues:Bool = true):Void {
        var n = getSwagNote(Note.convNoteData(selNote));
        if(n == null){
            if(nuFunc != null){nuFunc();}
        }else{
            var curNote:Note_Data = Note.getNoteData(n);    
            func(curNote);            
            Note.set_note(n, Note.convNoteData(curNote));
            selNote = curNote;
        }

        if(updateValues){updateNoteValues(); updateSection();}
    }

    private function reloadSelectedEvent():Void {
        selEvent.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        for(e in song.events.copy()){if(Note.compare(selEvent, Note.getEventData(e), false)){selEvent = Note.getEventData(e); break;}}
        updateNoteValues(); updateSection();
    }
    private function reloadSelectedNote():Void {
        selNote.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        selNote.keyData = Math.floor((FlxG.mouse.x - curGrid.x) / KEYSIZE) % song.strums[curStrum].keys;
        for(n in song.strums[curStrum].sections[curSection].notes.copy()){if(Note.compare(selNote, Note.getNoteData(n))){selNote = Note.getNoteData(n); break;}}
        updateNoteValues(); updateSection();
    }

    private function checkToAddEvent():Void{
        var _event:Event_Data = Note.getEventData();
        _event.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();

        for(e in song.events){
            if(!Note.compare(_event, Note.getEventData(e), false)){continue;}
            song.events.remove(e);
            updateNoteValues(); updateSection();
            return;
        }

        song.events.push(Note.convEventData(_event));
        selEvent = Note.getEventData(Note.convEventData(_event));
        updateNoteValues();
        updateSection();
    }
    private function checkToAddNote(isRelease:Bool = false):Void{
        var _note:Note_Data = Note.getNoteData();
        _note.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        _note.keyData = Math.floor((FlxG.mouse.x - curGrid.x) / KEYSIZE) % song.strums[curStrum].keys;
        _note.preset = '${selNote.preset}';

        for(n in song.strums[curStrum].sections[curSection].notes){
            if(!Note.compare(_note, Note.getNoteData(n))){continue;}
            song.strums[curStrum].sections[curSection].notes.remove(n);
            updateNoteValues(); updateSection();
            return;
        }

        song.strums[curStrum].sections[curSection].notes.push(Note.convNoteData(_note));
        selNote = _note;
        updateNoteValues();
        updateSection();
    }

    function getYfromStrum(strumTime:Float):Float {    
        if(curGrid != null){return FlxMath.remapToRange(strumTime, 0, song.sections[curSection].lengthInSteps * conductor.stepCrochet, curGrid.y, curGrid.y + curGrid.height);}
        return 0;
    }

    function getStrumTime(yPos:Float):Float{
        if(curGrid != null){return FlxMath.remapToRange(yPos, curGrid.y, curGrid.y + curGrid.height, 0, song.sections[curSection].lengthInSteps * conductor.stepCrochet);}
        return 0;
    }

    function sectionStartTime(newSection:Int = 0):Float {
        var daBPM:Float = song.bpm;
        var daPos:Float = 0;
        for(i in 0...(curSection + newSection)){
            if(song.sections[i] != null && song.sections[i].changeBPM){
                daBPM = song.sections[i].bpm;
            }
            daPos += 4 * (1000 * 60 / daBPM);
        }

        return daPos;
    }

    function copyLastSection(?sectionNum:Int = 1){
        var daSec = FlxMath.maxInt(curSection, sectionNum);
    
        for(strum in 0...song.strums.length){
            for(note in song.strums[strum].sections[daSec - sectionNum].notes){
                var curNote:Note_Data = Note.getNoteData(note);
                curNote.strumTime = curNote.strumTime + conductor.stepCrochet * (song.sections[daSec].lengthInSteps * sectionNum);
                if(getSwagNote(Note.convNoteData(curNote), strum) == null){song.strums[strum].sections[daSec].notes.push(Note.convNoteData(curNote));}
            }
        }        
    
        updateSection();
    }

    function copyLastStrum(?sectionNum:Int = 1, ?strum:Int = 0){
        var daSec = FlxMath.maxInt(curSection, sectionNum);
    
        for(note in song.strums[strum].sections[daSec - sectionNum].notes){
            var curNote:Note_Data = Note.getNoteData(note);
            curNote.strumTime = curNote.strumTime + conductor.stepCrochet * (song.sections[daSec].lengthInSteps * sectionNum);
            if(getSwagNote(Note.convNoteData(curNote), curStrum) == null){song.strums[curStrum].sections[daSec].notes.push(Note.convNoteData(curNote));}
        }
    
        updateSection();
    }

    function mirrorNotes(?strum:Int = null){
        if(strum == null){strum = curStrum;}

        var secNotes:Array<Dynamic> = song.strums[strum].sections[curSection].notes;
        var keyLength:Int = song.strums[strum].keys;

        for(i in 0...secNotes.length){
            var curNote:Note_Data = Note.getNoteData(secNotes[i]);
            curNote.keyData = keyLength - curNote.keyData - 1;
            secNotes[i] = Note.convNoteData(curNote);
        }

        song.strums[strum].sections[curSection].notes = secNotes;

        updateSection();
    }

    function syncNotes(){
        var allSection:Array<Dynamic> = [];
        for(section in song.strums){
            for(n in section.sections[curSection].notes){
                var hasNote:Bool = false;
                for(na in allSection){if(Note.compare(Note.getNoteData(na), Note.getNoteData(n))){hasNote = true; break;}}
                if(!hasNote){allSection.push(n);}
            }
        }
        
        for(section in song.strums){section.sections[curSection].notes = allSection.copy();}

        updateSection();
    }

    private function getFile(_onSelect:String->Void):Void{
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str){_onSelect(str);});
        fDialog.browse();
	}

    var sub_menu:FlxUITabMenu;
    var txtSong:FlxUIInputText;
    var txtCat:FlxUIInputText;
    var txtDiff:FlxUIInputText;
    var txtStage:FlxUIInputText;
    var txtStyle:FlxUIInputText;
    var stpPlayer:FlxUINumericStepper;
    var stpBPM:FlxUINumericStepper;
    var stpSpeed:FlxUINumericStepper;
    var stpSecBPM:FlxUINumericStepper;
    var stpLength:FlxUINumericStepper;
    var stpSecStrum:FlxUINumericStepper;
    var stpSrmKeys:FlxUINumericStepper;
    var stpLastSec:FlxUINumericStepper;
    var stpSwapSec:FlxUINumericStepper;
    var stpStrumLine:FlxUINumericStepper;
    var stpEventStrumLine:FlxUINumericStepper;
    var stpNoteLength:FlxUINumericStepper;
    var stpNoteHits:FlxUINumericStepper;
    var chkALT:FlxUICheckBox;
    var chkBPM:FlxUICheckBox;
    var chkHasVoices:FlxUICheckBox;
    var chkHideChart:FlxUICheckBox;
    var chkHideStrums:FlxUICheckBox;
    var chkMuteInst:FlxUICheckBox;
    var chkMuteVoices:FlxUICheckBox;
    var chkMuteVocal:FlxUICheckBox;
    var chkDoHits:FlxUICheckBox;
    var chkPlayable:FlxUICheckBox;
    var chkMuteHitSounds:FlxUICheckBox;
    var clEventListToNote:UIList;
    var clNoteEventList:UIList;
    var clNotePressets:UIList;
    var clNoteCondFunc:UIList;
    var clEventListToEvents:UIList;
    var clEventListEvents:UIList;
    var clNoteStyle:UIList;
    var clGenFocusChar:UIList;
    var btnChangeEventFile:FlxUIButton;
    var btnBrokeExternalEvent:FlxUIButton;
    var note_event_sett_group:FlxUIGroup;
    var event_sett_group:FlxUIGroup;
    function addMENUTABS():Void{
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "5Song";

        chkHasVoices = new FlxUICheckBox(25, 15, null, null, "\nSong has Voices?", 100); tabMENU.add(chkHasVoices);
        chkHasVoices.checked = song.voices;
        
        var btnReload = new UIButton(chkHasVoices.x + chkHasVoices.width + 30, chkHasVoices.y, Std.int((MENU.width / 4)), null, "Reload Audio", null, null, () -> {loadAudio(song.song, song.category);}); tabMENU.add(btnReload);

        var btnSave:FlxButton = new FlxCustomButton(30, chkHasVoices.y + chkHasVoices.height + 20, Std.int((MENU.width / 3)), null, "Save Song", null, null, () -> {
            canAutoSave = false; canControlle = false;
            save_song(Song.format(song.song,song.category,song.difficulty), song, {saveAs: true, onComplete: () -> {canAutoSave = true; canControlle = true;}});
        }); tabMENU.add(btnSave);

        var btnLoad:FlxButton = new FlxCustomButton(btnSave.x + btnSave.width + 30, btnSave.y, Std.int(MENU.width / 3), null, "Load Song", null, null, () -> {loadSong(song.song, song.category, song.difficulty);}); tabMENU.add(btnLoad);

        var btnImport:FlxButton = new FlxCustomButton(btnSave.x, btnSave.y + btnSave.height + 10, Std.int((MENU.width / 3)), null, "Import Chart", null, null, () -> {
            getFile((str) -> {
                var song_data:Song_File = cast Song.convert_song(Song.format(song.song, song.category, song.difficulty), str.getText().trim());
                Song.parse(song_data);

                song = song_data;
                
                updateSection();
            });
        }); tabMENU.add(btnImport);

        var btnAutoSave:FlxButton = new FlxCustomButton(btnImport.x + btnImport.width + 30, btnImport.y, Std.int((MENU.width / 3)), null, "Load Auto Save", null, null, function(){
            if(FlxG.save.data.autosave == null){return;}
            
            song = FlxG.save.data.autosave;
            Song.parse(song);

            FlxG.switchState(new states.LoadingState(new ChartEditorState(this.onBack, this.onConfirm), [{type:"SONG",instance:song}], false));
        }); tabMENU.add(btnAutoSave);

        var lblSong = new FlxText(25, btnImport.y + btnImport.height + 15, 0, "SONG:", 8); tabMENU.add(lblSong);
        txtSong = new FlxUIInputText(lblSong.x + lblSong.width + 5, lblSong.y, Std.int(MENU.width - lblSong.width - 50), Paths.format(song.song), 8); tabMENU.add(txtSong);
        arrayFocus.push(txtSong);
        txtSong.name = "SONG_NAME";

        var lblCat = new FlxText(25, txtSong.y + txtSong.height + 8, 0, "CATEGORY:", 8); tabMENU.add(lblCat);
        txtCat = new FlxUIInputText(lblCat.x + lblCat.width + 5, lblCat.y, Std.int(MENU.width - lblCat.width - 50), song.category, 8); tabMENU.add(txtCat);
        arrayFocus.push(txtCat);
        txtCat.name = "SONG_CATEGORY";

        var lblDiff = new FlxText(25, txtCat.y + txtCat.height + 8, 0, "DIFFICULTY:", 8); tabMENU.add(lblDiff);
        txtDiff = new FlxUIInputText(lblDiff.x + lblDiff.width + 5, lblDiff.y, Std.int(MENU.width - lblDiff.width - 50), song.difficulty, 8); tabMENU.add(txtDiff);
        arrayFocus.push(txtDiff);
        txtDiff.name = "SONG_DIFFICULTY";
        
        var lblPlayer = new FlxText(25, lblDiff.y + lblDiff.height + 15, 0, "Player: ", 8); tabMENU.add(lblPlayer);
        stpPlayer = new FlxUINumericStepper(lblPlayer.x, lblPlayer.y + lblPlayer.height, 1, song.player, 0, 999); tabMENU.add(stpPlayer);
            @:privateAccess arrayFocus.push(cast stpPlayer.text_field);
        stpPlayer.name = "SONG_Player";

        var lblSpeed = new FlxText(stpPlayer.x + stpPlayer.width + 32, lblPlayer.y, 0, "Scroll Speed: ", 8); tabMENU.add(lblSpeed);
        stpSpeed = new FlxUINumericStepper(lblSpeed.x, lblSpeed.y + lblSpeed.height, 0.1, song.speed, 0.1, 10, 1); tabMENU.add(stpSpeed);
            @:privateAccess arrayFocus.push(cast stpSpeed.text_field);
        stpSpeed.name = "SONG_Speed";
        
        var lblBPM = new FlxText(stpSpeed.x + stpSpeed.width + 32, lblSpeed.y, 0, "BPM: ", 8); tabMENU.add(lblBPM);
        stpBPM = new FlxUINumericStepper(lblBPM.x, lblBPM.y + lblBPM.height, 1, song.bpm, 5, 999); tabMENU.add(stpBPM);
            @:privateAccess arrayFocus.push(cast stpBPM.text_field);
        stpBPM.name = "SONG_BPM";
        
        chkMuteInst = new FlxUICheckBox(25, stpPlayer.y + stpPlayer.height + 10, null, null, "Mute Inst", 50); tabMENU.add(chkMuteInst);
        chkMuteVoices = new FlxUICheckBox(chkMuteInst.x + chkMuteInst.width + 15, chkMuteInst.y, null, null, "Mute Voices", 60); tabMENU.add(chkMuteVoices);
        chkMuteHitSounds = new FlxUICheckBox(chkMuteVoices.x + chkMuteVoices.width + 15, chkMuteInst.y, null, null, "Mute HitSounds", 60); tabMENU.add(chkMuteHitSounds);

        var lblStage = new FlxText(30, chkMuteInst.y + chkMuteInst.height + 20, 0, "Stage: ", 8);  tabMENU.add(lblStage);
        txtStage = new FlxUIInputText(lblStage.x + lblStage.width, lblStage.y, Std.int(MENU.width - lblStage.width - 70), song.stage, 8); tabMENU.add(txtStage);
        arrayFocus.push(txtStage);
        txtStage.name = "SONG_STAGE";

        var lblStyle = new FlxText(30, lblStage.y + lblStage.height + 8, 0, "Style: ", 8);  tabMENU.add(lblStyle);
        txtStyle = new FlxUIInputText(lblStyle.x + lblStyle.width, lblStyle.y, Std.int(MENU.width - lblStyle.width - 70), song.style, 8); tabMENU.add(txtStyle);
        arrayFocus.push(txtStyle);
        txtStyle.name = "SONG_STYLE";

        // Characters SubMenu --------------------
        sub_menu = new FlxUITabMenu(null, [], true);
		sub_menu.y = lblStyle.y + lblStyle.height + 15;
        sub_menu.resize(300, 75);
        tabMENU.add(sub_menu);
        
        var subTabChars = new FlxUI(null, sub_menu);
        subTabChars.name = "FNF_Characters";
        sub_menu.addGroup(subTabChars);

        var lblGf = new FlxText(25, 5, 0, "Girlfriend:", 8); subTabChars.add(lblGf);
        var txtGf = new FlxUIInputText(lblGf.x + lblGf.width + 5, 5, Std.int(MENU.width - lblGf.width - 60), song.characters.length >= 1 ? song.characters[0][0] : "Girlfriend", 8); subTabChars.add(txtGf);
        arrayFocus.push(txtGf); txtGf.name = "CHAR_GF";

        var lblOpp = new FlxText(25, 30, 0, "Opponent:", 8); subTabChars.add(lblOpp);
        var txtOpp = new FlxUIInputText(lblGf.x + lblGf.width + 5, 30, Std.int(MENU.width - lblOpp.width - 60), song.characters.length >= 2 ? song.characters[1][0] : "Daddy_Dearest", 8); subTabChars.add(txtOpp);
        arrayFocus.push(txtOpp); txtOpp.name = "CHAR_OPP";

        var lblBf = new FlxText(25, 55, 0, "Boyfriend:", 8); subTabChars.add(lblBf);
        var txtBf = new FlxUIInputText(lblGf.x + lblGf.width + 5, 55, Std.int(MENU.width - lblBf.width - 60), song.characters.length >= 3 ? song.characters[2][0] : "Boyfriend", 8); subTabChars.add(txtBf);
        arrayFocus.push(txtBf); txtBf.name = "CHAR_BF";

        sub_menu.showTabId("FNF_Characters");
        // Characters SubMenu --------------------

        var btnCustomCharacters:FlxButton = new FlxCustomButton(25, lblBf.y + lblBf.height + 20, Std.int(MENU.width - 50), null, "Customize your Characters", null, null, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.editors.CharacterEditorSubState", [song, stage, function(){
                persistentUpdate = true; canControlle = true;
                if(song.characters.length != 3){
                    sub_menu.kill();
                }else{
                    sub_menu.revive();
                    txtGf.text = song.characters[0][0];
                    txtOpp.text = song.characters[1][0];
                    txtBf.text = song.characters[2][0];
                }

                for(s in song.strums){
                    for(c in s.characters){if(c >= song.characters.length){s.characters.remove(c);}}
                    for(ss in s.sections){for(c in ss.characters){if(c >= song.characters.length){ss.characters.remove(c);}}}
                }
            }]);
        }); tabMENU.add(btnCustomCharacters);

        var btnAddStrum:FlxButton = new FlxCustomButton(25, btnCustomCharacters.y + btnCustomCharacters.height + 15, Std.int(MENU.width / 2 - 35), null, "Add Strum", null, null, function(){
            var nStrum:Strum_Data = {
                playable: true,
                keys: 4,
                style: "Default",
                characters: [0],
                sections: [
                    {
                        characters: [0],
                        changeCharacters: false,

                        changeAlt: false,

                        notes: []
                    }
                ]
            };

            song.strums.push(nStrum);

            for(i in 0...curSection){addSection(song.strums.length - 1, song.sections[i].lengthInSteps);}

            updateSection();
        }); tabMENU.add(btnAddStrum);

        var btnDelStrum:FlxButton = new FlxCustomButton(btnAddStrum.x + btnAddStrum.width + 30, btnAddStrum.y, Std.int(MENU.width / 2 - 35), null, "Delete Strum", null, FlxColor.RED, function(){
            if(song.strums.length <= 1){return;}
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete the Current Strum?", function(){
                song.strums.remove(song.strums[curStrum]);
                for(section in song.sections){if(section.strum >= song.strums.length){section.strum = song.strums.length - 1;}}
                changeStrum(-1);            
                updateSection();                
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnDelStrum); btnDelStrum.label.color = FlxColor.WHITE;
        btnDelStrum.x = btnCustomCharacters.x + btnCustomCharacters.width - btnDelStrum.width;

        var btnClearSong:FlxButton = new FlxCustomButton(5, MENU.height - 10, Std.int((MENU.width - 10)), null, "Clear Song Notes", null, FlxColor.RED, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete all Notes of the Song?", function(){
                for(i in song.strums){for(ii in i.sections){ii.notes = [];}}
                updateSection();              
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnClearSong);
        var btnClearSongStrum:FlxButton = new FlxCustomButton(5, btnClearSong.y + btnClearSong.height + 10, Std.int((MENU.width - 10)), null, "Clear Current Strum Notes", null, FlxColor.RED, function(){
            if(song.strums[curStrum] == null){return;}
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete all Notes of the Strum?", function(){
                for(i in song.strums[curStrum].sections){i.notes = [];}
                updateSection();
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnClearSongStrum);
        var btnClearSongEvents:FlxButton = new FlxCustomButton(5, btnClearSongStrum.y + btnClearSongStrum.height + 10, Std.int((MENU.width - 10)), null, "Clear Song Events", null, FlxColor.RED, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete all Events of the Song?", function(){
                song.events = [];
                updateSection();
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnClearSongEvents);
        btnClearSong.label.color = FlxColor.WHITE; btnClearSongStrum.label.color = FlxColor.WHITE; btnClearSongEvents.label.color = FlxColor.WHITE;

        MENU.addGroup(tabMENU);

        //=========================================================================================================================

        var tabSTRUM = new FlxUI(null, MENU);
        tabSTRUM.name = "4Section";

        var lblStrumSec = new FlxText(5, 5, MENU.width - 10, "Strum Section"); tabSTRUM.add(lblStrumSec);
        lblStrumSec.alignment = CENTER;

        var lblKeys = new FlxText(25, lblStrumSec.y + lblStrumSec.height + 15, 0, "Strum Keys: ", 8); tabSTRUM.add(lblKeys);
        stpSrmKeys = new FlxUINumericStepper(lblKeys.x + lblKeys.width, lblKeys.y, 1, song.strums[curStrum].keys, 1, 10); tabSTRUM.add(stpSrmKeys);
            @:privateAccess arrayFocus.push(cast stpSrmKeys.text_field);
        stpSrmKeys.name = "STRUM_KEYS";

        chkPlayable = new FlxUICheckBox(170, lblKeys.y, null, null, "Is Playable"); tabSTRUM.add(chkPlayable);
        chkPlayable.checked = song.strums[curStrum].playable;

        clNoteStyle = new UIList(25, lblKeys.y + lblKeys.height + 15, Std.int(MENU.width) - 50, Note.getStyles(), function(){
            if(song.strums[curStrum] == null){return;}
            song.strums[curStrum].style = clNoteStyle.getSelectedLabel();
            updateSection(); reloadChartGrid(true);
        }); tabSTRUM.add(clNoteStyle);
        clNoteStyle.setPrefix('Note Style: ');
        
        chkALT = new FlxUICheckBox(25, clNoteStyle.y + clNoteStyle.height + 20, null, null, "\nChange Strum ALT"); tabSTRUM.add(chkALT);
        chkALT.checked = song.strums[curStrum].sections[curSection].changeAlt;

        var btnCSing:FlxButton = new FlxCustomButton(150, chkALT.y, 120, null, "Sing Characters", null, null, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.editors.SingEditorSubState", [song, stage, curStrum, curSection, function(){
                persistentUpdate = true; canControlle = true;
            }]);
        }); tabSTRUM.add(btnCSing);

        chkMuteVocal = new FlxUICheckBox(25, chkALT.y + chkALT.height + 20, null, null, "Mute Strum Voice", 80); tabSTRUM.add(chkMuteVocal);
        chkDoHits = new FlxUICheckBox(150, chkMuteVocal.y, null, null, "\nActive HitSounds", 100); tabSTRUM.add(chkDoHits);

        var nLine = new FlxSprite(5, chkMuteVocal.y + chkMuteVocal.height + 15).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabSTRUM.add(nLine);

        var lblGenSec = new FlxText(5, nLine.y + 5, MENU.width - 10, "General Section"); tabSTRUM.add(lblGenSec);
        lblGenSec.alignment = CENTER;

        chkBPM = new FlxUICheckBox(25, lblGenSec.y + lblGenSec.height + 15, null, null, "Change BPM", 100); tabSTRUM.add(chkBPM);
		chkBPM.checked = song.sections[curSection].changeBPM;
        var lblBPM = new FlxText(chkBPM.x + chkBPM.width + 15, chkBPM.y, 0, "BPM: ", 8); tabSTRUM.add(lblBPM);
        stpSecBPM = new FlxUINumericStepper(lblBPM.x + lblBPM.width, lblBPM.y, 1, song.bpm, 5, 999); tabSTRUM.add(stpSecBPM);
            @:privateAccess arrayFocus.push(cast stpSecBPM.text_field);
        stpSecBPM.name = "GENERALSEC_BPM";

        var lblStrum = new FlxText(25, chkBPM.y + chkBPM.height + 18, 0, "Strum to Focus: ", 8); tabSTRUM.add(lblStrum);
        stpSecStrum = new FlxUINumericStepper(lblStrum.x + lblStrum.width, lblStrum.y, 1, song.sections[curSection].strum, 0, 999); tabSTRUM.add(stpSecStrum);
            @:privateAccess arrayFocus.push(cast stpSecStrum.text_field);
        stpSecStrum.name = "GENERALSEC_strum";

        clGenFocusChar = new UIList(lblStrum.x, lblStrum.y + lblStrum.height, Std.int(lblStrum.width + stpSecStrum.width), 12, [], song.sections[curSection].character, function(){
            song.sections[curSection].character = clGenFocusChar.getSelectedIndex();
        });  tabSTRUM.add(clGenFocusChar);

        var lblLength = new FlxText(25, clGenFocusChar.y + clGenFocusChar.height + 15, 0, "Section Length (In steps): ", 8); tabSTRUM.add(lblLength);
        stpLength = new FlxUINumericStepper(lblLength.x + lblLength.width, lblLength.y, 4, song.sections[curSection].lengthInSteps, 4, 32, 0); tabSTRUM.add(stpLength);
            @:privateAccess arrayFocus.push(cast stpLength.text_field);
        stpLength.name = "GENERALSEC_LENGTH";

        var btnCopy:FlxButton = new FlxCustomButton(25, lblLength.y + lblLength.height + 15, Std.int((MENU.width / 3) - 10), null, "Copy Section", null, null, function(){
            copySection = [curSection, []];
            for(i in 0...song.strums.length){
                copySection[1].push([]);
                for(n in song.strums[i].sections[curSection].notes){
                    var curNote:Note_Data = Note.getNoteData(n);
                    curNote.strumTime -= sectionStartTime();
                    copySection[1][i].push(Note.convNoteData(curNote));
                }
            }
        }); tabSTRUM.add(btnCopy);

        var btnPaste:FlxButton = new FlxCustomButton(btnCopy.x + btnCopy.width + 25, btnCopy.y, Std.int((MENU.width / 3) - 6), null, "Paste Section", null, null, function(){
            if(copySection == null || copySection[1] == null){return;}
            for(i in 0...song.strums.length){
                if(copySection[1][i] == null){continue;}

                var secNotes:Array<Dynamic> = copySection[1][i].copy();
                for(n in secNotes){
                    var curNote:Note_Data = Note.getNoteData(n);
                    curNote.strumTime += sectionStartTime();

                    if(getSwagNote(Note.convNoteData(curNote), i) == null){song.strums[i].sections[curSection].notes.push(Note.convNoteData(curNote));}
                }
            }
            updateSection();
        }); tabSTRUM.add(btnPaste);

        var btnLastSec:FlxButton = new FlxCustomButton(25, btnCopy.y + btnCopy.height + 15, Std.int((MENU.width / 2) - 20), null, "Paste Last Section", null, null, function(){
            copyLastSection(Std.int(stpLastSec.value));
        }); tabSTRUM.add(btnLastSec);
        stpLastSec = new FlxUINumericStepper(btnLastSec.x + btnLastSec.width + 10, btnLastSec.y + 3, 1, 0, -999, 999); tabSTRUM.add(stpLastSec);
            @:privateAccess arrayFocus.push(cast stpLastSec.text_field);
        
        var btnMirror:FlxButton = new FlxCustomButton(25, btnLastSec.y + btnLastSec.height + 15, 100, null, "Mirror Section", null, null, function(){for(i in 0...song.strums.length){mirrorNotes(i);}}); tabSTRUM.add(btnMirror);
        var btnSync:FlxButton = new FlxCustomButton(btnMirror.x + btnMirror.width + 15, btnMirror.y, 130, null, "Synchronize Notes", null, null, function(){syncNotes();}); tabSTRUM.add(btnSync);
        var btnSwapStrum:FlxButton = new FlxCustomButton(25, btnMirror.y + btnMirror.height + 15, Std.int((MENU.width / 2) - 3), null, "Swap Strum", null, null, function(){
            var sec1 = song.strums[curStrum].sections[curSection].notes;
            var sec2 = song.strums[Std.int(stpSwapSec.value)].sections[curSection].notes;

            song.strums[curStrum].sections[curSection].notes = sec2;
            song.strums[Std.int(stpSwapSec.value)].sections[curSection].notes = sec1;

            updateSection();
        }); tabSTRUM.add(btnSwapStrum);
        stpSwapSec = new FlxUINumericStepper(btnSwapStrum.x + btnSwapStrum.width + 5, btnSwapStrum.y + 3, 1, 0, 0, 999); tabSTRUM.add(stpSwapSec);
            @:privateAccess arrayFocus.push(cast stpSwapSec.text_field);
        stpSwapSec.name = "Strums_Length";

        var chkDEvents = new FlxUICheckBox(25, btnSwapStrum.y + btnSwapStrum.height + 15, null, null, "Events", 50); tabSTRUM.add(chkDEvents);
        var chkDNotes = new FlxUICheckBox(100, chkDEvents.y, null, null, "Notes", 50); tabSTRUM.add(chkDNotes);
        var chkDStrum = new FlxUICheckBox(175, chkDEvents.y, null, null, "Only Strum", 80); tabSTRUM.add(chkDStrum);

        var btnDelAllSec:FlxButton = new FlxCustomButton(5, chkDEvents.y + chkDEvents.height + 15, 250, null, "Clear Section", null, FlxColor.RED, function(){
            if(chkDNotes.checked){
                if(chkDStrum.checked){
                    song.strums[curStrum].sections[curSection].notes = [];
                }else{
                    for(strum in song.strums){strum.sections[curSection].notes = [];}
                }
            }
            if(chkDEvents.checked){
                for(e in song.events){
                    var eData:Event_Data = Note.getEventData(e);
                    if(eData.strumTime < sectionStartTime()){continue;}
                    if(eData.strumTime > sectionStartTime(1)){continue;}
                    song.events.remove(e);
                }
            }
            updateSection();
        }); tabSTRUM.add(btnDelAllSec); btnDelAllSec.label.color = FlxColor.WHITE;
        btnDelAllSec.x = MENU.width - btnDelAllSec.width - 25;
        
        MENU.addGroup(tabSTRUM);

        //===========================================================================================================================

        var tabNOTE = new FlxUI(null, MENU);
        tabNOTE.name = "3Note";

        var lblStrumLine = new FlxText(25, 15, 0, "StrumTime: ", 8); tabNOTE.add(lblStrumLine);
        stpStrumLine = new UINumericStepper(lblStrumLine.x + lblStrumLine.width, lblStrumLine.y, 120, conductor.stepCrochet * 0.5, 0, 0, 999999, 2); tabNOTE.add(stpStrumLine);
            @:privateAccess arrayFocus.push(cast stpStrumLine.text_field);
        stpStrumLine.name = "NOTE_STRUMTIME";

        var lblNoteLength = new FlxText(25, lblStrumLine.y + lblStrumLine.height + 10, 0, "Note Length: ", 8); tabNOTE.add(lblNoteLength);
        stpNoteLength = new UINumericStepper(lblNoteLength.x + lblNoteLength.width, lblNoteLength.y, 120, conductor.stepCrochet, 0, 0, 999999, 2); tabNOTE.add(stpNoteLength);
            @:privateAccess arrayFocus.push(cast stpNoteLength.text_field);
        stpNoteLength.name = "NOTE_LENGTH";

        var lblNoteHits = new FlxText(25, lblNoteLength.y + lblNoteLength.height + 10, 0, "Note Hits: ", 8); tabNOTE.add(lblNoteHits);
        stpNoteHits = new FlxUINumericStepper(lblNoteHits.x + lblNoteHits.width, lblNoteHits.y, 1, 0, 0, 999); tabNOTE.add(stpNoteHits);
            @:privateAccess arrayFocus.push(cast stpNoteHits.text_field);
        stpNoteHits.name = "NOTE_HITS";

        clNotePressets = new UIList(5, lblNoteHits.y + lblNoteHits.height + 5, Std.int(MENU.width - 10), Note.getPresets(), function(){
            updateSelectedNote(
                function(curNote){curNote.preset = clNotePressets.getSelectedLabel();},
                function(){selNote.preset = clNotePressets.getSelectedLabel();}
            );
        }); tabNOTE.add(clNotePressets);
        clNotePressets.setPrefix("Note Presset: ["); clNotePressets.setSuffix("]");
        
        clEventListToNote = new UIList(clNotePressets.x, clNotePressets.y + clNotePressets.height + 15, Std.int(MENU.width - 35), Note.getEvents(true)); tabNOTE.add(clEventListToNote);
        clEventListToNote.setPrefix("Event List: ["); clEventListToNote.setSuffix("]");

        var btnAddEventToNote = new UIButton(clEventListToNote.x + clEventListToNote.width + 5, clEventListToNote.y, 20, null, "+", null, null, function(){
            updateSelectedNote(
                function(curNote){
                    var cur_label:String = clEventListToNote.getSelectedLabel();
                    scripts.load(cur_label, Paths.event(cur_label));
                    var default_list:Array<Dynamic> = [];
                    for(setting in cast(scripts.get(cur_label).getVar("defaultValues"), Array<Dynamic>)){default_list.push(setting.value);}
                    curNote.eventData.push([cur_label, default_list, "OnHit"]);
                }
            );
            clNoteEventList.setIndex(selNote.eventData.length - 1);
        }); tabNOTE.add(btnAddEventToNote);
        
        clNoteEventList = new UIList(clEventListToNote.x, clEventListToNote.y + clEventListToNote.height + 5, Std.int(MENU.width) - 35, [], function(){
            updateSelectedNote(
                function(curNote){                
                    clNoteEventList.setSuffix('] (${clNoteEventList.getSelectedIndex() + 1}/${curNote.eventData.length})');
                    clNoteCondFunc.setLabel(curNote.eventData[clNoteEventList.getSelectedIndex()][2]);
                    loadNoteEventSettings(clNoteEventList.getSelectedLabel());
                    //try{txtNoteEventValues.text = Json.stringify(curNote.eventData[clNoteEventList.getSelectedIndex()][1]);}catch(e){trace(e); txtNoteEventValues.text = "[]";}
                },
                function(){
                    clNoteEventList.setData([]);
                    clNoteEventList.setSuffix('] (0/0)');
                    loadNoteEventSettings();
                    //txtNoteEventValues.text = "[]";
                }, false
            );
        }); tabNOTE.add(clNoteEventList);
        clNoteEventList.setPrefix("Current Event: ["); clNoteEventList.setSuffix("]");
        
        var btnDelEventToNote = new UIButton(clNoteEventList.x + clNoteEventList.width + 5, clNoteEventList.y, 20, null, "-", null, null, function(){
            updateSelectedNote(function(curNote){
                if(curNote.eventData.length <= 0){return;}
                curNote.eventData.remove(curNote.eventData[clNoteEventList.getSelectedIndex()]);
            });
            clNoteEventList.setIndex(selNote.eventData.length - 1);
        }); tabNOTE.add(btnDelEventToNote);

        clNoteCondFunc = new UIList(5, clNoteEventList.y + clNoteEventList.height + 5, Std.int(MENU.width - 10), ["OnHit", "OnMiss", "OnCreate"], function(){
            updateSelectedNote(function(curNote){
                if(curNote.eventData.length <= 0){return;}
                curNote.eventData[clNoteEventList.getSelectedIndex()][2] = clNoteCondFunc.getSelectedLabel();
            }, false);
        }); tabNOTE.add(clNoteCondFunc);
        clNoteCondFunc.setPrefix("Condition ("); clNoteCondFunc.setSuffix(")");

        note_event_sett_group = new FlxUIGroup(5, clNoteCondFunc.y + clNoteCondFunc.height + 5); tabNOTE.add(note_event_sett_group);
        note_event_sett_group.width = Std.int(MENU.width - 10);

        MENU.addGroup(tabNOTE);

        //===========================================================================================================================

        var tabEVENT = new FlxUI(null, MENU);
        tabEVENT.name = "2Event";
        
        var lblEventStrumLine = new FlxText(25, 15, 0, "StrumTime: ", 8); tabEVENT.add(lblEventStrumLine);
        stpEventStrumLine = new UINumericStepper(lblEventStrumLine.x + lblEventStrumLine.width, lblEventStrumLine.y, 120, conductor.stepCrochet * 0.5, 0, 0, 999999, 2); tabEVENT.add(stpEventStrumLine);
            @:privateAccess arrayFocus.push(cast stpEventStrumLine.text_field);
        stpEventStrumLine.name = "EVENT_STRUMTIME";

        clEventListToEvents = new UIList(25, lblEventStrumLine.y + lblEventStrumLine.height + 10, Std.int(MENU.width - 65), Note.getEvents()); tabEVENT.add(clEventListToEvents);
        clEventListToEvents.setPrefix("Event List: ["); clEventListToEvents.setSuffix("]");

        var btnAddEventToEvents = new UIButton(clEventListToEvents.x + clEventListToEvents.width + 5, clEventListToEvents.y, 20, null, "+", null, null, function(){
            updateSelectedEvent(
                function(curEvent){
                    var cur_label:String = clEventListToEvents.getSelectedLabel();
                    scripts.load(cur_label, Paths.event(cur_label));
                    var default_list:Array<Dynamic> = [];
                    for(setting in cast(scripts.get(cur_label).getVar("defaultValues"), Array<Dynamic>)){default_list.push(setting.value);}
                    curEvent.eventData.push([cur_label, default_list]);
                }
            );
        }); tabEVENT.add(btnAddEventToEvents);
        
        clEventListEvents = new UIList(25, clEventListToEvents.y + clEventListToEvents.height + 5, Std.int(MENU.width) - 65, [], function(){
            updateSelectedEvent(
                function(curEvent){                
                    clEventListEvents.setSuffix('] (${clEventListEvents.getSelectedIndex() + 1}/${curEvent.eventData.length})');
                    //try{txtCurEventValues.text = Json.stringify(curEvent.eventData[clEventListEvents.getSelectedIndex()][1]);}catch(e){trace(e); txtCurEventValues.text = "";}
                    loadEventSettings(clEventListEvents.getSelectedLabel());
                },
                function(){
                    clEventListEvents.setData([]);
                    clEventListEvents.setSuffix('] (0/0)');
                    //txtCurEventValues.text = "[]";
                    loadEventSettings();
                }, false
            );
        }); tabEVENT.add(clEventListEvents);
        clEventListEvents.setPrefix("Current Event: ["); clEventListEvents.setSuffix("]");
        
        var btnDelEventToNote = new UIButton(clEventListEvents.x + clEventListEvents.width + 5, clEventListEvents.y, 20, null, "-", null, null, function(){
            updateSelectedEvent(
                function(curEvent){
                    if(curEvent.eventData.length <= 0){return;}
                    curEvent.eventData.remove(curEvent.eventData[clEventListEvents.getSelectedIndex()]);
                }
            );
        }); tabEVENT.add(btnDelEventToNote);

        btnChangeEventFile = new UIButton(5, clEventListEvents.y + clEventListEvents.height + 5, Std.int(MENU.width) - 120, null, 'Local Event', null, null, function(){
            updateSelectedEvent(function(curEvent){curEvent.isExternal = !curEvent.isExternal;});
        }); tabEVENT.add(btnChangeEventFile);

        btnBrokeExternalEvent = new UIButton(btnChangeEventFile.x + btnChangeEventFile.width + 5, btnChangeEventFile.y, 100, null, 'Broke Ex Event', null, null, function(){
            updateSelectedEvent(function(curEvent){curEvent.isBroken = !curEvent.isBroken;});
        }); tabEVENT.add(btnBrokeExternalEvent);

        event_sett_group = new FlxUIGroup(5, btnChangeEventFile.y + btnChangeEventFile.height + 5); tabEVENT.add(event_sett_group);
        event_sett_group.width = Std.int(MENU.width - 10);

        MENU.addGroup(tabEVENT);

        //===========================================================================================================================
        
        var tabSETTINGS = new FlxUI(null, MENU);
        tabSETTINGS.name = "1Settings";

        chkHideChart = new FlxUICheckBox(25, 25, null, null, "Hide Chart", 100); tabSETTINGS.add(chkHideChart);
        chkHideStrums = new FlxUICheckBox(25, chkHideChart.y + chkHideChart.height + 5, null, null, "Hide Strums", 100); tabSETTINGS.add(chkHideStrums);

        MENU.addGroup(tabSETTINGS);

        //===========================================================================================================================
        
        MENU.scrollFactor.set();
        MENU.showTabId("5Song");

        if(song.characters.length != 3){sub_menu.kill();}
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
			var wname = check.getLabel().text;

            if(check.name.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote){
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = check.checked;
                    }, null, false
                );

                return;
            }else if(check.name.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent){
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = check.checked;
                    }, null, false
                );

                return;
            }

			switch(wname){
                case "Is Playable":{song.strums[curStrum].playable = check.checked;}
                case "\nActive HitSounds":{sHitsArray[curStrum] = check.checked;}
                case "Mute Strum Voice":{sVoicesArray[curStrum] = check.checked;}
                case "Mute Inst":{inst.volume = check.checked ? 0 : 1;}
                case "Hide Strums":{reloadChartGrid(true);} 
                case "Hide Chart":{
                    camHUD.visible = !check.checked;
                    camFHUD.alpha = !check.checked ? 1 : 0.5;
                }
				case 'Change BPM':{
                    song.sections[curSection].changeBPM = check.checked;
					FlxG.log.add('BPM Changed to: ' + check.checked);
                    updateSection();
                }
				case "\nChange Strum ALT":{
                    song.strums[curStrum].sections[curSection].changeAlt = check.checked;
                }
                case "Song has Voices?":{
                    inst.pause();
                    for(voice in voices.sounds){voice.pause();}
                    
                    song.voices = check.checked;
                    loadAudio(song.song, song.category);
                    reloadChartGrid(true);
                }
			}

            if(wname == "Mute Strum Voice" || wname == "Mute Voices"){
                for(i in 0...voices.sounds.length){voices.sounds[i].volume = !sVoicesArray[i] && !chkMuteVoices.checked ? 1 : 0;}
            }
		}else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

            if(wname.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var type:String = wname.split(":")[2];

                updateSelectedNote(
                    function(curNote){
                        switch(type){
                            case "string":{curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = input.text;}
                            case "array":{
                                var pString:String = '{ "Events": ${input.text} }';
                                var rString:Array<Dynamic> = [];
                                try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                                curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = rString;
                            }
                        }
                    }, null, false
                );

                return;
            }else if(wname.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var type:String = wname.split(":")[2];

                updateSelectedEvent(
                    function(curEvent){
                        switch(type){
                            case "string":{curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = input.text;}
                            case "array":{
                                var pString:String = '{ "Events": ${input.text} }';
                                var rString:Array<Dynamic> = [];
                                try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                                curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = rString;
                            }
                        }
                    }, null, false
                );

                return;
            }

            switch(wname){
                case "SONG_NAME":{song.song = Paths.format(input.text, true);}
                case "SONG_CATEGORY":{song.category = input.text;}
                case "SONG_DIFFICULTY":{song.difficulty = input.text;}
                case "SONG_STYLE":{song.style = input.text;}
                case "SONG_STAGE":{song.stage = input.text; updateStage();}
                case "NOTE_EVENT":{
                    if(getSwagNote(Note.convNoteData(selNote)) == null){input.color = FlxColor.GRAY; return;}

                    var pString:String = '{ "Events": ${input.text} }';
                    var rString:Array<Dynamic> = [];
                    try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                    updateSelectedNote(function(curNote){
                        if(curNote.eventData[clNoteEventList.getSelectedIndex()] == null){return;}
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1] = rString;
                    }, false);
                }
                case "EVENTS_EVENT":{
                    if(getSwagEvent(Note.convEventData(selEvent)) == null){input.color = FlxColor.GRAY; return;}
                    
                    var pString:String = '{ "Events": ${input.text} }';
                    var rString:Array<Dynamic> = [];
                    try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                    updateSelectedEvent(function(curEvent){
                        if(curEvent.eventData[clEventListEvents.getSelectedIndex()] == null){return;}
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1] = rString;
                    }, false);
                }
                case "CHAR_GF":{if(input == null || song.characters.length < 1 || song.characters[0].length < 1){return;} song.characters[0][0] = input.text; updateStage();}
                case "CHAR_OPP":{if(input == null || song.characters.length < 2 || song.characters[1].length < 1){return;} song.characters[1][0] = input.text; updateStage();}
                case "CHAR_BF":{if(input == null || song.characters.length < 3 || song.characters[2].length < 1){return;} song.characters[2][0] = input.text; updateStage();}
            }
        }else if(id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu)){
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;
            switch(wname){
                default:{}
            }
        }else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;

            if(wname.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote){
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = nums.value;
                    }, null, false
                );

                return;
            }else if(wname.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent){
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = nums.value;
                    }, null, false
                );

                return;
            }

            switch(wname){
                case "SONG_Player":{
                    if(nums.value < 0){nums.value = 0;}
                    if(nums.value >= song.strums.length){nums.value = song.strums.length - 1;}

                    song.player = Std.int(nums.value);
                }
                case "NOTE_STRUMTIME":{
                    updateSelectedNote(function(curNote){curNote.strumTime = nums.value;});
                }
                case "EVENT_STRUMTIME":{
                    updateSelectedEvent(function(curEvent){curEvent.strumTime = nums.value;});
                }
                case "NOTE_LENGTH":{
                    updateSelectedNote(function(curNote){
                        if(nums.value <= 0){curNote.multiHits = 0;}
                        curNote.sustainLength = nums.value;
                    });
                }
                case "SONG_Speed":{song.speed = nums.value;}
                case "SONG_BPM":{
                    tempBpm = nums.value;
                    
				    conductor.mapBPMChanges(song);
				    conductor.changeBPM(nums.value);
                    
                    updateSection();
                }
                case "GENERALSEC_BPM":{
                    song.sections[curSection].bpm = nums.value;
                    updateSection();
                }
                case "GENERALSEC_LENGTH":{
                    song.sections[curSection].lengthInSteps = Std.int(nums.value);
                    updateSection();
                }
                case "GENERALSEC_strum":{
                    if(nums.value < 0){nums.value = 0;}
                    if(nums.value >= song.strums.length){nums.value = song.strums.length - 1;}

                    song.sections[curSection].strum = Std.int(nums.value);
                    updateSection();
                }
                case "NOTE_HITS":{
                    updateSelectedNote(function(curNote){
                        curNote.multiHits = Std.int(nums.value);
                        if(curNote.sustainLength <= 0 && curNote.multiHits >= 0){curNote.sustainLength = conductor.stepCrochet;}
                    });
                }
                case "STRUM_KEYS":{
                    song.strums[curStrum].keys = Std.int(nums.value);
                    updateSection();
                }
                case "Strums_Length":{
                    if(nums.value < 0){nums.value = 0;}
                    if(nums.value >= song.strums.length){nums.value = song.strums.length - 1;}
                }
            }
        }else if(id == UIList.CHANGE_EVENT && (sender is UIList)){
            var nums:UIList = cast sender;
            var wname = nums.name;

            if(wname.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote){
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = nums.getSelectedLabel();
                    }, null, false
                );

                return;
            }else if(wname.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent){
                        if(curEvent.eventData == null){return;}
                        if(curEvent.eventData.length <= clEventListEvents.getSelectedIndex()){return;}
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = nums.getSelectedLabel();
                    }, null, false
                );

                return;
            }

            switch(wname){
                default:{}
            }
        }
    }

    var canAutoSave:Bool = true;
    private function autoSave():Void {
        if(!canAutoSave){trace("Auto Save Disabled!"); return;}
        FlxG.save.data.autosave = song;
		FlxG.save.flush();
        trace("Auto Saved!!!");
    }

    private function loadNoteEventSettings(?event:String):Void {
        note_event_sett_group.clear();   

        if(event == null){return;}
        
        scripts.load(event, Paths.event(event));
        var setting_list:Array<Dynamic> = scripts.get(event).getVar("defaultValues");

        var last_height:Float = 0;

        for(i in 0...setting_list.length){
            var setting:Dynamic = setting_list[i];
            var event_value:Dynamic = selNote.eventData[clNoteEventList.getSelectedIndex()][1][i];

            switch(setting.type){
                default:{
                    var chkCurrent_Variable = new FlxUICheckBox(0, last_height, null, null, setting.name);
                    chkCurrent_Variable.checked = event_value == true || event_value == "true";
                    chkCurrent_Variable.name = 'note_event_arg:${i}';
                    note_event_sett_group.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new UINumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 0.1, Std.parseFloat(event_value), -999, 999, 3);
                    stpCurrent_Variable.name = 'note_event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    note_event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'Int':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new UINumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 1, Std.parseFloat(event_value), -999, 999);
                    stpCurrent_Variable.name = 'note_event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    note_event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'String':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), Std.string(event_value), 8);
                    txtCurrent_Variable.name = 'note_event_arg:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    note_event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'Array':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var data:String = ''; try{data = Json.stringify(cast(event_value, Array<Dynamic>));}catch(e){trace(e); data = '[]';}
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), data, 8);
                    txtCurrent_Variable.name = 'note_event_arg:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    note_event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'List':{
                    var clCurrent_Variable = new UIList(0, last_height, Std.int(MENU.width) - 10, setting.list);
                    clCurrent_Variable.setPrefix('${setting.name}: ['); clCurrent_Variable.setSuffix(']');
                    clCurrent_Variable.name = 'note_event_arg:${i}';
                    clCurrent_Variable.setLabel(event_value,true);
                    note_event_sett_group.add(clCurrent_Variable); 
                    last_height += clCurrent_Variable.height + 5;
                }
            }
        }
    }

    private function loadEventSettings(?event:String):Void {
        event_sett_group.clear();   

        if(event == null){return;}
        
        scripts.load(event, Paths.event(event));
        var setting_list:Array<Dynamic> = scripts.get(event).getVar("defaultValues");

        var last_height:Float = 0;

        for(i in 0...setting_list.length){
            var setting:Dynamic = setting_list[i];
            var event_value:Dynamic = selEvent.eventData[clEventListEvents.getSelectedIndex()][1][i];

            switch(setting.type){
                default:{
                    var chkCurrent_Variable = new FlxUICheckBox(0, last_height, null, null, setting.name);
                    chkCurrent_Variable.checked = event_value == true || event_value == "true";
                    chkCurrent_Variable.name = 'event_arg:${i}';
                    event_sett_group.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new UINumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 0.1, Std.parseFloat(event_value), -999, 999, 3);
                    stpCurrent_Variable.name = 'event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'Int':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new UINumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 1, Std.parseFloat(event_value), -999, 999);
                    stpCurrent_Variable.name = 'event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'String':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var data:String = ''; try{data = Json.stringify(event_value);}catch(e){trace(e); data = '""';}
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), Std.string(event_value), 8);
                    txtCurrent_Variable.name = 'event_arg:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'Array':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var data:String = ''; try{data = Json.stringify(cast(event_value, Array<Dynamic>));}catch(e){trace(e); data = '[]';}
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), data, 8);
                    txtCurrent_Variable.name = 'event_arg:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'List':{
                    var clCurrent_Variable = new UIList(0, last_height, Std.int(MENU.width) - 10, setting.list);
                    clCurrent_Variable.setPrefix('${setting.name}: ['); clCurrent_Variable.setSuffix(']');
                    clCurrent_Variable.name = 'event_arg:${i}';
                    clCurrent_Variable.setLabel(event_value,true);
                    event_sett_group.add(clCurrent_Variable); 
                    last_height += clCurrent_Variable.height + 5;
                }
            }
        }
    }

    public static var song_file:SaverFile = null;
	public static function save_song(fileName:String, songData:Song_File, options:{?onComplete:Void->Void, ?throwFunc:Exception->Void, ?returnOnThrow:Bool, ?path:String, ?saveAs:Bool}):Void {
		if(song_file != null || songData == null){return;}
		var _song:Song_File = songData;

		Song.parse(_song);
		var _global_events:Event_File = {events: []};
		var init_events:Array<Dynamic> = _song.events.copy();

		var cur_ev:Int = 0;
		while(cur_ev < _song.events.length){
			var ev = _song.events[cur_ev];
			var ev_data:Event_Data = Note.getEventData(ev);
			if(!ev_data.isExternal){cur_ev++; continue;}
			_global_events.events.push(ev);
			if(!ev_data.isBroken){_song.events.remove(ev); cur_ev--;}
			cur_ev++;
		}

		var song_data:String = "";
		var events_data:String = "";

		try{song_data = Json.stringify({song: _song},"\t");}catch(e){trace(e); if(options.throwFunc != null){options.throwFunc(e);} if(options.returnOnThrow){return;}}
		try{events_data = Json.stringify({song: _global_events},"\t");}catch(e){trace(e); if(options.throwFunc != null){options.throwFunc(e);} if(options.returnOnThrow){return;}}

		if(options.saveAs){
			var files_to_save:Array<{name:String, data:Dynamic}> = [{name: '$fileName.json', data: song_data}];
			if(events_data.length > 0){files_to_save.push({name: 'global_events.json', data: events_data});}
			song_file = new SaverFile(files_to_save, {destroyOnComplete: true, onComplete: function(){if(options.onComplete != null){options.onComplete();} song_file = null;}});
			song_file.saveFile();
		}else{
			#if sys
				if((song_data != null) && (song_data.length > 0)){File.saveContent(options.path, song_data);}
				if((events_data != null) && (events_data.length > 0)){File.saveContent(options.path.replace('$fileName','global_events'), events_data);}
				if(options.onComplete != null){options.onComplete();}
			#end
		}

		_song.events = init_events;
	}
}