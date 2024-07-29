package utils.native;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
	<lib name="gdi32.lib" if="windows" />
</target>
')

@:cppFileCode('
#include <iostream>
#include <Windows.h>
#include <dwmapi.h>
#include <winuser.h>
#include <wingdi.h>
')
#end

@:dox(hide)
class Windows {
	public static var title:String;

	@:functionCode('
		HWND window = FindWindowA(NULL, _title.c_str());
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, _title.c_str());
		if (window == NULL) { return; }

		HICON icon = (HICON) LoadImage(NULL, _icon.c_str(), IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE | LR_SHARED);
		if (icon == NULL) { return; }

		SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM) icon);
		SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM) icon);
	')
	private static function _setIcon(_title:String, _icon:String):Void {}
	public static function setIcon(_icon:String):Void { _setIcon(title, _icon); }
	public static function resetIcon() { _setIcon(title, "assets/images/icon.ico"); }

	@:functionCode('
		int darkMode = _enable ? 1 : 0;

		HWND window = FindWindowA(NULL, _title.c_str());
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, _title.c_str());
		if (window == NULL) { return; }

		DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, &darkMode, sizeof(darkMode));
	')
	private static function _setDarkMode(_title:String, _enable:Bool) {}
	public static function setDarkMode(_enable:Bool) { _setDarkMode(title, _enable); }
	
	@:functionCode('
		HWND window = FindWindowA(NULL, _title.c_str());
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, _title.c_str());
		if (window == NULL) { return; }
		
		COLORREF colour = _color;

		DwmSetWindowAttribute(window, DWMWA_BORDER_COLOR, &colour, sizeof(colour));
		DwmSetWindowAttribute(window, DWMWA_CAPTION_COLOR, &colour, sizeof(colour));
	')
	private static function _setBorderColor(_title:String, _color:Int) {}
	public static function setBorderColor(_color:Int) { _setBorderColor(title, _color); }
	public static function resetBorderColor() { _setBorderColor(title, 0x00FFFFFF); }
}