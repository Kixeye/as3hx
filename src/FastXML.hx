#if haxe4


import haxe.xml.Access;


@:forward()
abstract FastXML(Access) from Access to Access {
    
    public inline function new( x : Xml ) {
		this = new Access(x);
	}
    
    public function appendChild( a : Dynamic ) {
        if( Std.is(a, Xml) )
            this.x.addChild(a);
        else
            this.x.addChild(Xml.parse(a));
    }
    
    public function descendants(name:String = "*") : FastXMLList {
        var a = new Array<FastXML>();
        for(e in this.x.elements()) {
            if(e.nodeName == name || name == "*") {
                a.push(new FastXML(e));
            } else {
                var fx = new FastXML(e);
                a = a.concat(fx.descendants(name).getArray());
            }
        }
        return new FastXMLList(a);
    }
    
    @:from private static function fromXml( x : Xml ) {
        return new FastXML(x);
    }
    
    /**
     * Return the specified attribute, or null if it does not exist
     * @throws String if the nodeType is an XML Document
     **/
    public function getAttribute(name:String) : String {
        if( this.x.nodeType == Xml.Document )
            throw "Cannot access document attribute "+name;
        var v = this.x.get(name);
        return v;
    }
    
    public function length() : Int {
        return 1;
    }
    
    public function setAttribute(name:String, value:String) : Void {
        if( this.x.nodeType == Xml.Document )
            throw "Cannot access document attribute "+name;
        this.x.set(name,value);
    }
    
    public function toString() : String {
        return this.x.toString();
    }
    
    public static function parse(s:String) : FastXML {
        var x = Xml.parse(s);
        return new FastXML(x.firstChild());
    }
    
    public static function filterNodes(a : FastXMLList, f : FastXML -> Bool) : FastXMLList {
        var rv = new Array();
        for(i in a)
            if(f(i))
                rv.push(i);
        return new FastXMLList(rv);
    }
}


#else


private class NodeAccess #if !haxe4 implements Dynamic<FastXML> #end {

    var __x : Xml;

    public function new( x : Xml ) {
        __x = x;
    }

    public function resolve( name : String ) : FastXML {
        var x = __x.elementsNamed(name).next();
        if( x == null ) {
            var xname = if( __x.nodeType == Xml.Document ) "Document" else __x.nodeName;
            throw xname+" is missing element "+name;
        }
        return new FastXML(x);
    }

}

private class AttribAccess #if !haxe4 implements Dynamic<String> #end {

    var __x : Xml;

    public function new( x : Xml ) {
        __x = x;
    }

    public function resolve( name : String ) : String {
        if( __x.nodeType == Xml.Document )
            throw "Cannot access document attribute "+name;
        var v = __x.get(name);
        if( v == null )
            throw __x.nodeName+" is missing attribute "+name;
        return v;
    }

}

private class HasAttribAccess #if !haxe4 implements Dynamic<Bool> #end {

    var __x : Xml;

    public function new( x : Xml ) {
        __x = x;
    }

    public function resolve( name : String ) : Bool {
        if( __x.nodeType == Xml.Document )
            throw "Cannot access document attribute "+name;
        return __x.exists(name);
    }

}

private class HasNodeAccess #if !haxe4 implements Dynamic<Bool> #end {

    var __x : Xml;

    public function new( x : Xml ) {
        __x = x;
    }

    public function resolve( name : String ) : Bool {
        return __x.elementsNamed(name).hasNext();
    }

}

private class NodeListAccess #if !haxe4 implements Dynamic<FastXMLList> #end {

    var __x : Xml;

    public function new( x : Xml ) {
        __x = x;
    }

    public function resolve( name : String ) : FastXMLList {
        var l = new Array();
        for( x in __x.elementsNamed(name) ) 
            l.push(new FastXML(x));
        return new FastXMLList(l);
    }

}

class FastXML {

    public var x(default,null) : Xml;
    public var name(get,null) : String;
    public var innerData(get,null) : String;
    public var innerHTML(get,null) : String;
    public var node(default,null) : NodeAccess;
    public var nodes(default,null) : NodeListAccess;
    public var att(default,null) : AttribAccess;
    public var has(default,null) : HasAttribAccess;
    public var hasNode(default,null) : HasNodeAccess;
    public var elements(get,null) : Iterator<FastXML>;

    public function new( x : Xml ) {
        if( x.nodeType != Xml.Document && x.nodeType != Xml.Element )
            throw "Invalid nodeType "+x.nodeType;
        this.x = x;
        node = new NodeAccess(x);
        nodes = new NodeListAccess(x);
        att = new AttribAccess(x);
        has = new HasAttribAccess(x);
        hasNode = new HasNodeAccess(x);
    }

    public function appendChild( a : Dynamic ) {
        if( Std.is(a, Xml) )
            x.addChild(a);
        else
            x.addChild(Xml.parse(a));
    }

    public function descendants(name:String = "*") : FastXMLList {
        var a = new Array<FastXML>();
        for(e in x.elements()) {
            if(e.nodeName == name || name == "*") {
                a.push(new FastXML(e));
            } else {
                var fx = new FastXML(e);
                a = a.concat(fx.descendants(name).getArray());
            }
        }
        return new FastXMLList(a);
    }

    /**
     * Return the specified attribute, or null if it does not exist
     * @throws String if the nodeType is an XML Document
     **/
    public function getAttribute(name:String) : String {
        if( x.nodeType == Xml.Document )
            throw "Cannot access document attribute "+name;
        var v = x.get(name);
        return v;
    }

    function get_name():String {
        return if( x.nodeType == Xml.Document ) "Document" else x.nodeName;
    }

    function get_innerData():String {
        var it = x.iterator();
        if( !it.hasNext() )
            throw name+" does not have data";
        var v = it.next();
        var n = it.next();
        if( n != null ) {
            // handle <spaces>CDATA<spaces>
            if( v.nodeType == Xml.PCData && n.nodeType == Xml.CData && StringTools.trim(v.nodeValue) == "" ) {
                var n2 = it.next();
                if( n2 == null || (n2.nodeType == Xml.PCData && StringTools.trim(n2.nodeValue) == "" && it.next() == null) )
                    return n.nodeValue;
            }
            throw name+" does not only have data";
        }
        if( v.nodeType != Xml.PCData && v.nodeType != Xml.CData )
            throw name+" does not have data";
        return v.nodeValue;
    }

    function get_innerHTML():String {
        var s = new StringBuf();
        for( x in x )
            s.add(x.toString());
        return s.toString();
    }

    function get_elements():Iterator<FastXML> {
        var it = x.elements();
        return {
            hasNext : it.hasNext,
            next : function() {
                var x = it.next();
                if( x == null )
                    return null;
                return new FastXML(x);
            }
        };
    }

    public function length() : Int {
        return 1;
    }

    public function setAttribute(name:String, value:String) : Void {
        if( x.nodeType == Xml.Document )
            throw "Cannot access document attribute "+name;
        x.set(name,value);
    }
    
    public function toString() : String {
        return x.toString();
    }

    public static function parse(s:String) : FastXML {
        var x = Xml.parse(s);
        return new FastXML(x.firstChild());
    }

    public static function filterNodes(a : FastXMLList, f : FastXML -> Bool) : FastXMLList {
        var rv = new Array();
        for(i in a)
            if(f(i))
                rv.push(i);
        return new FastXMLList(rv);
    }
}


#end
