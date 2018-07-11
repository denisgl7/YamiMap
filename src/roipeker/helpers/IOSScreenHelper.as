/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/30/17.
 *
 */
package roipeker.helpers {
import flash.system.Capabilities;

public class IOSScreenHelper {

	private static var identifier:String ;

	private static var _isIpad:Boolean;
	private static var _isIphone:Boolean;
	private static var _isIpod:Boolean;

	public function IOSScreenHelper() {
	}

	public static function init():void {
		var os:String = Capabilities.os;
		identifier = os.split(" ").pop() ;
		_isIpad = identifier.search(/iPad/)>-1;
		if( !_isIpad ) {
			_isIphone = identifier.search(/iPhone/)>-1;
			if( !_isIphone )
				_isIpod = identifier.search(/iPod/)>-1;
		}
//		[trace] Capabilities os= iPhone OS 7.0.4 iPad4,4 version= IOS 26,0,0,120
//		iPhone OS 7.0.4
//		var isIphonePlus:Boolean = /(iPhone9,2|iPhone9,4|iPhone8,2|iPhone7,1)/.exec(os) != null ;
	}

	public static function get isIphonePlus():Boolean {
		return /(iPhone9,2|iPhone9,4|iPhone8,2|iPhone7,1)/.exec(identifier) != null
	}

	public static function get isIpadMini():Boolean {
		return /(iPad4,4|iPad4,5|iPad4,6|iPad4,7|iPad4,8|iPad4,9)/.exec(identifier) != null
	}

	public static function get isIpad():Boolean {
		return _isIpad;
	}

	public static function get isIphone():Boolean {
		return _isIphone;
	}
}
}
