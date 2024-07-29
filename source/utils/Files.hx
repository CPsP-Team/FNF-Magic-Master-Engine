package utils;

import objects.notes.StrumLine.StrumLine_Graphic_Data;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.display3D.textures.RectangleTexture;
import objects.notes.StrumNote.Note_Graphic_Data;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetManifest;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetLibrary;
import openfl.display.BitmapData;
import flixel.system.FlxAssets;
import openfl.utils.AssetType;
import haxe.format.JsonParser;
import flixel.math.FlxPoint;
import openfl.system.System;
import flash.geom.Rectangle;
import openfl.utils.Assets;
import flixel.math.FlxRect;
import objects.notes.Note;
import flash.media.Sound;
import haxe.xml.Access;
import haxe.io.Bytes;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Files {
	public static var savedTempMap:Map<String, {asset_type:AssetType, asset:Dynamic}> = new Map<String, {asset_type:AssetType, asset:Dynamic}>();
	public static var savedGraphicMap:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var savedSoundMap:Map<String, Sound> = new Map<String, Sound>();
	public static var usedAssets:Array<String> = [];

	public static function clearUnusedAssets() {
		for(key in savedGraphicMap.keys()){
			if(usedAssets.contains(key)){continue;}

			var cur_asset = savedGraphicMap.get(key);
			if(cur_asset == null){continue;}

			@:privateAccess openfl.Assets.cache.removeBitmapData(key);
			@:privateAccess FlxG.bitmap._cache.remove(key);
			
			if(Reflect.hasField(cur_asset, 'destroy')){cur_asset.destroy();}
			savedGraphicMap.remove(key);
		}

		for(key in savedSoundMap.keys()){
			if(usedAssets.contains(key)){continue;}

			var cur_asset = savedSoundMap.get(key);
			if(cur_asset == null){continue;}

			@:privateAccess
				openfl.Assets.cache.removeSound(key);
			
			savedSoundMap.remove(key);
		}

		for(key in savedTempMap.keys()){
			if(usedAssets.contains(key)){continue;}

			var cur_asset = savedTempMap.get(key);
			if(cur_asset == null){continue;}

			@:privateAccess
				switch(cur_asset.asset_type){
					default:{}
					case FONT:{openfl.Assets.cache.removeFont(key);}
				}
			
			if(Reflect.hasField(cur_asset.asset, 'destroy')){cur_asset.asset.destroy();}
			savedTempMap.remove(key);
		}

		System.gc();
	}
	public static function clearMemoryAssets():Void {
		@:privateAccess
			for(key in FlxG.bitmap._cache.keys()){
				var cur_asset = FlxG.bitmap._cache.get(key);
				if(cur_asset == null || (savedGraphicMap.exists(key) && !Settings.get("UseGpu"))) {continue;}
				//trace('Clearing $key');
				
				savedGraphicMap.remove(key);
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				cur_asset.destroy();
			}

			for (key in savedSoundMap.keys()) {
				var cur_saved = savedSoundMap.get(key);
				if(cur_saved == null || usedAssets.contains(key)){continue;}

				openfl.Assets.cache.clear(key);
				savedSoundMap.remove(key);
			}

			for (key in savedTempMap.keys()) {
				var cur_saved = savedTempMap.get(key);
				if(cur_saved == null || usedAssets.contains(key)){continue;}

				savedTempMap.remove(key);
				if(Reflect.hasField(cur_saved.asset, 'destroy')){cur_saved.asset.destroy();}
			}

		usedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function isSaved(file:String, ?asset_type:AssetType):Bool {
		switch(asset_type){
			default:{return savedTempMap.exists(file);}
			case IMAGE:{return savedGraphicMap.exists(file);}
			case SOUND, MUSIC:{return savedSoundMap.exists(file);}
		}
		return false;
	}
	public static function getSavedFile(file:String, ?asset_type:AssetType):Any {
		switch(asset_type){
			default:{if(savedTempMap.exists(file)){return savedTempMap.get(file).asset;}}
			case IMAGE:{if(savedGraphicMap.exists(file)){return savedGraphicMap.get(file);}}
			case SOUND, MUSIC:{if(savedSoundMap.exists(file)){return savedSoundMap.get(file);}}
		}
		return null;
	}
	inline static public function saveFile(file:String, instance:Any, ?asset_type:AssetType):Void {
		usedAssets.push(file);
		switch(asset_type){
			default:{savedTempMap.set(file, {asset_type: asset_type, asset: instance});}
			case IMAGE:{savedGraphicMap.set(file, instance);}
			case SOUND, MUSIC:{savedSoundMap.set(file, instance);}
		}
		
		//trace('Saved $file');
	}
	inline static public function unsaveFile(file:String, ?asset_type:AssetType):Void {
		switch(asset_type){
			default:{
				var asset = savedTempMap.get(file);
				if(asset == null){return;}
				savedTempMap.remove(file);
				if(Reflect.hasField(asset.asset, 'destroy')){asset.asset.destroy();}
			}
			case IMAGE:{
				var asset = savedGraphicMap.get(file);
				if(asset == null){return;}
				savedGraphicMap.remove(file);
				asset.destroy();
			}
			case SOUND, MUSIC:{
				var asset = savedSoundMap.get(file);
				if(asset == null){return;}
				savedSoundMap.remove(file);
			}
		}
	}

	inline public static function getSound(file:String):Sound {
		if(isSaved(file, SOUND)){return getSavedFile(file, SOUND);}
		if(!Paths.exists(file)){return null;}
		saveFile(file, OpenFlAssets.exists(file) ? OpenFlAssets.getSound(file) : Sound.fromFile(file), SOUND);
		return getSavedFile(file, SOUND);
	}

	inline public static function getBytes(file:String):Any {
		if(isSaved(file, BINARY)){return getSavedFile(file, BINARY);}
		if(!Paths.exists(file)){return null;}
		#if sys
		saveFile(file, OpenFlAssets.exists(file) ? OpenFlAssets.getBytes(file) : File.getBytes(file), BINARY);
		#else
		saveFile(file, OpenFlAssets.getBytes(file), BINARY);
		#end
		return getSavedFile(file, BINARY);
	}
	public static function getGraphic(file:String, forceCPU:Bool = false):Any {
		if(isSaved(file, IMAGE)){return getSavedFile(file, IMAGE);}
		if(!Paths.exists(file)){return null;}
		
		var bitmap:BitmapData = OpenFlAssets.exists(file) ? OpenFlAssets.getBitmapData(file) : BitmapData.fromFile(file);

		if (Settings.get("UseGpu") && !forceCPU) {
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = BitmapData.fromTexture(texture);
		}

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		graphic.destroyOnNoUse = false;
		graphic.persist = true;
		saveFile(file, graphic, IMAGE);
		return getSavedFile(file, IMAGE);
	}
	inline public static function getText(file:String):String {
		if(isSaved(file, TEXT)){return getSavedFile(file, TEXT);}
		if(!Paths.exists(file)){trace('$file no exist'); return null;}

		#if sys
		saveFile(file, OpenFlAssets.exists(file) ? OpenFlAssets.getText(file) : File.getContent(file), TEXT);
		#else
		saveFile(file, OpenFlAssets.getText(file), TEXT);
		#end
		return getSavedFile(file, TEXT);
	}

	inline static public function getSparrowAtlas(path:String):FlxAtlasFrames {
		path = path.replace(".png", "").replace('.xml', '');

		var bit = getGraphic('$path.png');
		var xml = getText('$path.xml');

		if(bit == null || xml == null){return null;}
		return FlxAtlasFrames.fromSparrow(bit, xml);
	}

	inline static public function getPackerAtlas(path:String):FlxAtlasFrames {
		path = path.replace(".png", "").replace('.txt', '');

		var bit = getGraphic('$path.png');
		var txt = getText('$path.txt');

		if(bit == null || txt == null){return null;}
		return FlxAtlasFrames.fromSpriteSheetPacker(bit, txt);
	}

	static public function getAtlas(path:String):FlxAtlasFrames {
		path = path.replace(".png", "").replace(".xml", "").replace(".txt", "");

		if(Paths.exists('${path}.xml')){return getSparrowAtlas('$path.xml');}
		else if(Paths.exists('${path}.txt')){return getPackerAtlas('$path.txt');}
		return null;
	}
	
	inline static public function getJson(path:String):Dynamic {
		var text = getText(path);
		if(text == null){return null;}
		return Json.parse(text.trim());
	}

	inline static public function getColorNote(key:String):String {
		var fileName:String = key.split("/").pop();
		var note_path:String = key.replace(fileName, "colors.json");
		if(!Paths.exists(note_path)){return "None";}
		var colorData:Dynamic = Files.getJson(note_path);
		return Reflect.hasField(colorData, fileName) ? Reflect.getProperty(colorData, fileName) : "None";
	}
	inline static public function getDataNote(data:Int, keys:Int, ?type:String):Note_Graphic_Data {
		if(type == null){type = Settings.get("NoteSkin");}
		var j_strum:StrumLine_Graphic_Data = getJson(Paths.strum_keys(keys, type));
		var j_note:Note_Graphic_Data = j_strum.gameplay_notes.notes[(data % (keys)) % (j_strum.gameplay_notes.notes.length)];
		if(j_strum.gameplay_notes.general_animations == null || j_strum.gameplay_notes.general_animations.length <= 0){return j_note;}
		for(anim in j_strum.gameplay_notes.general_animations){j_note.animations.push(anim);}
		return j_note;
	}
	inline static public function getDataStaticNote(data:Int, keys:Int, ?type:String):Note_Graphic_Data {
		if(type == null){type = Settings.get("NoteSkin");}
		var j_strum:StrumLine_Graphic_Data = getJson(Paths.strum_keys(keys, type));
		var j_note:Note_Graphic_Data = j_strum.static_notes.notes[(data % (keys)) % (j_strum.static_notes.notes.length)];
		if(j_strum == null || j_strum.gameplay_notes == null || j_strum.static_notes.general_animations == null || j_strum.static_notes.general_animations.length <= 0){return j_note;}
		for(anim in j_strum.static_notes.general_animations){j_note.animations.push(anim);}
		return j_note;
	}

	public static function getXMLAnimations(path:String):Array<String> {
		if(!Paths.exists(path)){return [];}
		var toReturn:Array<String> = [];

		var data:Access = new Access(Xml.parse(Files.getText(path)).firstElement());
		for (texture in data.nodes.SubTexture){
			if(!texture.has.name){continue;}
			var _name = texture.att.name.substr(0, texture.att.name.length - 4);
			if(toReturn.contains(_name)){continue;}
			toReturn.push(_name);
		}

		return toReturn;
	}
}