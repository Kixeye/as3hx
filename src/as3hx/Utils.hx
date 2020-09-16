package as3hx;

import sys.FileSystem;
using StringTools;

class Utils {

    public static function errorString(e : Error) {
        return switch(e) {
            case EInvalidChar(c): "Invalid char '" + String.fromCharCode(c) + "' 0x" + StringTools.hex(c, 2);
            case EUnexpected(src): "Unexpected " + src;
            case EUnterminatedString: "Unterminated string";
            case EUnterminatedComment: "Unterminated comment";
            case EUnterminatedXML: "Unterminated XML";
        }
    }

    public static function round(number:Float, ?precision=2): Float
    {
        number *= Math.pow(10, precision);
        return Math.round(number) / Math.pow(10, precision);
    }

    public static function isExcludeFile(excludes: List<String>, file: String)
        return Lambda.filter(excludes, function (path) return Config.toPath(file).indexOf(path.replace(".", "/")) > -1).length > 0;

    public static function ensureDirectoryExists(dir : String) {
        var tocreate = [];
        while (!FileSystem.exists(dir) && dir != '')
        {
            var parts = dir.split("/");
            tocreate.unshift(parts.pop());
            dir = parts.join("/");
        }
        for (part in tocreate)
        {
            if (part == '')
                continue;
            dir += "/" + part;
            try {
                FileSystem.createDirectory(dir);
            } catch (e : Dynamic) {
                Sys.println("unable to create dir: " + dir);
                //throw "unable to create dir: " + dir;
            }
        }
    }

    static var reabs = ~/^([a-z]:|\\\\|\/)/i;
    public static function directory(dir : String, alt = ".") {
        if (dir == null)
            dir = alt;
        if(dir.endsWith("/") || dir.endsWith("\\"))
            dir = dir.substr(0, -1);
        if(!reabs.match(dir))
            dir = Sys.getCwd() + dir;
        dir = StringTools.replace(dir, "\\", "/");
        return dir;
    }
}


