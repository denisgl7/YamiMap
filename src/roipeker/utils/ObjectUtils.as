/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.utils {
import flash.utils.ByteArray;

public class ObjectUtils {
	public function ObjectUtils() {
	}

	public static function shallowCopy( source:Object, obj:Object = null ):Object {
		if ( !obj )
			obj = {};

		if ( source )
			for ( var o:* in source ) obj[o] = source[o];

		return obj;
	}

	public static function deepCopy( obj:Object ):Object {
		if(!obj) return {} ;
		var ba:ByteArray = new ByteArray;
		ba.writeObject(obj);
		ba.position=0;
		return ba.readObject();
	}

	public static function hasProperties(obj:Object):Boolean {
		if(!obj) return false ;
		for( var p:String in obj ) return true ;
		return false ;
	}

	public static function numProperties(obj:Object):uint{
		if(!obj) return 0 ;
		var count:uint=0;
		for( var p:String in obj ) ++count;
		return count ;
	}

	public static function propertiesToArray(obj:Object):Array{
		if(!obj) return null ;
		var props:Array = [] ;
		for each( var p:String in obj ) props[props.length] = p;
		return props;
	}

	public static function toString(obj:Object,delimiter:String="\n"):String {
		if( !obj || !delimiter) return "";
		var arr:Array = [];
		for( var p:String in obj ){
			arr[arr.length] = p + ": " + obj[p];
		}
		return arr.join(delimiter);
	}
	
	public static function printObject( object:Object, indent:String = "" ):void {
		for( var key:String in object ) {
			const value:Object = object[key];
			printObject( value, indent + "  " );
		}
	}
}
}
