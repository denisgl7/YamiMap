/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/29/17.
 *
 */
package roipeker.starling {
import roipeker.utils.StringUtils;

import com.greensock.TweenLite;

import flash.events.Event;
import flash.geom.Rectangle;

import starling.display.BlendMode;

import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.textures.Texture;
import starling.utils.AssetManager;
import starling.utils.StringUtil;

public class MyAssets {
	public function MyAssets() {}

	public static var man:AssetManager;

	public static function init( assets:AssetManager ):void {
		man = assets;
	}

	public static function addQueue( url:String, id:String ):void {
		man.enqueueWithName( url, id );
	}

	public static function loadQueue( onComplete:Function ):void {
		man.loadQueue( function ( p:Number ):void {
			if ( p == 1 ) {
				if ( onComplete ) onComplete()
			}
		} )
	}

	public static function loadUrl( url:String, id:String, onComplete:Function ):void {
		addQueue( url, id );
		loadQueue( onComplete );
	}


	//===================================================================================================================================================
	//
	//      ------  special memory management.
	//
	//===================================================================================================================================================
	private static var _uniqueIdCache:int = 1;
	public static function get uniqueIdCache():String {
		return "img" + ( _uniqueIdCache++);
	}


	// keep a LOCAL REFERENCE of the images to LOAD.
	private static var _loadingQueueUrl:Object = {};
	private static var _loadingQueueIds:Object = {};
	private static var _errorCallbackByUrl:Object = {};
	private static var _pendingUnloads:Array = [];
	private static var _allLoads:Array = [];

	public static function loadImage( url:String, id:String, onComplete:Function, onError:Function = null ):void {
		// TODO: validate if this is the way to do it!!!!
		var tx:Texture = getTx( id );
		if ( onError ) _errorCallbackByUrl[url] = onError;
//		var f:File = FileUtils.TMP_FILE ;
//		f.url = url ;
//		log("loadImage:: id={0} - size={1} ",id,FileUtils.redeableBytes(f.size));
		if ( tx ) {
			onComplete();
			return;
		}
		_loadingQueueUrl[url] = id;
		_loadingQueueIds[id] = {url: url};
		man.enqueueWithName( url, id );
		man.loadQueue( function ( p:Number ):void {
			if ( p == 1 ) {
				// marked for delete.
				if ( _loadingQueueIds[id] && _loadingQueueIds[id].pendingUnload ) {
					man.removeTexture( id, true );
				}
				// marked to delete?
				delete _errorCallbackByUrl[url];
				delete _loadingQueueUrl[url];
				delete _loadingQueueIds[id];
				if ( onComplete ) onComplete();
			}
		} )
	}

	private static function onLoadError( event:Event, url:String ):void {
		trace( "load error for url:", url, "id:", _loadingQueueUrl[url] );
		if ( _errorCallbackByUrl[url] ) {
			_errorCallbackByUrl[url]();
			delete _errorCallbackByUrl[url];
		}
	}

	private static var _invalidatePurge:Boolean = false;
	public static var purgeUnloadsDelay:Number = 10;

	public static function unload( id:String ):void {
		// if its still loading or doesnt exists... put in the remove Queue.
		var vo:Object = _loadingQueueIds[id];
		if ( vo && vo.url ) {
			delete _errorCallbackByUrl[vo.url];
			delete _loadingQueueUrl[vo.url];
		}
		if ( vo || !man.getTexture( id ) ) {
//			trace("WTF?", _loadingQueueIds[id], id );
			if ( vo ) {
				vo.pendingUnload = true;
			}
//			trace(">>>> can't unload image :" + id + " is still loading or was disposed");
			_pendingUnloads.push( id );
			if ( !_invalidatePurge ) {
				log( "invalidatePurge in {0} secs.", purgeUnloadsDelay );
//				trace("invalidate purge, will run in " + purgeUnloadsDelay + "secs");
				_invalidatePurge = true;

				// TODO: use starling???
				TweenLite.killDelayedCallsTo( purgeUnloads );
				TweenLite.delayedCall( purgeUnloadsDelay, purgeUnloads );
			}
			// delay to execute the queue.
			return;
		}
//		trace(">>>> unload image :", id );
		man.removeTexture( id, true );
	}

	private static function purgeUnloads():void {
		_invalidatePurge = false;
		var len:int = _pendingUnloads.length;
		log( "purgeUnloads() num=" + len );
//		trace(">>>> purging " + len + " elements");
		for ( var i:int = 0; i < len; i++ ) {
			var id:String = _pendingUnloads[i];
//			trace(">>>> purging:" +  id + " exists?" + man.getTexture( id ) + " is loading?" + (_loadingQueueIds[id]!=null ));
			man.removeTexture( id, true );
		}
		_pendingUnloads.length = 0;
	}


	//===================================================================================================================================================
	//
	//      ------  retrieval
	//
	//===================================================================================================================================================

	public static var useLookupColorTextures:Boolean = false;

	public static function getColorQuad( color:uint, doc:DisplayObjectContainer = null, w:Number = 0,
										 h:Number = 0, opaqueBlendMode:Boolean=false ):Quad {
		if ( w <= 0 ) w = 1;
		if ( h <= 0 ) h = 1;
		var q:Quad = new Quad( w, h, color );
		if ( doc ) doc.addChild( q );
		if( opaqueBlendMode ) q.blendMode = BlendMode.NONE ;
		return q;
	}

	// requires at least c_fffff in memory/atlas.
	public static function getColorImage( color:uint, doc:DisplayObjectContainer = null, image:Image = null,
										  tw:Number = 0,
										  th:Number = 0 ):Image {
		var img:Image;
		if ( useLookupColorTextures ) {
			// 0x0 is always c_0 ... dont add extra 000000
			var cid:String = "";
			if ( color == 0x0 ) cid = "0";
			cid = color.toString( 16 );
			if ( !getTx( "c_" + cid ) ) {
				if ( cid.length < 6 ) cid = StringUtils.zeroPad( cid, 6 );
			}
			img = getImage( "c_" + cid, doc, image, false );
			if ( tw > 0 && th > 0 ) {
				img.width = tw;
				img.height = th;
			}
			return img;
		} else {
			img = getImage( "c_ffffff", doc, image, false );
			if ( image ) img.readjustSize();
			img.width = tw;
			img.height = th;
			if ( color != 0xFFFFFF ) img.color = color;
			return img;
		}
	}

	public static function getImage( id:String, doc:DisplayObjectContainer = null, image:Image = null,
									 center:Boolean = false, roundCenter:Boolean = false ):Image {
		var tx:Texture;
		if ( id ) {
			tx = getTx( id );
			if ( !tx ) log( "Texture " + id + " not found." );
		}

		if ( !image ) {
			image = new Image( tx );
		} else {
			image.texture = tx;
			image.readjustSize();
			image.scale = 1;///AppUtils.scale;
		}
		if ( center ) {
			image.alignPivot();
			if ( roundCenter ) {
				image.pivotX |= 0;
				image.pivotY |= 0;
			}
		}
		if ( doc ) doc.addChild( image );
		return image;
	}

	public static function getSprite( id:String, doc:DisplayObjectContainer = null ):Sprite {
		var spr:Sprite = new Sprite();
		spr.addChild( getImage( id ) );
		if ( doc )
			doc.addChild( spr );
		return spr;
	}

	public static function getJsonObject( id:String ):Object {
		return man.getObject( id );
	}

	public static function getTx( id:String ):Texture {
		return man.getTexture( id );
	}


	public static var RECT:Rectangle = new Rectangle();

	public static function getScale9Rect( image:Image, margin:int ):Rectangle {
		RECT.setTo( margin, margin, image.texture.width - margin * 2, image.texture.height - margin * 2 );
		return RECT;
	}

	public static function bindScale9( id:String, margin:int ):void {
		var tx:Texture = getTx( id );
		if ( !tx ) {
			error( "can't bind texture {0}, it doesnt exist.", id );
			return;
		}
		RECT.setTo( margin, margin, tx.width - margin * 2, tx.height - margin * 2 );
		trace("texture:", id, RECT );
		Image.bindScale9GridToTexture( tx, RECT.clone());
	}

	//===================================================================================================================================================
	//
	//      ------  logs
	//
	//===================================================================================================================================================
	public static var verbose:Boolean = true;
	private static const className:String = "Assets";

	private static function error( ...args ):void {
		var msg:String = args[0] is String && args[0].indexOf( "{" ) > -1 ? StringUtil.format.apply( null, args ) : args.join( " " );
		trace( "[" + className + "] ERROR=" + msg );
	}

	private static function log( ...args ):void {
		if ( !verbose ) return;
		var msg:String = args[0] is String && args[0].indexOf( "{" ) > -1 ? StringUtil.format.apply( null, args ) : args.join( " " );
		trace( "[" + className + "] " + msg );
	}

}
}
