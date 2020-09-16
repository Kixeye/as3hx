import as3hx.GlobalContext;
import as3hx.Config;
import as3hx.Utils;

typedef Stat = {
    var info:String;
    var time:Float;
}

class Run {

    static var stats:Array<Stat> = [];

    public static function measure(func:Void->String):Float {
        var start = Sys.time();
        var info = func();
        var elapsed = Sys.time() - start;

        stats.push({ info: info, time: elapsed });

        return elapsed;
    }

    static function formatTime(t:Float):String {
        return Utils.round(t, 2) + " seconds.";
    }

    public static function main() {
        var context = new GlobalContext(new Config());
        measure(context.parse);
        measure(context.process);
        measure(context.write);

        Sys.println("");
        var total = 0.0;
        for (stat in stats) {
            Sys.println(stat.info + " in " + formatTime(stat.time));
            total += stat.time;
        }
        Sys.println("Total time: " + formatTime(total));
    }
}
