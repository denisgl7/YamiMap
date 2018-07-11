/**
 *
 * Created by Rodrigo Lopez [blnk™] on 1/3/17.
 *
 */
package roipeker.starling.animation {
public class GreensockCustomEase {


	private var _numbersExp:RegExp = /(?:(-|-=|\+=)?\d*\.?\d*(?:e[\-+]?\d+)?)[0-9]/ig;
	private var _svgPathExp:RegExp = /[achlmqstvz]|(-?\d*\.?\d*(?:e[\-+]?\d+)?)[0-9]/ig;
	private var _scientific:RegExp = /[\+\-]?\d*\.?\d+e[\+\-]?\d+/ig;
	private var _needsParsingExp:RegExp = /[cLlsS]/g;

	private static var _map:Object = {}
	public var id:String;

	public function GreensockCustomEase(id:String, data:String, config:Object=null ) {
		this.id = id;
		if ( id ) {
			_map[id] = this;
		}
		setData( data, config );
	}

	public static function create( id:String, data:String, config:Object=null ):GreensockCustomEase {
		return new GreensockCustomEase( id, data, config );
	}

	public static function get( id:String ):GreensockCustomEase {
		return _map[id]
	}

	public static function getSVGData( ease:GreensockCustomEase, config:Object ):String {
		if ( !config ) config = {};
		var rnd:Number = 1000,
				width:Number = config.width || 100,
				height:Number = config.height || 100,
				x:Number = config.x || 0,
				y:Number = (config.y || 0) + height,
				e:Number = config.path,
				a:Array, slope:Number, i:uint, inc:Number, tx:Number, ty:Number, precision:Number, threshold:Number, prevX:Number, prevY:Number;
		if ( config.invert ) {
			height = -height;
			y = 0;
		}
//		ease = ease.getRatio ? ease : Ease.map[ease] || console.log("No ease found: ", ease);
		if ( !ease.rawBezier ) {
			a = ["M" + x + "," + y];
			precision = Math.max( 5, (config.precision || 1) * 200 );
			inc = 1 / precision;
			precision += 2;
			threshold = 5 / precision;
			prevX = (((x + inc * width) * rnd) | 0) / rnd;
			prevY = (((y + ease.getRatio( inc ) * -height) * rnd) | 0) / rnd;
			slope = (prevY - y) / (prevX - x);
			for ( i = 2; i < precision; i++ ) {
				tx = (((x + i * inc * width) * rnd) | 0) / rnd;
				ty = (((y + ease.getRatio( i * inc ) * -height) * rnd) | 0) / rnd;
				if ( Math.abs( (ty - prevY) / (tx - prevX) - slope ) > threshold || i === precision - 1 ) { //only add points when the slope changes beyond the threshold
					a.push( prevX + "," + prevY );
					slope = (ty - prevY) / (tx - prevX);
				}
				prevX = tx;
				prevY = ty;
			}
		} else {
			a = [];
			precision = ease.rawBezier.length;
			for ( i = 0; i < precision; i += 2 ) {
				a.push( (((x + ease.rawBezier[i] * width) * rnd) | 0) / rnd + "," + (((y + ease.rawBezier[i + 1] * -height) * rnd) | 0) / rnd );
			}
			a[0] = "M" + a[0];
			a[1] = "C" + a[1];
		}
		/*if (e) {
		 (typeof(e) === "string" ? document.querySelector(e) : e).setAttribute("d", a.join(" "));
		 }*/
		return a.join( " " );
	}

	private function _bezierToPoints( x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number,
									  y4:Number, threshold:Number, points:Array, index:Number ):Array {
		var x12:Number = (x1 + x2) / 2,
				y12:Number = (y1 + y2) / 2,
				x23:Number = (x2 + x3) / 2,
				y23:Number = (y2 + y3) / 2,
				x34:Number = (x3 + x4) / 2,
				y34:Number = (y3 + y4) / 2,
				x123:Number = (x12 + x23) / 2,
				y123:Number = (y12 + y23) / 2,
				x234:Number = (x23 + x34) / 2,
				y234:Number = (y23 + y34) / 2,
				x1234:Number = (x123 + x234) / 2,
				y1234:Number = (y123 + y234) / 2,
				dx:Number = x4 - x1,
				dy:Number = y4 - y1,
				d2:Number = Math.abs( (x2 - x4) * dy - (y2 - y4) * dx ),
				d3:Number = Math.abs( (x3 - x4) * dy - (y3 - y4) * dx ),
				length:Number;

		if ( !points ) {
			points = [{x: x1, y: y1}, {x: x4, y: y4}];
			index = 1;
		}
		points.splice( index || points.length - 1, 0, {x: x1234, y: y1234} );
		if ( (d2 + d3) * (d2 + d3) > threshold * (dx * dx + dy * dy) ) {
			length = points.length;
			_bezierToPoints( x1, y1, x12, y12, x123, y123, x1234, y1234, threshold, points, index );
			_bezierToPoints( x1234, y1234, x234, y234, x34, y34, x4, y4, threshold, points, index + 1 + (points.length - length) );
		}
		return points;
	}


	private function _findMinimum( values:Array ):Number {
		var l:uint = values.length,
				min:uint = 999999999999,
				i:uint;
		for ( i = 1; i < l; i += 6 ) {
			if ( +values[i] < min ) {
				min = +values[i];
			}
		}
		return min;
	}

	//takes all the points and translates/scales them so that the x starts at 0 and ends at 1.
	private function _normalize( values:Array, height:Number, originY:Number ) {
		if ( !originY && originY !== 0 ) {
			originY = Math.max( values[values.length - 1], values[1] );
		}
		var tx:Number = values[0] * -1,
				ty:Number = -originY,
				l:uint = values.length,
				sx:Number = 1 / (+values[l - 2] + tx),
				sy:Number = -height || ((Math.abs( +values[l - 1] - +values[1] ) < 0.01 * (+values[l - 2] - +values[0])) ? _findMinimum( values ) + ty : +values[l - 1] + ty),
				i:uint;
		if ( sy ) { //typically y ends at 1 (so that the end values are reached)
			sy = 1 / sy;
		} else { //in case the ease returns to its beginning value, scale everything proportionally
			sy = -sx;
		}
		for ( i = 0; i < l; i += 2 ) {
			values[i] = (+values[i] + tx) * sx;
			values[i + 1] = (+values[i + 1] + ty) * sy;
		}
	}

	private function _pathDataToBezier( d:String ) {
		var a = (d + "").replace( _scientific, function ( m:String ) {
							var n:Number = Number( m );
							return (n < 0.0001 && n > -0.0001) ? 0 : n;
						} ).match( _svgPathExp ) || [], //some authoring programs spit out very small numbers in scientific notation like "1e-5", so make sure we round that down to 0 first.
				path:Array = [],
				relativeX:Number = 0,
				relativeY:Number = 0,
				elements:uint = a.length,
				l:Number = 2,
				i:uint, x:Number, y:Number, command:String, isRelative, segment, startX:Number, startY:Number, prevCommand:String, difX:Number, difY:Number;
		for ( i = 0; i < elements; i++ ) {
			prevCommand = command;
			if ( isNaN( a[i] ) ) {
				command = a[i].toUpperCase();
				isRelative = (command !== a[i]); //lower case means relative
			} else { //commands like "C" can be strung together without any new command characters between.
				i--;
			}
			x = +a[i + 1];
			y = +a[i + 2];
			if ( isRelative ) {
				x += relativeX;
				y += relativeY;
			}
			if ( !i ) {
				startX = x;
				startY = y;
			}
			if ( command === "M" ) {
				if ( segment && segment.length < 8 ) { //if the path data was funky and just had a M with no actual drawing anywhere, skip it.
					path.length -= 1;
					l = 0;
				}
				relativeX = startX = x;
				relativeY = startY = y;
				segment = [x, y];
				l = 2;
				path.push( segment );
				i += 2;
				command = "L"; //an "M" with more than 2 values gets interpreted as "lineTo" commands ("L").

			} else if ( command === "C" ) {
				if ( !segment ) {
					segment = [0, 0];
				}
				segment[l++] = x;
				segment[l++] = y;
				if ( !isRelative ) {
					relativeX = relativeY = 0;
				}
				segment[l++] = relativeX + a[i + 3] * 1; //note: "*1" is just a fast/short way to cast the value as a Number. WAAAY faster in Chrome, slightly slower in Firefox.
				segment[l++] = relativeY + a[i + 4] * 1;
				segment[l++] = relativeX = relativeX + a[i + 5] * 1;
				segment[l++] = relativeY = relativeY + a[i + 6] * 1;
				i += 6;

			} else if ( command === "S" ) {
				if ( prevCommand === "C" || prevCommand === "S" ) {
					difX = relativeX - Number( segment[l - 4] );
					difY = relativeY - Number( segment[l - 3] );
					segment[l++] = relativeX + difX;
					segment[l++] = relativeY + difY;
				} else {
					segment[l++] = relativeX;
					segment[l++] = relativeY;
				}
				segment[l++] = x;
				segment[l++] = y;
				if ( !isRelative ) {
					relativeX = relativeY = 0;
				}
				segment[l++] = relativeX = relativeX + a[i + 3] * 1;
				segment[l++] = relativeY = relativeY + a[i + 4] * 1;
				i += 4;

			} else if ( command === "L" || command === "Z" ) {
				if ( command === "Z" ) {
					x = startX;
					y = startY;
//					segment.closed = true;
				}
				if ( command === "L" || Math.abs( relativeX - x ) > 0.5 || Math.abs( relativeY - y ) > 0.5 ) {
					segment[l++] = relativeX + (x - relativeX) / 3;
					segment[l++] = relativeY + (y - relativeY) / 3;
					segment[l++] = relativeX + (x - relativeX) * 2 / 3;
					segment[l++] = relativeY + (y - relativeY) * 2 / 3;
					segment[l++] = x;
					segment[l++] = y;
					if ( command === "L" ) {
						i += 2;
					}
				}
				relativeX = x;
				relativeY = y;
			} else {
				throw _bezierError;
			}

		}
		return path[0];
	}

	public function getRatio( p:Number ):Number {
		var point:Object = this.lookup[(p * this.l) | 0] || this.lookup[this.l - 1];
		if ( point.nx < p ) {
			point = point.n;
		}
		return point.y + ((p - point.x) / point.cx) * point.cy;
	}

	public var data:String;
	public var rawBezier:Array;
	public var lookup:Array;
	public var points:Array;
	public var fast:Boolean;
	public var l:Number;
	private var _bezierError:Error = new Error( "CustomEase only accepts Cubic Bezier data." );


	public function setData( data:String, config:Object=null ) {
		data = data || "0,0,1,1";
		var values:Array = data.match( _numbersExp ),
				closest:Number = 1,
				points:Array = [],
				len:int, a1, a2, i, inc:Number, j, point, prevPoint, p, precision;
		config = config || {};
		precision = config.precision || 1;
		this.data = data;
		this.lookup = [];
		this.points = points;
		this.fast = (precision <= 1);
		if ( _needsParsingExp.test( data ) || (data.indexOf( "M" ) !== -1 && data.indexOf( "C" ) === -1) ) {
			values = _pathDataToBezier( data );
		}
		trace("values:", values );
		len = values.length;
		if ( len === 4 ) {
			values.unshift( 0, 0 );
			values.push( 1, 1 );
			len = 8;
		} else if ( (len - 2) % 6 ) {
			throw _bezierError;
		}
		if ( Number(values[0]) != 0 || Number(values[len - 2]) != 1 ) {
			_normalize( values, config.height, config.originY );
		}

		this.rawBezier = values;
		for ( i = 2; i < len; i += 6 ) {
			a1 = {x: +values[i - 2], y: +values[i - 1]};
			a2 = {x: +values[i + 4], y: +values[i + 5]};
			points.push( a1, a2 );
			_bezierToPoints( a1.x, a1.y, +values[i], +values[i + 1], +values[i + 2], +values[i + 3], a2.x, a2.y, 1 / (precision * 200000), points, points.length - 1 );
		}
		len = points.length;
		trace("points len:", len );
		for ( i = 0; i < len; i++ ) {
			point = points[i];
			prevPoint = points[i - 1] || point;
			trace(i, prevPoint, point.x > prevPoint.x );
			//if a point goes BACKWARD in time or is a duplicate, just drop it.
			if ( point.x > prevPoint.x || (prevPoint.y != point.y && prevPoint.x == point.x) || point == prevPoint ) {
				//change in x between this point and the next point (performance optimization)
				prevPoint.cx = point.x - prevPoint.x;
				prevPoint.cy = point.y - prevPoint.y;
				prevPoint.n = point;
				//next point's x value (performance optimization, making lookups faster in getRatio()). Remember, the lookup will always land on a spot where it's either this point or the very next one (never beyond that)
				prevPoint.nx = point.x;
				//if there's a sudden change in direction, prioritize accuracy over speed. Like a bounce ease - you don't want to risk the sampling chunks landing on each side of the bounce anchor and having it clipped off.
				if ( this.fast && i > 1 && Math.abs( prevPoint.cy / prevPoint.cx - points[i - 2].cy / points[i - 2].cx ) > 2 ) {
					trace("remove flast!");
					this.fast = false;
				}
				trace(prevPoint.cx, closest);
				if ( prevPoint.cx < closest ) {
					if ( !prevPoint.cx ) {
						prevPoint.cx = 0.001; //avoids math problems in getRatio() (dividing by zero)
					} else {
						closest = prevPoint.cx;
					}
				}
			} else {
				points.splice( i--, 1 );
				len--;
			}
		}
		len = (1 / closest + 1) | 0;
		l = len; //record for speed optimization
		inc = 1 / len;
		j = 0;
		point = points[0];
		trace("new LEN", l, closest );
		trace("is fst:",fast);
//		return ;
		if ( this.fast ) {
			for ( i = 0; i < len; i++ ) { //for fastest lookups, we just sample along the path at equal x (time) distance. Uses more memory and is slightly less accurate for anchors that don't land on the sampling points, but for the vast majority of eases it's excellent (and fast).
				p = i * inc;
				if ( point.nx < p ) {
					point = points[++j];
				}
				a1 = point.y + ((p - point.x) / point.cx) * point.cy;
				this.lookup[i] = {x: p, cx: inc, y: a1, cy: 0, nx: 9};
				if ( i ) {
					this.lookup[i - 1].cy = a1 - this.lookup[i - 1].y;
				}
			}
			trace("lookup",lookup.length);
			this.lookup[len - 1].cy = points[points.length - 1].y - a1;
		} else { //this option is more accurate, ensuring that EVERY anchor is hit perfectly. Clipping across a bounce, for example, would never happen.
			for ( i = 0; i < len; i++ ) { //build a lookup table based on the smallest distance so that we can instantly find the appropriate point (well, it'll either be that point or the very next one). We'll look up based on the linear progress. So it's it's 0.5 and the lookup table has 100 elements, it'd be like lookup[Math.floor(0.5 * 100)]
				if ( point.nx < i * inc ) {
					point = points[++j];
				}
				this.lookup[i] = point;
			}
		}
		return this;
	}


	/*CustomEase = function (id, data, config) {
	 this._calcEnd = true;
	 this.id = id;
	 if (id) {
	 Ease.map[id] = this;
	 }
	 this.getRatio = _getRatio; //speed optimization, faster lookups.
	 this.setData(data, config);
	 },*/
}
}


/*
 private static var _all:Object = {}; //keeps track of all CustomEase instances.
 private var _segments:Array;
 private var _name:String;

 public static function create( name:String, segments:Array ):Function {
 var b:CustomEase = new CustomEase( name, segments );
 return b.ease;
 }

 public static function byName( name:String ):Function {
 return _all[name].ease;
 }

 public function CustomEase( name:String, segments:Array ) {
 _name = name;
 _segments = [];
 var l:int = segments.length;
 for ( var i:int = 0; i < l; i++ ) {
 _segments[_segments.length] = new Segment( segments[i].s, segments[i].cp, segments[i].e );
 }
 _all[name] = this;
 }

 public function ease( time:Number, start:Number, change:Number, duration:Number ):Number {
 var factor:Number = time / duration, qty:uint = _segments.length, t:Number, s:Segment;
 var i:int = int( qty * factor );
 t = (factor - (i * (1 / qty))) * qty;
 s = _segments[i];
 return start + change * (s.s + t * (2 * (1 - t) * (s.cp - s.s) + t * (s.e - s.s)));
 }

 public function destroy():void {
 _segments = null;
 delete _all[_name];
 }

 }
 }

 //allows for strict data typing, making lookups faster
 internal class Segment {
 public var s:Number;
 public var cp:Number;
 public var e:Number;

 public function Segment( s:Number, cp:Number, e:Number ) {
 this.s = s;
 this.cp = cp;
 this.e = e;
 }
 }*/
