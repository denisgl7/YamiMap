/**
 *
 * Created by Rodrigo Lopez [blnk™] on 1/24/17.
 *
 */
package roipeker.starling.display {
import roipeker.starling.Screener;
import roipeker.utils.Pooler;

import com.greensock.TweenLite;
import com.greensock.TweenMax;
import com.greensock.easing.Linear;
import com.greensock.easing.Quad;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.StageQuality;
import flash.geom.Rectangle;

import starling.display.Canvas;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.geom.Polygon;
import starling.textures.RenderTexture;
import starling.textures.Texture;
import starling.utils.AssetManager;
import starling.utils.StringUtil;

/**
 * PreloaderSpinner is a useful class to display a preloader.
 *
 * Sample:

 // create a texture first
 PreloaderSpinner.createTexture( "red", 24, 2, 0xff0000 );

 var spinner:PreloaderSpinner = PreloaderSpinner.get( "red", this );
 spinner.move( 100, 100 );
 spinner.animate();
 setTimeout(function():void {
	PreloaderSpinner.put(spinner);
	// or direct call.
	// spinner.returnPool() ;
 }, 1000 );



 // option 2 EXTREME render texture.
 var spinner:PreloaderSpinner = PreloaderSpinner.get( "WHITE", this );
 spinner.animate();
 spinner.makeKeyRT( "WHITE" );
 spinner.visible = false;

 stage.starling.showStats = true;
 stage.starling.showStatsAt( "left", "top", 2 );
 var sep:Number = spinner.radius * 2 + 2;
 var batch:MeshBatch ;

 stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent){
			if(e.keyCode==Keyboard.F){
				Screener.toggleFullscreen();
			}
		});
 stage.addEventListener(Event.RESIZE, function(){
			recreateBatch();
			trace("resizing stage:", stage.stageWidth );
		}) ;
 recreateBatch();
 function recreateBatch():void {
			if( batch ){
				TweenMax.killTweensOf( batch );
				batch.clear();
				batch.dispose();
				batch = null ;
			}
			var total:uint = (stage.stageWidth / sep ) * (stage.stageHeight / sep  )  ;
			if( total > 12000) total = 12000 ;

			var cols:int = (stage.stageWidth / sep ) ;
			trace( "rendering spinners:" + total );
			batch = new MeshBatch();
			var r:Number = .000;
			var a:Number = .000;
			for ( var i:int = 0; i < total; i++ ) {
				var img:Image = PreloaderSpinner.getRTImageByKey( "WHITE" );
				img.alignPivot();
				img.rotation = r ;
				r += .005 ;
				a += .0001 ;
				img.x = img.pivotX + (i % cols ) * sep;
				img.y = img.pivotY + (i / cols | 0 ) * sep;
//				batch.addMesh( img, null, 0.25 + Math.random() );
				batch.addMesh( img, null, .2 + (Math.cos(r)+1) * .5 * .8 );
			}
			batch.alignPivot();
			batch.x = stage.stageWidth>>1;
			batch.y = stage.stageHeight>>1;
			batch.touchable = false ;
//			batch.setRequiresRedraw();
			addChild( batch );
			TweenMax.to( batch, 6, { scale: 1.5, yoyo: true, repeat: -1, ease: Linear.easeNone} );
		}


 */

public class PreloaderSpinner extends Sprite {

	private static var _shape:Shape;
	private static var _textureMap:Object = {};

	public static function createTexture( id:String, radius:int, thickness:Number = 4, color:uint = 0xffffff ):Texture {
		if ( !_shape ) _shape = new Shape();
		_shape.graphics.clear();
		_shape.graphics.lineStyle( thickness, color, 1 );
		_shape.graphics.drawCircle( radius, radius, radius - thickness / 2 );
		var oldQuality:String = Screener.stage.quality ;
		Screener.stage.quality = StageQuality.BEST ;
		var rect:Rectangle = _shape.getBounds( _shape );
		var bd:BitmapData = new BitmapData( rect.width, rect.height, true, 0x0 );
		bd.drawWithQuality( _shape, null, null, null, null, false, StageQuality.BEST );
		var tx:Texture = Texture.fromBitmapData( bd, false, false, Screener.assetScale );
		if ( assetsManager ) {
			assetsManager.addTexture( id, tx );
		}
		Screener.stage.quality = oldQuality ;
		_textureMap[id] = tx;
		return _textureMap[id];
	}

	public static function getTexture( textureId:String ):Texture {
		return _textureMap[textureId];
	}

	//===================================================================================================================================================
	//
	//      ------  POOL
	//
	//===================================================================================================================================================
	private static var _pool:Pooler;

	public static function get( textureId:String = null, doc:Sprite = null ):PreloaderSpinner {
		if ( !_pool )
			_pool = Pooler.build( PreloaderSpinner, null, "reset" );
		var spin:PreloaderSpinner = _pool.get(true) as PreloaderSpinner;
		if ( textureId ) spin.textureId = textureId;
		if ( doc ) doc.addChild( spin );
		return spin;
	}

	public static function put( spinner:PreloaderSpinner ):void {
		spinner.returnPool();
	}

	public function returnPool():void {
		if ( !_pool.owns( this ) ) {
			trace( 'PreloaderSpinner::returnPool() Only instances requested by PreloaderSpinner::get() are elegible' );
			return;
		}
		reset();
		_pool.put( this );
//		reset();
		if ( parent ) parent.removeChild( this );
	}


	public static var polygonSides:uint = 4; // min 3
	public static var assetsManager:AssetManager;

	public static var animationAutoPercentDuration:Number = 1.8;
	public static var animationRotationDuration:Number = 1.8 * 1.5;

	public static const autoPercentMin:Number = (Math.PI * 0.2) / (Math.PI * 2);
	public static const autoPercentMax:Number = (Math.PI * 1.6) / (Math.PI * 2);

	private static const PI2:Number = Math.PI * 2;

	private var _radius:Number;

	public var startAngle:Number = -Math.PI / 2;

	//modifies  animationAutoPercentDuration/animationRotationDuration
	public var animationSpeedRatio:Number = 1;
	public var dispatchUpdate:Boolean;

	private var _container:Sprite;
	private var _img:Image;
	private var _canvas:Canvas;
	private var _poly:Polygon;
	private var _percent:Number = 0;

	private var _running:Boolean;
	private var _textureId:String;

	private var _keyRT:RenderTexture;
	private static var _keys:Object = {};

	/**
	 * constructor.
	 * @param doc
	 */
	public function PreloaderSpinner(doc:Sprite = null ) {
		if ( doc ) doc.addChild( this );
		init();
	}

	private function init():void {
		_container = new Sprite();
		_img = new Image( null );
		_canvas = new Canvas();
		_img.mask = _canvas;
		_container.addChild( _img );
		_container.addChild( _canvas );
		addChild( _container );
		_poly = new Polygon();
	}

	public function animate():void {
		_running = true;
		autoAnimatePercent();
		rotationAnimation();
	}

	public function stop():void {
		_running = false;
		TweenLite.killTweensOf( _canvas );
		TweenLite.killTweensOf( _container );
		TweenLite.killTweensOf( this, true, {percent: true} );
	}

	public function reset():void {
		stop();
		_percent = _container.rotation = _canvas.rotation = 0;
		drawPoly();
		if ( _keyRT ) {
			_keyRT.dispose();
			_keyRT = null;
		}
	}

	private function autoAnimatePercent():void {
		var val:Number = _percent > autoPercentMin ? autoPercentMin : autoPercentMax;
		var rot:Number = _canvas.rotation + (val == autoPercentMin ? Math.PI * 2 : Math.PI );
		TweenLite.to( this, animationAutoPercentDuration * animationSpeedRatio, {
			percent: val,
			ease: Quad.easeInOut
		} );
		TweenLite.to( _canvas, animationAutoPercentDuration * animationSpeedRatio, {
			rotation: rot,
			onComplete: autoAnimatePercent,
			ease: Quad.easeInOut
		} );
	}

	private function rotationAnimation():void {
		TweenMax.to( _container, animationRotationDuration * animationSpeedRatio, {
			rotation: String( Math.PI * 2 ),
			repeat: -1,
			ease: Linear.easeOut
		} );
	}

	private function drawPoly():void {
		if ( _percent == 0 ) {
			_poly.numVertices = 0;
			_img.mask = null;
			_container.visible = false;
		} else {
			_img.mask = _canvas;
			_container.visible = true;
			updatePoly( _percent, _radius, 0, 0, startAngle );
		}
		_canvas.clear();
		_canvas.beginFill( 0x00ff00 );
		_canvas.drawPolygon( _poly );
		_canvas.endFill();
		if ( dispatchUpdate ) {
			dispatchEventWith( Event.UPDATE );
		}
		if ( _keyRT ) {
			_keyRT.clear();
			if ( _percent > 0 ) _keyRT.draw( this );
		}
	}

	private function updatePoly( p:Number, radius:Number, x:int, y:int, rot:Number ):void {
		_poly.numVertices = 0;
		_poly.addVertices( x, y );
		radius /= Math.cos( 1 / polygonSides * Math.PI );
		var sidesToDraw:int = p * polygonSides;
		var angle:Number;
		var cos:Function = Math.cos;
		var sin:Function = Math.sin;
		for ( var i:int = 0; i <= sidesToDraw; i++ ) {
			angle = i / polygonSides * PI2 + rot;
			_poly.addVertices( x + cos( angle ) * radius, y + sin( angle ) * radius );
		}
		if ( p * polygonSides != sidesToDraw ) {
			angle = p * PI2 + rot;
			_poly.addVertices( x + cos( angle ) * radius, y + sin( angle ) * radius );
		}
	}

	public function set textureId( id:String ):void {
		_textureId = id;
		if ( assetsManager ) {
			texture = assetsManager.getTexture( id );
		} else {
			texture = _textureMap[id] as Texture;
		}
	}

	public function set texture( tex:Texture ):void {
		if ( !tex ) {
			trace( "[ PreloaderSpinner ] ERROR: texture can't be null" );
			return;
		}
		_img.texture = tex;
		_img.readjustSize();
		_radius = tex.width / 2;
		_container.pivotX = _container.pivotY = _container.y = _container.x = _radius;
		_canvas.x = _canvas.y = _radius;
		invalidatePercent();
	}

	private function invalidatePercent():void {
		drawPoly();
	}

	public function get percent():Number {return _percent;}

	public function set percent( value:Number ):void {
		if ( _percent == value || _radius == 0 ) return;
		if ( value < 0 ) value = 0;
		else if ( value > 1 ) value = 1;
		_percent = value;
		drawPoly();
	}

	public function get color():uint {return _img.color}

	public function set color( value:uint ):void {
		_img.color = value;
	}

	public function get radius():Number {
		return _radius;
	}

	public function get running():Boolean {
		return _running;
	}

	//============================
	// RenderTexture optimization
	//============================

	public function useRenderTexture( flag:Boolean ):void {
		if ( flag ) {
			if ( _keyRT ) {
				_keyRT.dispose();
				_keyRT = null;
			}
			_keyRT = new RenderTexture( _radius * 2, _radius * 2, true, 1 );
			_keyRT.clear();
		} else {
			if ( _keyRT ) {
				_keyRT.dispose();
				_keyRT = null;
			}
		}
	}

	public function makeKeyRT( id:String ):void {
		// take the object name
		_keys[id] = this;
		if ( _keyRT ) {
			_keyRT.dispose();
			_keyRT = null;
		}
		_keyRT = new RenderTexture( _radius * 2, _radius * 2, true, 1 );
		_keyRT.clear();
	}

	public static function getRTImageByKey( id:String, doc:Sprite=null ):Image {
		var instance:PreloaderSpinner = _keys[id];
		if ( !instance ) {
			trace( StringUtil.format( "[ PreloaderSpinner ] ::getKeyImage id={0} not defined.", id ) );
			return new Image( null );
		}
		var img:Image = new Image( instance._keyRT );
		if( doc ) doc.addChild(img);
		return img ;
	}

	public function get renderTexture():RenderTexture {
		return _keyRT;
	}

	//===================================================================================================================================================
	//
	//      ------  utility
	//
	//===================================================================================================================================================
	public function move( tx:Number, ty:Number ):void {
		x = tx;
		y = ty;
	}

}
}
