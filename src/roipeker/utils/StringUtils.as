/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/29/17.
 *
 */
package roipeker.utils {
public class StringUtils {
	public function StringUtils() {
	}

	/**
	 * adds digits
	 * @param value    can be int, num or string.
	 * @param len
	 * @return
	 */
	public static function zeroPad( value:*, len:int ):String {
		for ( var val:String = String( value ); val.length < len; val = '0' + val ) {}
		return val;
	}

	public static function replaceMultiple( str:String, searchs:Array, replacements:Array=null ):String {
		if ( !str || !searchs ) return str;
		if( replacements!=null && replacements.length!=searchs.length ){
			trace("ERROR: StringUtils::replaceMultiple searches and replacements must have the same amount of items");
			return str ;
		}
		var len:int = searchs.length ;
		for ( var i:int = 0; i < len; i++ ) {
			str = replace(str, searchs[i], !replacements?"":replacements[i])
		}
		return str ;
	}

	public static function replace( str:String, search:String, replacement:String = "" ):String {
		if ( !str ) return str;
		return str.split( search ).join( replacement );
	}

	public static function trim( s:String ):String {
		return s ? s.replace( /^\s+|\s+$/gs, '' ) : "";
	}

	public static function reduceWhiteSpace(s:String):String {
		return s ? s.replace(/\s+/g, ' ') : "" ;
	}

	public static function format( format:String, ...args ):String {
		// TODO: add number formatting options
		for ( var i:int = 0; i < args.length; ++i )
			format = format.replace( new RegExp( "\\{" + i + "\\}", "g" ), args[i] );
		return format;
	}

    public static function formatKeys( format:String, props:Object ):String {
        var key:String ;
        for( key in props ){
            format = format.replace( new RegExp( "\\${" + key + "\\}", "g" ), props[key] );
        }
        return format;
    }

}
}
