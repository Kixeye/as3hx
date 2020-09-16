package as3hx;

import as3hx.As3;
import concurrent.ConcurrentMap;

typedef Field = {
    var kwds : Array<String>;
    var type : String;
}

class Lookup {

    var cfg:Config;
    var fields: ConcurrentMap<String, ConcurrentMap<String, Field>> = new ConcurrentMap();
    var functions: ConcurrentMap<String, ConcurrentMap<String, Function>> = new ConcurrentMap();
    var hierarchy: ConcurrentMap<String, String> = new ConcurrentMap();

    static var knownTypes : Map<String, Map<String, String>> = [
        "SharedObject" => [
            "data" => "Object"
        ],
        "Array" => [
            "length" => "int"
        ],
        "String" => [
            "length" => "int"
        ],
        "FastXMLList" => [
            "length" => "int"
        ],
        "Point" => [
            "x" => "Number",
            "y" => "Number"
        ],
        "TextField" => [
            "x" => "Number",
            "y" => "Number",
            "width" => "Number",
            "height" => "Number",
            "textWidth" => "Number",
            "sharpness" => "Number",
            "thickness" => "Number"
        ]
    ];

    public function new(config:Config) {
        cfg = config;
        for (className in knownTypes.keys()) {
            var fields = knownTypes.get(className);
            for (fieldName in fields.keys()) {
                addField(className, fieldName, fields.get(fieldName), []);
            }
        }
    }

    function tstring(t : T) : String {
        if(t == null) return null;
        return switch(t) {
            case TStar: "Dynamic";
            case TVector(t): cfg.vectorToArray ? "Array<" + tstring(t) + ">" : "Vector<" + tstring(t) + ">";
            case TDictionary(k, v): (cfg.dictionaryToHash ? "haxe.ds.ObjectMap<" : "Dictionary<") + tstring(k) + ", " + tstring(v) + ">";
            case TPath(p):
                var c = p.join(".");
                return switch(c) {
                    case "Array"    : "Array<Dynamic>";
                    case "Boolean"  : "Bool";
                    case "Class"    : "Class<Dynamic>";
                    case "int"      : "Int";
                    case "Number"   : cfg.floatType;
                    case "uint"     : cfg.uintToInt ? "Int" : "UInt";
                    case "void"     : "Void";
                    case "Function" : cfg.functionToDynamic ? "Dynamic" : c;
                    case "Object"   : "Dynamic";
                    case "XML"      : cfg.useFastXML ? "FastXML" : "Xml";
                    case "XMLList"  : cfg.useFastXML ? "FastXMLList" : "Iterator<Xml>";
                    case "RegExp"   : cfg.useCompat ? "as3hx.Compat.Regex" : "flash.utils.RegExp";
                    default         : c;
                }
            default: null;
        }
    }

    public function getModifiedIdent(s : String) : String {
        return switch(s) {
            case "int": "Int";
            case "uint": cfg.uintToInt ? "Int" : "UInt";
            case "Number": cfg.floatType;
            case "Boolean": "Bool";
            case "Function": cfg.functionToDynamic ? "Dynamic" : s;
            case "Object": "Dynamic";
            case "undefined": "null";
            //case "Error": cfg.mapFlClasses ? "flash.errors.Error" : s;
            case "XML": "FastXML";
            case "XMLList": "FastXMLList";
            case "NaN":"Math.NaN";
            case "Dictionary": cfg.dictionaryToHash ? "haxe.ds.ObjectMap" : s;
            //case "QName": cfg.mapFlClasses ? "flash.utils.QName" : s;
            default: s;
        };
    }

    public function process(program:Program) {
        for (def in program.defs) {
            switch (def) {
                case CDef(c):
                    if (fields.exists(c.name) || hierarchy.exists(c.name)) {
                        Sys.println("WARNING: " + c.name + " already exists in another package.");
                    }
                    fields.setIfNotExists(c.name, new ConcurrentMap());
                    switch (c.extend) {
                        case TPath(p):
                            hierarchy.set(c.name, p[0]);
                        default:
                    }
                    for (field in c.fields) {
                        switch (field.kind) {
                            case FVar(t, val):
                                addField(c.name, field.name, tstring(t), field.kwds);
                            case FFun(f):
                                if (field.kwds.indexOf("get") != -1) {
                                    addField(c.name, field.name, tstring(f.ret.t), field.kwds);
                                } else {
                                    addFunction(c.name, field.name, f);
                                }
                            default:
                        }
                    }
                default:
            }
        }
    }

    function addField(className:String, name:String, type:String, kwds: Array<String>) {
        fields.setIfNotExists(className, new ConcurrentMap());
        fields.get(className).set(name, {
            type: getModifiedIdent(type),
            kwds: kwds
        });
    }

    function addFunction(className:String, name:String, f:Function) {
        functions.setIfNotExists(className, new ConcurrentMap());
        functions.get(className).set(name, f);
    }

    public function getField(className:String, name:String):Field {
        if (fields.exists(className) && fields.get(className).exists(name)) {
            return fields.get(className).get(name);
        }
        if (functions.exists(className) && functions.get(className).exists(name)) {
            var f = functions.get(className).get(name);
            return {
                type: tstring(f.ret.t),
                kwds: []
            };
        }
        if (hierarchy.exists(className)) {
            return getField(hierarchy.get(className), name);
        }
        return {
            type: null,
            kwds: []
        };
    }

    public function getFunction(className:String, name:String):Function {
        if (className == null) {
            return null;
        }
        if (functions.exists(className) && functions.get(className).exists(name)) {
            return functions.get(className).get(name);
        }
        if (hierarchy.exists(className)) {
            return getFunction(hierarchy.get(className), name);
        }
        return null;
    }

    function getClassName(expr:Expr, context:Map<String, String>):String {
        switch (expr) {
            case EField(e, f):
                var c = getClassName(e, context);
                return c != null ? getField(c, f).type : null;

            case EIdent(i):
                if (context.exists(i)) {
                    return getModifiedIdent(context.get(i));
                }
                return i;
            default:
        }
        return null;
    }

    /* Look up class where field 's' is defined */
    function getClassForField(className:String, s:String):String
    {
        if (fields.exists(className) && fields.get(className).exists(s)) {
            return className;
        }
        if (hierarchy.exists(className)) {
            return getClassForField(hierarchy.get(className), s);
        }
        return null;
    }

    public function resolveFullIdent(className:String, s:String, context:Map<String, String>):String
    {
        if (context.exists(s)) {
            return getModifiedIdent(s);
        }

        var klassName = getClassForField(className, s);

        // If the field is declared static in a superclass, explicitly refer to that definition.
        if (klassName != null && klassName != className)
        {
            if (getField(klassName, s).kwds.indexOf("static") != -1)
            {
                return klassName + "." + getModifiedIdent(s);
            }
        }

        return getModifiedIdent(s);
    }

    public function resolveFunction(thisName:String, expr: Expr, context:Map<String, String>):Function {
        switch (expr) {
            case EField(e, f):
                var c = getClassName(e, context);
                return getFunction(c, f);

            case EIdent(i):
                return getFunction(thisName, i);

            default:
        }

        return null;
    }
}
