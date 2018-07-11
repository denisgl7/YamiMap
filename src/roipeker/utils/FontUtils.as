/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/30/17.
 *
 */
package roipeker.utils {
import flash.text.Font;

public class FontUtils {
	public function FontUtils() {
	}

	public static function traceFonts( system:Boolean = false ):void {
		var list:Array = Font.enumerateFonts( system );
		trace( "---- Flash Fonts ----- " );
		for each( var font:Font in list ) {
			trace( font.fontName );
		}
		trace( "---- end Flash Fonts ----- " );
	}
}
}
