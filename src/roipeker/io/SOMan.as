/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.io {
import flash.net.SharedObject;

public class SOMan {

	public static var sharedObjectId:String = "data";
	private static var _instance:SOMan;
	public static function get instance():SOMan {
		if ( !_instance ) {
			_instance = new SOMan();
			_instance.init() ;
		}
		return _instance;
	}

	private var so:SharedObject;

	public function SOMan() {}

	private function init():void {
		so = SharedObject.getLocal( sharedObjectId );
//		asdfasdf
	}

	public function has( prop:String ):Boolean {
		return !so ? null : so.data.hasOwnProperty(prop);
	}
	public function get( prop:String ):* {
		if ( !so ) init();
		return so.data[prop];
	}

	public function set( prop:String, value:Object ):void {
		if ( !so ) init();
		if( value == null ){
			delete so.data[prop];
		} else {
			so.data[prop] = value ;
		}
		so.flush();
	}

	public function copyProps( obj:Object ):void {
		if (!obj) return ;
		for( var p:String in obj ){
			so.data[p] = obj[p];
		}
		so.flush();
	}

	public function clear( prop:String ):void {
		set( prop, null );
	}

	public function dispose():void {
		so.clear();
		so = null;
	}

}
}
