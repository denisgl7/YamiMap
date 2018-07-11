/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.starling.ui {
import starling.display.DisplayObjectContainer;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;
import starling.utils.Align;

public class UIFactory {

	public static var defaultFontSize:int = -1 ;// for bitmap fonts, or 16.
	public static var defaultFontColor:uint = 0xffffff ;
	public static var defaultFontFace:String = "Arial";

	public function UIFactory() {}

	public static function init():void {
	}

	public static function createLabel( doc:DisplayObjectContainer = null, text:String = null, fontFace:String = null,
										w:Number = -1, h:Number = -1, size:Number = -1,
										color:int = -1, autoSize:String = TextFieldAutoSize.NONE,
										align:String = Align.LEFT,
										leading:Number = 0, letterSpacing:Number = 0, debugSize:Boolean = false ):TextField {

		if ( !autoSize ) autoSize = TextFieldAutoSize.NONE;
		if ( !fontFace ) fontFace = defaultFontFace;
		if ( w == -1 && h == -1 ) {
			autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			w = 0;
			h = 0;
		}
		if ( w == -1 ) {
			autoSize = TextFieldAutoSize.HORIZONTAL;
			w = 0;
		}
		if ( h == -1 ) {
			autoSize = TextFieldAutoSize.VERTICAL;
			h = 0;
		}
		if( color < 0 ) color = defaultFontColor ;
		if( size < 0 ) size = defaultFontSize ;

		var format:TextFormat = new TextFormat( fontFace, size, color );
		format.kerning = false;
		format.leading = leading;
		format.letterSpacing = letterSpacing;
		format.horizontalAlign = align;
		format.verticalAlign = Align.TOP;

		if ( fontFace.toLowerCase().indexOf( "bold" ) > -1 ) {
			format.bold = true;
		}

		var tf:TextField = new TextField( w, h, text, format );

		tf.autoSize = autoSize;
		tf.touchable = false;
		if ( debugSize ) {
			tf.border = true;
		}
		if ( text && text.length < 20 ) {
			tf.batchable = true;
		}

		if ( doc ) {
			doc.addChild( tf );
		}
//		_map.push( tf );
		/*// use distance fonts by default.
		 if ( useDistanceFonts ) {
		 // check this can be "unique".
		 var ss:DistanceFieldStyle = new DistanceFieldStyle( 0.5, distanceSoftness );
		 //			ss.softness = distanceSoftness;
		 tf.STYLE = ss;
		 trace( "ok adding this shit!", ss, tf.STYLE is DistanceFieldStyle );
		 }*/
		return tf;
	}
}
}
