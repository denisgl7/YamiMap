/**
 *
 * Created by Rodrigo Lopez [blnk™] on 1/8/17.
 *
 */
package roipeker.starling.animation {
import com.greensock.TweenLite;
import com.greensock.plugins.TweenPlugin;

public class GreensockStarlingColorPlugin extends TweenPlugin {

	public static const API:Number = 2;
	private var _colors:Array;

	public function GreensockStarlingColorPlugin() {
		super( "color" );
		_overwriteProps = [];
		_colors = [];
	}

	override public function _onInitTween( target:Object, value:*, tween:TweenLite ):Boolean {
		_initColor( target, "color", uint( value ) );
		return true;
	}

	public function _initColor( target:Object, p:String, end:uint ):void {
		var isFunc:Boolean = (typeof(target[p]) == "function");
		// avoid errors.
//		var start:uint = !isFunc ? target[p] : target[((p.indexOf( "set" ) || !("get" + p.substr( 3 ) in target)) ? p : "get" + p.substr( 3 ))]();
		var start:uint = target[p] ;
		if ( start != end ) {
			var r:uint = start >> 16,
					g:uint = (start >> 8) & 0xff,
					b:uint = start & 0xff;
			_colors[_colors.length] = new ColorProp( target, p, isFunc, r, (end >> 16) - r, g, ((end >> 8) & 0xff) - g, b, (end & 0xff) - b );
			_overwriteProps[_overwriteProps.length] = p;
		}
	}

	override public function _kill( lookup:Object ):Boolean {
		var i:int = _colors.length;
		while ( i-- ) {
			if ( lookup[_colors[i].p] != null ) {
				_colors.removeAt( i );
			}
		}
		return super._kill( lookup );
	}

	override public function setRatio( v:Number ):void {
		var i:int = _colors.length, clr:ColorProp, val:Number;
		while ( --i > -1 ) {
			clr = _colors[i];
			val = (clr.rs + (v * clr.rc)) << 16 | (clr.gs + (v * clr.gc)) << 8 | (clr.bs + (v * clr.bc));
			if ( clr.f ) {
				clr.t[clr.p]( val );
			} else {
				clr.t[clr.p] = val;
			}
		}
	}

}
}


internal class ColorProp {
	public var t:Object;
	public var p:String;
	public var f:Boolean;
	public var rs:int;
	public var rc:int;
	public var gs:int;
	public var gc:int;
	public var bs:int;
	public var bc:int;

	public function ColorProp( t:Object, p:String, f:Boolean, rs:int, rc:int, gs:int, gc:int, bs:int, bc:int ) {
		this.t = t;
		this.p = p;
		this.f = f;
		this.rs = rs;
		this.rc = rc;
		this.gs = gs;
		this.gc = gc;
		this.bs = bs;
		this.bc = bc;
	}
}

/*



 protected var _colors:Array;

 /!** @private **!/
 public function HexColorsPlugin() {
 super("hexColors");
 _overwriteProps = [];
 _colors = [];
 }

 /!** @private **!/
 override public function _onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
 for (var p:String in value) {
 _initColor(target, p, uint(value[p]));
 }
 return true;
 }

 /!** @private **!/
 public function _initColor(target:Object, p:String, end:uint):void {
 var isFunc:Boolean = (typeof(target[p]) == "function"),
 start:uint = (!isFunc) ? target[p] : target[ ((p.indexOf("set") || !("get" + p.substr(3) in target)) ? p : "get" + p.substr(3)) ]();
 if (start != end) {
 var r:uint = start >> 16,
 g:uint = (start >> 8) & 0xff,
 b:uint = start & 0xff;
 _colors[_colors.length] = new ColorProp(target, p, isFunc, r, (end >> 16) - r, g, ((end >> 8) & 0xff) - g, b, (end & 0xff) - b);
 _overwriteProps[_overwriteProps.length] = p;
 }
 }

 /!** @private **!/
 override public function _kill(lookup:Object):Boolean {
 var i:int = _colors.length;
 while (i--) {
 if (lookup[_colors[i].p] != null) {
 _colors.splice(i, 1);
 }
 }
 return super._kill(lookup);
 }

 /!** @private **!/
 override public function setRatio(v:Number):void {
 var i:int = _colors.length, clr:ColorProp, val:Number;
 while (--i > -1) {
 clr = _colors[i];
 val = (clr.rs + (v * clr.rc)) << 16 | (clr.gs + (v * clr.gc)) << 8 | (clr.bs + (v * clr.bc));
 if (clr.f) {
 clr.t[clr.p](val);
 } else {
 clr.t[clr.p] = val;
 }
 }
 }


 }
 }

 internal class ColorProp {
 public var t:Object;
 public var p:String;
 public var f:Boolean;
 public var rs:int;
 public var rc:int;
 public var gs:int;
 public var gc:int;
 public var bs:int;
 public var bc:int;

 public function ColorProp(t:Object, p:String, f:Boolean, rs:int, rc:int, gs:int, gc:int, bs:int, bc:int) {
 this.t = t;
 this.p = p;
 this.f = f;
 this.rs = rs;
 this.rc = rc;
 this.gs = gs;
 this.gc = gc;
 this.bs = bs;
 this.bc = bc;
 }
 }*/
