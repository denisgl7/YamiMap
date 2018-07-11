/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.starling {

import roipeker.helpers.UIHelper;

import flash.geom.Matrix;

import flash.geom.Point;
import flash.geom.Rectangle;

import starling.core.Starling;
import starling.display.Canvas;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.utils.MatrixUtil;
import starling.utils.Pool;

public class StarlingUtils {
	public static function drawRoundRect( canvas:Canvas, x:int, y:int, w:int, h:int, radius:int ):Canvas {

		canvas.drawCircle( x + radius, y + radius, radius );
		canvas.drawCircle( x + radius, y + h - radius, radius );
		canvas.drawCircle( x + w - radius, y + radius, radius );
		canvas.drawCircle( x + w - radius, y + h - radius, radius );

		canvas.drawRectangle( x, y + radius, radius, h - radius * 2 );
		canvas.drawRectangle( x + w - radius, y + radius, radius, h - radius * 2 );
		canvas.drawRectangle( x + radius, y, w - radius * 2, h );
		return canvas;
	}

    public static function drawCircle( radius:int, color:uint=0xff0000, canvas:Canvas=null, x:int=0, y:int=0 ):Canvas {
        if(!canvas) canvas = new Canvas();
        canvas.beginFill( color );
        canvas.drawCircle( x + radius, y + radius, radius );
        canvas.endFill();
        return canvas;
    }

	public static function constrainImageSize( img:Image, maxW:int, maxH:int, fillMask:Boolean = false,
											   reposition:Boolean = true, useTextureSize:Boolean = true ):void {
		if ( !img.texture ) return;
		if( useTextureSize ){
			var tw:int = img.texture.width;
			var th:int = img.texture.height;
		} else {
			tw = img.width ;
			th = img.height ;
		}
		var r1:Number = tw / th;
		var r2:Number = maxW / maxH;
		var condition:Boolean = fillMask ? (r1 < r2 ) : (r1 > r2 );
		if ( condition ) {
			img.width = maxW;
			img.height = th * (maxW / tw);
//			img.scaleY = img.scaleX;
		} else {
			img.height = maxH;
			img.width = tw * (maxH / th);
//			img.scaleX = img.scaleY;
		}
		if ( reposition ) {
			img.x = maxW - img.width >> 1;
			img.y = maxH - img.height >> 1;
		}
	}


	public static function proportionalWidth( obj:DisplayObject, w:Number, useDesignDPI:Boolean = false ):void {
		obj.width = useDesignDPI ? Screener.designScale( w ) : w;
		obj.scaleY = obj.scaleX;
	}

	public static function proportionalHeight( obj:DisplayObject, h:Number, useDesignDPI:Boolean = false ):void {
		obj.height = useDesignDPI ? Screener.designScale( h ) : h;
		obj.scaleX = obj.scaleY ;
	}

	public static function mouseHit( hit:DisplayObject, stageX:int = -1, stageY:int = -1 ):Boolean {
		var viewport:Rectangle = Starling.current.viewPort;
		if ( stageX < 0 ) stageX = Starling.current.nativeOverlay.mouseX;
		if ( stageY < 0 ) stageY = Starling.current.nativeOverlay.mouseY;
		var pos:Point = Pool.getPoint();
		pos.x = (stageX - viewport.x) / Starling.contentScaleFactor;
		pos.y = (stageY - viewport.y) / Starling.contentScaleFactor;
		hit.globalToLocal( pos, pos );
		var flag:Boolean = hit.hitTest( pos );
		Pool.putPoint( pos );
		return flag;
	}


	// get object coordinates for stage.
	public static function getStagePosition( obj:DisplayObject, rect:Rectangle ):Rectangle {
		if ( !obj.stage ) return rect;
		if ( !rect ) rect = UIHelper.rect;
		var starlingObj:DisplayObject;
		starlingObj = obj as DisplayObject;
		starlingObj.getTransformationMatrix( starlingObj.stage, UIHelper.matrix );
		MatrixUtil.transformCoords( UIHelper.matrix, 0, 0, UIHelper.point );
		starlingObj.getBounds( starlingObj.parent, rect );
		rect.x = UIHelper.point.x;
		rect.y = UIHelper.point.y;
		var scale:Number = Starling.current.nativeOverlay.scaleX;
		rect.x *= scale;
		rect.y *= scale;
		rect.width *= scale;
		rect.height *= scale;
		return rect;
	}

	public static function getDisplayObjectDepth( obj:DisplayObject ):int {
		if ( !obj.stage ) {
			return -1;
		}
		var count:int = 0;
		while ( obj.parent ) {
			obj = obj.parent;
			count++;
		}
		return count;
	}

	public static function matrixToScaleX( m:Matrix ):Number {
		return Math.sqrt( m.a * m.a + m.b * m.b );
	}

	public static function matrixToScaleY( m:Matrix ):Number {
		return Math.sqrt( m.c * m.c + m.d * m.d );
	}

}
}
