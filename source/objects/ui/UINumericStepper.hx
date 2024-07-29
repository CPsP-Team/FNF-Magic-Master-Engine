package objects.ui;

import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITypedButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;

using utils.Files;
using StringTools;

class UINumericStepper extends FlxUINumericStepper {
    public function new(X:Float = 0, Y:Float = 0, Width:Int = 25, Size:Int = 8, StepSize:Float = 1, DefaultValue:Float = 0, Min:Float = -999, Max:Float = 999, Decimals:Int = 0, Stack:Int = FlxUINumericStepper.STACK_HORIZONTAL, ?TextField:FlxText, ?ButtonPlus:FlxUITypedButton<FlxSprite>, ?ButtonMinus:FlxUITypedButton<FlxSprite>, IsPercent:Bool = false):Void {
        super(X, Y, StepSize, DefaultValue, Min, Max, Decimals, Stack, TextField, ButtonPlus, ButtonMinus, IsPercent);
        //text_field.setFormat(FlxAssets.FONT_DEFAULT, Size, FlxColor.BLACK);
    }

    public function change(minus:Bool = false):Void { (minus ? _onMinus : _onPlus)(); }
}