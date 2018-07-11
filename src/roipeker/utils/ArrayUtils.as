/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.utils {
import flash.utils.ByteArray;

public class ArrayUtils {

	private static var _tmp_ba:ByteArray;

	public static function clone( object:Object ):Object {
		if ( !_tmp_ba )
			_tmp_ba = new ByteArray();
		_tmp_ba.writeObject( object );
		_tmp_ba.position = 0;
		var o:Object = _tmp_ba.readObject();
		_tmp_ba.clear();
		return o;
	}

	public static function getIndexFromSearchProp( arr:Array, propValue:Object, propName:String = "text" ):int {
		var obj:Object = searchPropInArray( arr, propValue, propName );
		if ( !obj ) return -1;
		return arr.indexOf( obj );
	}

	public static function searchPropInArray( arr:Array, propValue:Object, propName:String = "text" ):Object {
		var len:int = arr.length;
		for ( var i:int = len - 1; i >= 0; i-- ) {
			var vo:Object = arr[i];
			if ( vo.hasOwnProperty( propName ) ) {
				if ( vo[propName] == propValue ) return vo;
			}
		}
		return null;
	}

	public static function toArray( iterable:* ):Array {
		var ret:Array = [];
		for each ( var elem:* in iterable ) ret[ret.length] = elem;
		return ret;
	}

	public static function remove( arr:Array, element:* ):void {
		var index:int = arr.indexOf( element );
		while ( index > -1 ) {
			arr.removeAt( index );
			index = arr.indexOf( element, index );
		}
	}

	/**
	 * Returns the min value in array.
	 * @param arr  contains Numbers,uint,int only
	 * @return
	 */
	public function getMinValue( arr:Array ):Number {
		return arr[arr.sort( 16 | 8 )[0]];
	}


	/**
	 * Returns the max value in array.
	 * @param arr  contains Numbers,uint,int only
	 * @return
	 */
	public function getMaxValue( arr:Array ):Number {
		return arr[int( arr.sort( 16 | 8 )[int( arr.length - 1 )] )];
	}


	public static function getItemsByKey( arr:Array, key:String, match:* ):Array {
		var out:Array = [];
		for ( var len:int = arr.length, i:int = len - 1; i >= 0; i-- ) {
			if ( arr[i] && arr[i][key] == match ) {
				out[out.length] = arr[i];
			}
		}
		return out;
	}

	public static function removeDuplicates( arr:Array ):Array {
		return arr.filter(
				function ( e:*, i:int, arr:Array ):Boolean {
					return (i == 0) ? true : arr.lastIndexOf( e, i - 1 ) == -1;
				});
	}

	public static function getRandomItems( arr:Array, len:int ):Array {
		if ( !arr ) return [];
		var tmp:Array = arr.concat();
		var result:Array = [];
		if ( len > arr.length ) len = arr.length;
		for ( var i:int = 0; i < len; i++ ) {
			var tmp_len:int = tmp.length;
			if ( tmp_len <= 0 ) break;
			var idx:int = Math.random() * tmp_len | 0;
			result[i] = tmp.removeAt( idx );
		}
		return result;
	}

	public static function randomSort( arr:Array, clone:Boolean = false ):Array {
		arr = clone ? arr.concat() : arr;
		arr.sort( randomize );
		return arr;

		function randomize( a:*, b:* ):int {
			return Math.random() > .5 ? 1 : -1;
		}
	}

	public static function pickRandom( arr:Array ):* {
		return arr[int( Math.round( Math.random() * (arr.length - 1) ) )];
	}

	public static function equals(arr1:Array, arr2:Array):Boolean {
		if( arr1.length != arr2.length ) return false ;
		for( var i:int=arr1.length-1; i >= 0; i--){
			if( arr1[i] != arr2[i]) return false ;
		}
		return true ;
	}

}
}
