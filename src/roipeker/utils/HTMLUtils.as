/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.utils {
public class HTMLUtils {


	/**
	 * Convert links in a string to HTML links using the <a> tag
	 * @param text    The text to convert
	 * @return    The converted text.
	 */
	public static function convertUrlsToLinks( text:String ):String {
		var re:RegExp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig;
		return text.replace( re, "<a href='$1'>$1</a>" );
	}

	public static function removeHTMLTags( html:String, keepTags:String = "" ):String {
		var toKeept:Array = [];
		if ( keepTags.length > 0 ) {
			toKeept = keepTags.split( new RegExp( "\\s*,\\s*" ) );
		}
		var toKeep:Array = [];
		for ( var i:int = toKeept.length - 1; i >= 0; --i ) {
			if ( toKeept[i] && toKeept[i] != "" ) toKeep[toKeep.length] = toKeept[i];
		}

		var toRemoved:Array = [];
		var found:Array = html.match( new RegExp( "<([^>\\s]+)(\\s[^>]+)*>", "g" ) );
		var len:int = found.length;
		for ( i = 0; i < len; i++ ) {
			var tagFlag:Boolean = false;
			if ( toKeep ) {
				for ( var j:int = 0; j < toKeep.length; j++ ) {
					var tmpRegExp:RegExp = new RegExp( "<\/?" + toKeep[j] + "[^<>]*?>", "i" );
					var tmpStr:String = found[i] as String;
					if ( tmpStr.search( tmpRegExp ) != -1 ) {
						tagFlag = true;
					}
				}
			}
			if ( !tagFlag ) toRemoved[toRemoved.length] = found[i];
		}

		for ( i = 0; i < len; i++ ) {
			var tmpRE:RegExp = new RegExp( "([\+\*\$\/])", "g" );
			var tmpRemRE:RegExp = new RegExp( ( toRemoved[i] as String ).replace( tmpRE, "\\$1" ), "g" );
			html = html.replace( tmpRemRE, "" );
		}
		return html;
	}
}
}
