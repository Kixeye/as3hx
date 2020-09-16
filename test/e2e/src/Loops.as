package {

public class Loops {
    public function setIcon(iconOrLabel:Object):void
    {
        for(var i:int = 0; i < _numButtons; i++)
        {
            var btn:ArcButton = new ArcButton();
            btn.id = i;
            if(btn.name != null) continue;
            trace(i);
        }

        var advanceStyleClientChildren:Dictionary = new Dictionary();

        for (var styleClient:Object in advanceStyleClientChildren) {
            var iAdvanceStyleClientChild:Sprite = styleClient as Sprite;
        }
    }

    public function while_loops_postfix_decrement():void
    {
        var sum:int = 0;
        var x:int = 10;
        while (x--) {
            sum += x;
        }
    }

    public function for_loop_conversions():void
    {
        for (var i:int = 0; i <= 4; i++) {
            // Should convert to for (i in 0...5)
        }

        for (var i:int = 0; i < 4; i++) {
            // Should convert to for (i in 0...4)
        }
    }

    public function for_loop_into_while_loop_conversions():void
    {
        var arr:Array = [1, 2, 3];
        for (var i:int = 0; i < arr.length; i++) {
            // Should convert to while (i < arr.length) with i++ increment.
        }

        for (var i:int = 0; i <= arr.length; i++) {
            // Should convert to while (i <= arr.length) with i++ increment.
        }

        for (var i:int = 0; i < arr.length - 3; i += 2) {
            // Should convert to while (i < arr.length - 3) with i += 2 increment.
            trace(i);
        }

        for (var i:int = arr.length; i >= 0; i--) {
            // Should convert to while (i >= 0) with i-- decrement.
        }

        for (var i:int = arr.length; i > 0; i -= 2) {
            // Should convert to while (i > 0) with i -= 2 decrement.
        }
    }
}
}
