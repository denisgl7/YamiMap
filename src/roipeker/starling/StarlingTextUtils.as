/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/4/17.
 *
 */
package roipeker.starling {
import starling.text.TextField;
import starling.text.TextFieldAutoSize;

public class StarlingTextUtils {


	public function StarlingTextUtils() {
	}


	public static function ellipsis( tf:TextField, str:String = null, breakWords:Boolean = true,
									 dots:String = "…" ):Boolean {
		var autoSizeH:Boolean = tf.autoSize == TextFieldAutoSize.HORIZONTAL;
		var autoSizeV:Boolean = tf.autoSize == TextFieldAutoSize.VERTICAL;
		if ( autoSizeV || ( autoSizeH && autoSizeV ) ) return false;
		cloneProperties( tf );
		if ( !str ) str = tf.text;
		str = TextFieldHelper.ellipsis( str, breakWords, dots );
		if ( str ) tf.text = str;
		return str != null;
	}

	// faster than ellpsis but multilinea and breaks words...
	public static function stripSingleLine( tf:TextField, str:String = null, dots:String = "…" ):Boolean {
		cloneProperties( tf );
		if ( !str ) str = tf.text;
		str = TextFieldHelper.stripSingleLine( str, dots );
		if ( str ) tf.text = str;
		return str != null;
	}

	private static function cloneProperties( tf:TextField ):void {
		tf.format.toNativeFormat( TextFieldHelper.format );
		TextFieldHelper.applyProps(
				tf.width, tf.height, tf.autoSize, tf.wordWrap
		);
	}

}
}

import roipeker.utils.StringUtils;

import flash.text.TextField;
import flash.text.TextFormat;

import starling.utils.SystemUtil;

internal class TextFieldHelper {

	internal static var format:TextFormat = new TextFormat();
	private static var dummy:TextField;

	public function TextFieldHelper():void {}

	public static function applyProps( w:Number, h:Number, autoSize:String, wordWrap:Boolean,
									   text:String = null ):void {
		if ( !dummy ) initFlashText();
		if ( text ) dummy.text = text;
		var autoSizeV:Boolean = autoSize == "vertical" || autoSize == "both";
		var autoSizeH:Boolean = autoSize == "horizontal" || autoSize == "both";
		if ( autoSizeH ) w = 10000;
		if ( autoSizeV ) h = 10000;
		dummy.width = w;
		dummy.height = h + 2;
//		dummy.autoSize = autoSize ;
		dummy.wordWrap = wordWrap;
		dummy.embedFonts = SystemUtil.isEmbeddedFont( format.font, format.bold, format.italic );
		dummy.defaultTextFormat = format;
		dummy.setTextFormat( format );
	}

	public static function stripSingleLine( text:String = "", p_dots:String = "…" ):String {
		var tf:TextField = dummy;
		if ( text ) tf.text = text;
		if ( tf.textWidth < tf.width ) return null;
		var idx:int = tf.getCharIndexAtPoint( tf.width - 5, tf.textHeight * 0.5 );
		if ( !text ) text = tf.text;
		do {
			idx--;
			tf.text = text.substr( 0, idx ) + p_dots;
		} while ( tf.textWidth > tf.width ) ;
		return tf.text;
	}


	private static function initFlashText():void {
		if ( dummy ) return;
		dummy = new TextField();
		dummy.multiline = true;
//		AppHelper.stage.addChild( dummy );
		dummy.border = true;
		dummy.borderColor = 0x0;
	}

	public static function ellipsis( text:String = "", breakWords:Boolean = true,
									 dots:String = "…" ):String {
		var tf:TextField = dummy;
		if ( !text ) text = tf.text;
		tf.text = StringUtils.trim( text );
		var str:String = text;
		var endWordIndex:Number;
		var multiline:Boolean = tf.maxScrollV > 1;//tf.multiline;
		if ( tf.maxScrollH > 0 || tf.maxScrollV > 1 ) {
			while ( str.length > 0 ) {
				if ( breakWords ) {
					str = str.substr( 0, str.length - 1 );
				} else {
					endWordIndex = Math.max( str.lastIndexOf( " " ), 0 );
					str = str.substr( 0, endWordIndex );
				}
				tf.text = StringUtils.trim( str ) + dots;
				trace( tf.maxScrollH )
				if ( (!multiline && tf.maxScrollH <= 0) || (multiline && tf.maxScrollV <= 1) ) {
					break;
				}
			}
			str = tf.text;
		}
		if ( str != text ) {
			return str;
		}
		return null;
	}
}