/**
 * Tests of assertions in if statements
 **/

package {

public class Ifs {

	public function single(a:Sprite) {
		if(a) {
			a.x = 15;
		}
	}

	public function singleInv(a:Sprite) {
		if(!a) {
			a = new Sprite();
		}
	}

	public function binops(a:Sprite, b:Sprite) {
		if(a && b)
			trace("We have two sprites");
		if(a || b)
			trace("We have at least one sprite");
		if(a && !b)
			trace("a is ok, b is null");
		if(!a && b)
			trace("a is null, b is ok");
	}

	public function aBool(b:Boolean) {
		// should parse to if(b)
		if(b) {
		}
		// should parse to if(!b)
		if(!b) {
		}
		// should be left alone as if(b == null)
		if(b == null) {
		}
	}

	public function maths(a:Int) {
		// should parse to if(a++ != 0)
		if(a++) {
		}
		// should parse to if(a++ == 0)
		if(!a++) {
		}
		// should parse to if(++a++ != 0)
		if(++a++) {
		}
		// should parse to if(++a++ == 0)
		if(!++a++) {
		}
	}

	function value_or_default(s:String):void {
		// should convert to var r:String = (s == null || s.length == 0) ? "" : s;
		var r:String = s || "";
		s = s || "";
		// should convert to o = o != null ? o : {};
		var o:Object = {};
		o = o || {};
	}

	function integer_truthiness_semantics(i:Int) {
		if (i) {
			// Should parse to if (i != null && i != 0)
		}
		if (!i) {
			// Should parse to if (!(i != null && i != 0))
		}
		var b:Boolean = true;
		if (b && i) {
			// Should parse to if (b && (i != null && i != 0))
		}
		if (b && !i) {
			// Should parse to if (b && !(i != null && i != 0))
		}
	}

	function float_truthiness_semantics(f:Float) {
		if (f) {
			// Should parse to if (f != null && f != 0 && !Math.isNaN(f))
		}
		if (!f) {
			// Should parse to if (!(f != null && f != 0 && !Math.isNaN(f)))
		}
		var b:Boolean = true;
		if (b && f) {
			// Should parse to if (b && (f != null && f != 0 && !Math.isNaN(f)))
		}
		if (b && !f) {
			// Should parse to if (b && !(f != null && f != 0 && !Math.isNaN(f)))
		}
	}

	function string_truthiness_semantics(s:String) {
		if (s) {
			// Should parse to if (s != null && s != '')
		}
		if (!s) {
			// Should parse to if (!(s != null && s != ''))
		}
		var b:Boolean = true;
		if (b && s) {
			// Should parse to if (b && (s != null && s != ''))
		}
		if (b && !s) {
			// Should parse to if (b && !(s != null && s != ''))
		}
	}
}

}
