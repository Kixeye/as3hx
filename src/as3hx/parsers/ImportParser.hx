package as3hx.parsers;

class ImportParser {

    static var doNotImport = [
        "clearInterval",
        "clearTimeout",
        "describeType",
        "escapeMultiByte",
        "getDefinitionByName",
        "getTimer",
        "setInterval",
        "setTimeout",
        "unescapeMultiByte",
        "navigateToURL"
    ];

    public static function parse(tokenizer:Tokenizer, cfg:Config) {
        Debug.dbg("parseImport()", tokenizer.line);
        var a = [tokenizer.id()];
        while(true) {
            var tk = tokenizer.token();
            switch(tk) {
                case TDot:
                    tk = tokenizer.token();
                    switch(tk) {
                        case TId(id):
                            if (Lambda.has(doNotImport, id)) return [];
                            // TODO: this is flash.utils.Proxy need to create a compat class
                            // http://blog.int3ractive.com/2010/05/using-flash-proxy-class.html
                            if (id == "flash_proxy") return ["flash","utils","Proxy"];
                            // import __AS3__.vec.Vector;
                            if (id == "Vector" && a[0] == "__AS3__") return [];
                            if (id == "getQualifiedClassName") return ["openfl", "Lib"];
                            if (id == "getQualifiedSuperclassName") return ["openfl", "Lib"];
                            // import flash.utils.Dictionary;
                            if (id == "Dictionary" && a.length == 2 && a[0] == "flash" && a[1] == "utils") {
                                if (cfg.openflDictionary) return ["openfl", "utils", "Dictionary"];
                                if (cfg.dictionaryToHash) return [];
                            }
                            if (id == "MD5" && a[0] == "com" && a[1] == "adobe" && a[2] == "crypto")
                            {
                                return ["haxe", "crypto", "Md5"];
                            }
                            if (id == "Rndm" && a[0] == "com" && a[1] == "gskinner" && a[2] == "utils")
                            {
                                return ["com", "kixeye", "utils", "Rndm"];
                            }
                            if (id == "XMLNode" && a[0] == "flash" && a[1] == "xml")
                            {
                                return [];
                            }
                            if (id == "StringUtil") {
                                switch(a) {
                                    case ["mx", "utils"]: return [];
                                    default:
                                }
                            }
                            a.push(id);
                        case TOp(op):
                            if(op == "*") {
                                a.push(op);
                                break;
                            }
                            ParserUtils.unexpected(tk);
                        default: ParserUtils.unexpected(tk);
                    }
                case TCommented(s,b,t):
                    tokenizer.add(t);
                default:
                    tokenizer.add(tk);
                    break;
            }
        }
        Debug.dbgln(" -> " + a, tokenizer.line);
        if(cfg.testCase && a.join(".") == "flash.display.Sprite")
            return [];
        return a;
    }
}
