package substates.menus;

class YesNoSubMenu extends OptionsSubMenu {
    public function new(description:Dynamic, onYes:Void->Void, onNo:Void->Void):Void {
        super(description , [{display: "yes", method: onYes}, {display: "no", method: onNo}]);
    }
}
