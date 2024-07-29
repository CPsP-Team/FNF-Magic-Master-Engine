package states.editors;

import flixel.graphics.frames.FlxFramesCollection.FlxFrameCollectionType;
import flixel.graphics.frames.FlxAtlasFrames.TexturePackerObject;
import flixel.system.FlxAssets.FlxTexturePackerSource;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITabMenu;
import openfl.events.IOErrorEvent;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.net.FileReference;
import flixel.addons.ui.FlxUI;
import flash.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.ui.FlxButton;
import flixel.math.FlxRect;
import lime.ui.FileDialog;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import haxe.xml.Access;
import openfl.Assets;
import flixel.FlxG;
import haxe.Json;

import objects.scripts.Script;
import objects.ui.UIList;
import flixel.ui.FlxCustomButton;
import objects.ui.UIButton;
import objects.ui.UIValueChanger;
import objects.ui.UINumericStepper;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

typedef PackerData = {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var frame_x:Int;
    var frame_y:Int;
    var symbol:String;
    var frame_width:Int;
    var frame_height:Int;
}

class PackerEditorState extends MusicBeatState {
    private static var _PACKER:Array<PackerData>;
    private static var _IMG:FlxGraphic;

    var tabFILE:FlxUITabMenu;
    var tabGHOST:FlxUITabMenu;
    var tabSPRITE:FlxUITabMenu;
    
    var point:FlxSprite;
    var camPoint:FlxSprite;
    var sizePoint:FlxSprite;

    var imgIcon:FlxSprite;
    var bSprite:FlxSprite;
    var eSprite:FlxSprite;
    
    var arrayFocus:Array<FlxUIInputText> = [];

    var camFollow:FlxObject;

    override function create(){
        if(FlxG.sound.music != null){FlxG.sound.music.stop();}

        #if desktop
		// Updating Discord Rich Presence
		Discord.change('Editing', '[Packer Editor]');
		Magic.setWindowTitle('On Packer Editor', 1);
		#end

        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);

        //SPRITES
        bSprite = new FlxSprite();
        bSprite.color = FlxColor.GRAY;
        bSprite.cameras = [camFGame];
        bSprite.antialiasing = false;
        bSprite.alpha = 0.3;
        
        eSprite = new FlxSprite();
        eSprite.cameras = [camFGame];
        eSprite.antialiasing = false;

        imgIcon = new FlxSprite(5, 5);
        imgIcon.cameras = [camHUD];

        add(eSprite);
        add(bSprite);

        add(imgIcon);

        point = new FlxSprite(100, 50).makeGraphic(5, 5, FlxColor.WHITE);
        point.cameras = [camFGame];
        add(point);
        
        camPoint = new FlxSprite(0, 0).makeGraphic(5, 5, FlxColor.WHITE);
        camPoint.cameras = [camFGame];
        add(camPoint);

        sizePoint = new FlxSprite(0, 0).makeGraphic(5, 5, FlxColor.WHITE);
        sizePoint.cameras = [camFGame];
        add(sizePoint);

        tabFILE = new FlxUITabMenu(null, [{name: "Files", label: 'Files'}], true);
        tabFILE.resize(250, 130);
		tabFILE.x = FlxG.width - tabFILE.width;
        tabFILE.camera = camHUD;
        addFILETABS();
        
        tabGHOST = new FlxUITabMenu(null, [{name: "Ghost", label: 'Ghost'}], true);
        tabGHOST.resize(250, 100);
		tabGHOST.y = tabFILE.height;
		tabGHOST.x = tabFILE.x;
        tabGHOST.camera = camHUD;
        addGHOSTTABS();

        tabSPRITE = new FlxUITabMenu(null, [{name: "General", label: 'General'}], true);
        tabSPRITE.resize(250, FlxG.height - tabFILE.height - tabGHOST.height);
        tabSPRITE.y = tabGHOST.y + tabGHOST.height;
		tabSPRITE.x = tabFILE.x;
        tabSPRITE.camera = camHUD;
        addFRAMESTABS();

        add(tabFILE);
        add(tabGHOST);
        add(tabSPRITE);
        
		camFollow = new FlxObject(0, 0, 1, 1);
        camFollow.screenCenter();
        camFGame.follow(camFollow, LOCKON);
		add(camFollow); 

        super.create();
        
        FlxG.mouse.visible = true;
    }

    var pos = [[], []];
    override function update(elapsed:Float){
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);

        bSprite.setPosition(point.x, point.y);
        eSprite.setPosition(point.x, point.y);

        camPoint.setPosition(eSprite.getGraphicMidpoint().x, eSprite.getGraphicMidpoint().y);
        sizePoint.setPosition(eSprite.x + eSprite.width, eSprite.y + eSprite.height);

        var arrayControlle = true;
        for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}

        if(canControlle && arrayControlle){    
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[pMouse.x, pMouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + ((pos[1][0] - pMouse.x) * 1.0), pos[0][1] + ((pos[1][1] - pMouse.y) * 1.0));}

            if(FlxG.keys.pressed.SHIFT){
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.1);} 
                
                if(FlxG.keys.justPressed.W){vchCurHeight.change(true);}
                if(FlxG.keys.justPressed.A){vchCurWidth.change(true);}
                if(FlxG.keys.justPressed.S){vchCurHeight.change();}
                if(FlxG.keys.justPressed.D){vchCurWidth.change();}
            }else{
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.01);}

                if(FlxG.keys.justPressed.W){vchCurY.change(true);}
                if(FlxG.keys.justPressed.A){vchCurX.change(true);}
                if(FlxG.keys.justPressed.S){vchCurY.change();}
                if(FlxG.keys.justPressed.D){vchCurX.change();}
            }

            if(FlxG.mouse.justPressedMiddle){camFollow.setPosition(eSprite.getGraphicMidpoint().x, eSprite.getGraphicMidpoint().y);}
        }
        
		super.update(elapsed);
    }

    private function getFile(_file:FlxUIInputText):Void {
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str){_file.text = str;});
        fDialog.browse();
	}
    
    private function loadArchives():Void {
        if(!txtIMAGE.text.contains(".png") || !txtPACKER.text.contains(".txt")){return;}
        
        _IMG = FlxGraphic.fromBitmapData(BitmapData.fromFile(txtIMAGE.text));
        _PACKER = parseData(txtPACKER.text.getText());
    }

    private function loadGhostSprites():Void {
        if(!txtIMAGE.text.contains(".png") || !txtPACKER.text.contains(".txt")){return;}

        //bSprite.frames = Files.fromUncachedSpriteSheetPacker(BitmapData.fromFile(txtIMAGE.text), txtPACKER.text.getText());

        var animArr = getNamesArray(parseData(txtPACKER.text.getText()));
        for(anim in animArr){bSprite.animation.addByPrefix(anim, anim);}
        clGCurAnim.setData(animArr);

        stpGCurFrame.value = 0;
    }
    private function loadNormalSprites():Void {
        loadESprite();
        
        imgIcon.loadGraphic(_IMG);
        imgIcon.setGraphicSize(Std.int(15 * FlxG.height / 100), Std.int(15 * FlxG.height / 100));
        imgIcon.updateHitbox();
        
        clCurAnim.setData(getNamesArray(_PACKER));

        stpCurFrame.value = 0;
        playAnim();
    }
    private function loadESprite():Void {
        var values:Array<Dynamic> = null;
        if(eSprite != null && eSprite.animation.curAnim != null){values = [eSprite.animation.curAnim.name, eSprite.animation.curAnim.curFrame];}
        if(_PACKER != null && _IMG != null){
            //eSprite.frames = Files.fromUncachedSpriteSheetPacker(_IMG, convertData(_PACKER));
            
            var animArr = getNamesArray(_PACKER);
            for(anim in animArr){eSprite.animation.addByPrefix(anim, anim); eSprite.animation.play(anim); eSprite.animation.stop();}
            if(values != null){eSprite.animation.play(values[0], false, false, values[1]); eSprite.animation.stop();}
        }
    }

    public static function getNamesArray(arr:Array<PackerData>):Array<String> {
        var toReturn:Array<String> = [];

        for(chr in arr){
            var line_data:Array<String> = chr.symbol.split("_");
            var name:String = line_data[0];
            if(!toReturn.contains(name)){
                toReturn.push(name);
            }
        }

        return toReturn;
    }
    private function getPacker(?AnimName:String, ?Frame:Int, hasNull:Bool = false):PackerData {
        if(AnimName == null){AnimName = clCurAnim.getSelectedLabel();}
        if(Frame == null){Frame = Std.int(stpCurFrame.value);}

        var Name:String = '${AnimName}_${Frame}';

        for(data in _PACKER){if(data.symbol == Name){return data;}}

        if(hasNull){return null;}
        return {symbol: "PlaceHolder", x: 0, y: 0, width: 0, height: 0, frame_x: 0, frame_y: 0, frame_width: 0, frame_height: 0};
    }
    
    private function getMapFromDat(data:PackerData):Map<String, Dynamic> {
        var toReturn:Map<String, Dynamic> = [];

        toReturn.set("symbol", data.symbol);
        toReturn.set("x", data.x);
        toReturn.set("y", data.y);
        toReturn.set("width", data.width);
        toReturn.set("height", data.height);
        toReturn.set("frame_y", data.frame_y);
        toReturn.set("frame_y", data.frame_y);
        toReturn.set("frame_width", data.frame_width);
        toReturn.set("frame_height", data.frame_height);

        return toReturn;
    }
    private function setDataFromMap(data:PackerData, map:Map<String, Dynamic>):Void {
        data.symbol = map.get("symbol");
        data.x = map.get("x");
        data.y = map.get("y");
        data.width = map.get("width");
        data.height = map.get("height");
        data.frame_x = map.get("frame_x");
        data.frame_y = map.get("frame_y");
        data.frame_width = map.get("frame_width");
        data.frame_height = map.get("frame_height");
    }

    private function editAttribute(attribute:String, value:Int, force:Bool = false):Void {
        if(eSprite == null || eSprite.animation.curAnim == null){return;}
        
        if(chkSetToAllSprite.checked){
            for(e in _PACKER){
                var eMap:Map<String, Dynamic> = getMapFromDat(e);

                if(force){
                    eMap.set(attribute, Std.string(value));
                }else{
                    eMap.set(attribute, Std.string(Std.parseInt(eMap.get(attribute)) - value));
                }

                setDataFromMap(e, eMap);
            }
            loadESprite(); playAnim();
            return;
        }

        if(chkSetToAllFrames.checked){
            for(i in 0...eSprite.animation.curAnim.frames.length){
                var eMap:Map<String, Dynamic> = getMapFromDat(getPacker(null, i));

                if(force){
                    eMap.set(attribute, Std.string(value));
                }else{
                    eMap.set(attribute, Std.string(Std.parseInt(eMap.get(attribute)) - value));
                }

                setDataFromMap(getPacker(null, i), eMap);
            }
            loadESprite(); playAnim();
            return;
        }
        
        var eMap:Map<String, Dynamic> = getMapFromDat(getPacker());
        if(force){
            eMap.set(attribute, Std.string(value));
        }else{
            eMap.set(attribute, Std.string(Std.parseInt(eMap.get(attribute)) - value));
        }

        setDataFromMap(getPacker(), eMap);

        loadESprite(); playAnim();
    }

    public function playAnim(?AnimName:String, ?Frame:Int):Void{
        if(eSprite == null || eSprite.animation.curAnim == null){return;}
        
        if(AnimName == null){AnimName = eSprite.animation.curAnim.name;}
        if(Frame == null){Frame = eSprite.animation.curAnim.curFrame;}

        eSprite.animation.play(AnimName, true, false, Frame);
        eSprite.animation.stop();

        eSprite.updateHitbox();

        var sTexture:PackerData = getPacker(AnimName, Frame);
        lblCurX.text = 'X: [${sTexture.x}]';
        lblCurY.text = 'Y: [${sTexture.y}]';
        lblCurWidth.text = 'Width: [${sTexture.width}]';
        lblCurHeight.text = 'Height: [${sTexture.height}]';
    }
    public function playGhost(AnimName:String, Frame:Int):Void{
        bSprite.animation.play(AnimName, true, false, Frame);
        bSprite.animation.stop();
    }

    private function convertData(_data:Array<PackerData>):String {
        var toReturn:String = "";

        for(line in _data){toReturn += '${line.symbol}:${line.x},${line.y},${line.width},${line.height}:${line.frame_x},${line.frame_y},${line.frame_width},${line.frame_height}\n';}

        return toReturn;
    }
    private function parseData(_data:String):Array<PackerData> {
        var toReturn:Array<PackerData> = [];

		var pack = StringTools.trim(_data);
		var lines:Array<String> = pack.split("\n");

        for(i in 0...lines.length){
			var currImageData = lines[i].split(":");
			var name = StringTools.trim(currImageData[0]);
			var currImageRegion = StringTools.trim(currImageData[1]).split(",");
			var currRectRegion = StringTools.trim(currImageData[2]).split(",");

            toReturn.push(
                {
                    symbol: name,
                    x: Std.parseInt(currImageRegion[0]),
                    y: Std.parseInt(currImageRegion[1]),
                    width: Std.parseInt(currImageRegion[2]),
                    height: Std.parseInt(currImageRegion[3]),
                    frame_x: Std.parseInt(currRectRegion[0]),
                    frame_y: Std.parseInt(currRectRegion[1]),
                    frame_width: Std.parseInt(currRectRegion[2]),
                    frame_height: Std.parseInt(currRectRegion[3])
                }
            );
		}

        return toReturn;
    }

    var _file:FileReference;
    private function save(){
		var data:String = convertData(_PACKER);

		if((data != null) && (data.length > 0)){
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "newPacker.txt");
		}
	}

	function onSaveComplete(_):Void{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

    var txtIMAGE:FlxUIInputText;
    var txtPACKER:FlxUIInputText;
    function addFILETABS():Void{
        var uiFile = new FlxUI(null, tabFILE);
        uiFile.name = "Files";

        var lblIMAGE = new FlxText(5, 5, 0, "IMAGE (File):", 8); uiFile.add(lblIMAGE);
        txtIMAGE = new FlxUIInputText(lblIMAGE.x + lblIMAGE.width + 5, lblIMAGE.y, Std.int(tabFILE.width - lblIMAGE.width - 50), "", 8); uiFile.add(txtIMAGE);
        txtIMAGE.name = "FILE_IMAGE";
        var btnImage:FlxButton = new FlxCustomButton(txtIMAGE.x + txtIMAGE.width + 5, txtIMAGE.y - 3, 30, null, "GET", null, null, function(){getFile(txtIMAGE);}); uiFile.add(btnImage);

        var lblPACKER = new FlxText(lblIMAGE.x, lblIMAGE.y + txtIMAGE.height + 10, 0, "TXT (File):", 8); uiFile.add(lblPACKER);
        txtPACKER = new FlxUIInputText(lblPACKER.x + lblPACKER.width + 5, lblPACKER.y, Std.int(tabFILE.width - lblPACKER.width - 50), "", 8); uiFile.add(txtPACKER);
        txtPACKER.name = "FILE_PACKER";        
        var btnPACKER:FlxButton = new FlxCustomButton(txtPACKER.x + txtPACKER.width + 5, txtPACKER.y - 3, 30, null, "GET", null, null, function(){getFile(txtPACKER);}); uiFile.add(btnPACKER);

        var btnImport:FlxButton = new FlxCustomButton(lblPACKER.x, btnPACKER.y + btnPACKER.height + 5, Std.int(tabFILE.width / 2) - 7, null, "IMPORT", null, null, function(){loadArchives(); loadNormalSprites();}); uiFile.add(btnImport);
        var btnGhostImport:FlxButton = new FlxCustomButton(btnImport.x + btnImport.width + 5, btnImport.y, Std.int(tabFILE.width / 2) - 7, null, "IMPORT GHOST", null, null, function(){loadGhostSprites();}); uiFile.add(btnGhostImport);

        var btnSave:FlxButton = new FlxCustomButton(5, btnGhostImport.y + btnGhostImport.height + 7, Std.int(tabFILE.width) - 10, null, "Save TXT", null, null, function(){save();}); uiFile.add(btnSave);

        tabFILE.addGroup(uiFile);
        tabFILE.scrollFactor.set();
        tabFILE.showTabId("Files");
    }

    var clGCurAnim:UIList;
    var stpGCurFrame:FlxUINumericStepper = new FlxUINumericStepper();
    var chkGFlipX:FlxUICheckBox;
    var chkGFlipY:FlxUICheckBox;
    function addGHOSTTABS():Void {
        var uiGhost = new FlxUI(null, tabGHOST);
        uiGhost.name = "Ghost";

        clGCurAnim = new UIList(5, 5, Std.int(tabGHOST.width - 10), [], function(){
            stpGCurFrame.value = 0;
            playGhost(clGCurAnim.getSelectedLabel(), Std.int(stpGCurFrame.value));
        }); uiGhost.add(clGCurAnim);

        var lblbGCurFrame = new FlxText(clGCurAnim.x, clGCurAnim.y + clGCurAnim.height + 7, 0, "[Current Frame]: ", 8); uiGhost.add(lblbGCurFrame);
        stpGCurFrame = new UINumericStepper(lblbGCurFrame.x + lblbGCurFrame.width, lblbGCurFrame.y, Std.int(tabGHOST.width - lblbGCurFrame.width) - 10, 1, 0, 0, 999); uiGhost.add(stpGCurFrame);
        stpGCurFrame.name = "GHOST_INDEX";

        chkGFlipX = new FlxUICheckBox(5, lblbGCurFrame.y + lblbGCurFrame.height + 7, null, null, "FlipX Ghost Image"); uiGhost.add(chkGFlipX);
        chkGFlipY = new FlxUICheckBox(chkGFlipX.x + chkGFlipX.width + 5, chkGFlipX.y, null, null, "FlipY Ghost Image"); uiGhost.add(chkGFlipY);

        tabGHOST.addGroup(uiGhost);
        tabGHOST.scrollFactor.set();
        tabGHOST.showTabId("Ghost");
    }

    var clCurAnim:UIList;
    var stpCurFrame:FlxUINumericStepper = new FlxUINumericStepper();
    var chkFlipX:FlxUICheckBox;
    var chkFlipY:FlxUICheckBox;
    var chkSetToAllFrames:FlxUICheckBox;
    var chkSetToAllSprite:FlxUICheckBox;
    var lblCurX:FlxText;
    var vchCurX:UIValueChanger;
    var lblCurY:FlxText;
    var vchCurY:UIValueChanger;
    var lblCurWidth:FlxText;
    var vchCurWidth:UIValueChanger;
    var lblCurHeight:FlxText;
    var vchCurHeight:UIValueChanger;
    var lblCurFrameX:FlxText;
    var vchCurFrameX:UIValueChanger;
    var lblCurFrameY:FlxText;
    var vchCurFrameY:UIValueChanger;
    var lblCurFrameWidth:FlxText;
    var vchCurFrameWidth:UIValueChanger;
    var lblCurFrameHeight:FlxText;
    var vchCurFrameHeight:UIValueChanger;
    private function addFRAMESTABS():Void{
        var uiBase = new FlxUI(null, tabSPRITE);
        uiBase.name = "General";

        clCurAnim = new UIList(5, 5, Std.int(tabSPRITE.width - 10), [], function(){
            stpCurFrame.value = 0;
            playAnim(clCurAnim.getSelectedLabel(), Std.int(stpCurFrame.value));
        }); uiBase.add(clCurAnim);
        clCurAnim.name = "BASE_CHANGE";

        var lblbCurFrame = new FlxText(clCurAnim.x, clCurAnim.y + clCurAnim.height + 7, 0, "[Current Frame]: ", 8); uiBase.add(lblbCurFrame);
        stpCurFrame = new UINumericStepper(lblbCurFrame.x + lblbCurFrame.width, lblbCurFrame.y, Std.int(tabSPRITE.width - lblbCurFrame.width) - 10, 1, 0, 0, 999); uiBase.add(stpCurFrame);
        stpCurFrame.name = "FRAME_INDEX";

        chkFlipX = new FlxUICheckBox(5, lblbCurFrame.y + lblbCurFrame.height + 5, null, null, "FlipX Image"); uiBase.add(chkFlipX);
        chkFlipY = new FlxUICheckBox(chkFlipX.x + chkFlipX.width + 5, chkFlipX.y, null, null, "FlipY Image"); uiBase.add(chkFlipY);

        chkSetToAllFrames = new FlxUICheckBox(chkFlipX.x, chkFlipX.y + chkFlipX.height + 10, null, null, "Change on All Frames", Std.int(tabSPRITE.width) - 10); uiBase.add(chkSetToAllFrames);
        chkSetToAllSprite = new FlxUICheckBox(chkSetToAllFrames.x, chkSetToAllFrames.y + chkSetToAllFrames.height + 10, null, null, "Change on All Sprite", Std.int(tabSPRITE.width) - 10); uiBase.add(chkSetToAllSprite);

        lblCurX = new FlxText(chkSetToAllSprite.x, chkSetToAllSprite.y + chkSetToAllSprite.height + 7, 0, "X: [0]"); uiBase.add(lblCurX);
        vchCurX = new UIValueChanger(tabSPRITE.width - 105, lblCurX.y - 1, 100, function(value:Float){}); uiBase.add(vchCurX); vchCurX.name = "SPRITE_X";
        lblCurY = new FlxText(lblCurX.x, lblCurX.y + lblCurX.height + 3, 0, "Y: [0]"); uiBase.add(lblCurY);
        vchCurY = new UIValueChanger(tabSPRITE.width - 105, lblCurY.y - 1, 100, function(value:Float){}); uiBase.add(vchCurY); vchCurY.name = "SPRITE_Y";
        
        lblCurWidth = new FlxText(lblCurY.x, lblCurY.y + lblCurY.height + 7, 0, "Width: [0]"); uiBase.add(lblCurWidth);
        vchCurWidth = new UIValueChanger(tabSPRITE.width - 105, lblCurWidth.y - 1, 100, function(value:Float){}); uiBase.add(vchCurWidth); vchCurWidth.name = "SPRITE_WIDTH";
        lblCurHeight = new FlxText(lblCurWidth.x, lblCurWidth.y + lblCurWidth.height + 3, 0, "Height: [0]"); uiBase.add(lblCurHeight);
        vchCurHeight = new UIValueChanger(tabSPRITE.width - 105, lblCurHeight.y - 1, 100, function(value:Float){}); uiBase.add(vchCurHeight); vchCurHeight.name = "SPRITE_HEIGHT";
        
        lblCurFrameX = new FlxText(lblCurHeight.x, lblCurHeight.y + lblCurHeight.height + 7, 0, "Frame X: [0]"); uiBase.add(lblCurFrameX);
        vchCurFrameX = new UIValueChanger(tabSPRITE.width - 105, lblCurFrameX.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameX); vchCurFrameX.name = "SPRITE_FRAME_X";
        lblCurFrameY = new FlxText(lblCurFrameX.x, lblCurFrameX.y + lblCurFrameX.height + 3, 0, "Frame Y: [0]"); uiBase.add(lblCurFrameY);
        vchCurFrameY = new UIValueChanger(tabSPRITE.width - 105, lblCurFrameY.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameY); vchCurFrameY.name = "SPRITE_FRAME_Y";
        
        lblCurFrameWidth = new FlxText(lblCurFrameY.x, lblCurFrameY.y + lblCurFrameY.height + 7, 0, "Frame Width: [0]"); uiBase.add(lblCurFrameWidth);
        vchCurFrameWidth = new UIValueChanger(tabSPRITE.width - 105, lblCurFrameWidth.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameWidth); vchCurFrameWidth.name = "SPRITE_FRAME_WIDTH";
        lblCurFrameHeight = new FlxText(lblCurFrameWidth.x, lblCurFrameWidth.y + lblCurFrameWidth.height + 3, 0, "Frame Height: [0]"); uiBase.add(lblCurFrameHeight);
        vchCurFrameHeight = new UIValueChanger(tabSPRITE.width - 105, lblCurFrameHeight.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameHeight); vchCurFrameHeight.name = "SPRITE_FRAME_HEIGHT";
        
        tabSPRITE.addGroup(uiBase);
        tabSPRITE.scrollFactor.set();
        tabSPRITE.showTabId("General");
    }
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if((sender is FlxUICheckBox)){
            var check:FlxUICheckBox = cast sender;
            var label = check.getLabel().text;

            switch(id){
                case FlxUICheckBox.CLICK_EVENT:{
                    switch(label){
                        default:{trace("[FlxUICheckBox]: Works!");}
                        case "FlipX Ghost Image":{bSprite.flipX = check.checked;}
                        case "FlipY Ghost Image":{bSprite.flipY = check.checked;}
                        case "FlipX Image":{eSprite.flipX = check.checked;}
                        case "FlipY Image":{eSprite.flipY = check.checked;}
                    }
                }
            }
        }else if((sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

            switch(id){
                case FlxUIInputText.CHANGE_EVENT:{
                    switch(wname){
                        default:{trace("[FlxUIInputText]: Works!");}
                    }
                }
            }
        }else if((sender is FlxUIDropDownMenu)){
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;

            switch(id){
                case FlxUIDropDownMenu.CLICK_EVENT:{
                    switch(wname){
                        default:{trace("[FlxUIDropDownMenu]: Works!");}
                    }
                }
            }
        }else if((sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
            var wname = nums.name;

            switch(id){
                case FlxUINumericStepper.CHANGE_EVENT:{
                    switch(wname){
                        default:{trace("[FlxUINumericStepper]: Works!");}
                        case "FRAME_INDEX":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}

                            if(Std.int(nums.value) < 0){nums.value = eSprite.animation.curAnim.frames.length - 1;}
                            if(Std.int(nums.value) >= eSprite.animation.curAnim.frames.length){nums.value = 0;}

                            playAnim(clCurAnim.getSelectedLabel(), Std.int(nums.value));
                        }
                        case "GHOST_INDEX":{
                            if(bSprite == null || bSprite.animation.curAnim == null){return;}

                            if(Std.int(nums.value) < 0){nums.value = bSprite.animation.curAnim.frames.length - 1;}
                            if(Std.int(nums.value) >= bSprite.animation.curAnim.frames.length){nums.value = 0;}

                            playGhost(clGCurAnim.getSelectedLabel(), Std.int(nums.value));
                        }
                    }
                }
            }        
        }else if((sender is UIValueChanger)){
            var nums:UIValueChanger = cast sender;
            var wname = nums.name;

            var chValue:Int = Std.int(nums.value);
            if(data){chValue = -Std.int(nums.value);}
                
            switch(id){
                case UIValueChanger.CHANGE_EVENT:{
                    switch(wname){
                        case "SPRITE_X":{editAttribute("x", chValue);}
                        case "SPRITE_Y":{editAttribute("y", chValue);}
                        case "SPRITE_WIDTH":{editAttribute("width", chValue);}
                        case "SPRITE_HEIGHT":{editAttribute("height", chValue);}
                        case "SPRITE_FRAME_X":{editAttribute("frame_x", chValue);}
                        case "SPRITE_FRAME_Y":{editAttribute("frame_y", chValue);}
                        case "SPRITE_FRAME_WIDTH":{editAttribute("frame_width", chValue);}
                        case "SPRITE_FRAME_HEIGHT":{editAttribute("frame_height", chValue);}
                    }
                }
            }
        }else if((sender is UIList)){
            var nums:UIList = cast sender;
            var wname = nums.name;
            
            switch(id){
                case UIList.CHANGE_EVENT:{
                    switch(wname){
                        default:{}
                    }
                }
            }
        }
    }
}