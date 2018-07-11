/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/19/17.
 *
 */
package roipeker.starling {
import roipeker.callbacks.Callback;
import roipeker.helpers.AppHelper;

import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.system.Capabilities;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.utils.ByteArray;
import flash.utils.setTimeout;

import starling.core.Starling;
import starling.utils.AssetManager;
import starling.utils.StringUtil;

public class StarlingFactory {

	public static var assets:AssetManager;

	private var _mainClass:Class;
	private var _starling:Starling;
	private var _scaleFactor:Number = 1;
	private var useMipmaps:Boolean = false;

	public var assetsToLoad:Array = [];
	public var onComplete:Function;
	private var _splash:Loader;

	private var centerLoadingScreen:Boolean = true;
	private var _stats:Boolean;

	public var verbose:Boolean = true ;

	public function StarlingFactory(mainClass:Class ) {
		_mainClass = mainClass;
	}

	public function initStarling():void {
		Starling.multitouchEnabled = true;
		_starling = new Starling( _mainClass, AppHelper.stage );
		_starling.skipUnchangedFrames = true;
		_starling.enableErrorChecking = false;
		_starling.supportHighResolutions = true;
		_starling.addEventListener( "rootCreated", rootCreatedHandler );
		_starling.start();
		_starling.showStats = _stats;
		AppHelper.appActivated.add( onAppActivation );
	}

	private function onAppActivation( active:Boolean ):void {
		if ( AppHelper.isMobile ) {
			active ? _starling.start() : _starling.stop( true );
		}
	}

	public function initIOSSplash():void {
		if ( !AppHelper.isIOS ) return;
		var imgH:int = Screener.isLandscape ? AppHelper.stage.fullScreenWidth : AppHelper.stage.fullScreenHeight;
		var isTablet:Boolean = Screener.isTablet;
		var orientation:String = Screener.isLandscape ? "-Landscape" : "-Portrait";
		var screenType:String = "";
		var scaleFactor:String = "";
		var deviceType:String = isTablet ? "~ipad" : "~iphone";

		switch ( imgH ) {
			case 2732:
			case 2224:
				deviceType = "";
				break;
			case 2208:
				screenType = "-414w-736h";
				break;
			case 1334:
			case 2001:
				screenType = "-375w-667h";
				break;
			case 1136:
				screenType = "-568h";
				break;
			case 960:
				screenType = "";
				break;
		}

		if ( !Screener.isLandscape && !isTablet )
			orientation = "";

		var scale:Number = Screener.densityScale;
		if ( scale > 1 ) {
			if ( imgH <= 2001 ) scale = 2;
			scaleFactor = StringUtil.format( "@{0}x", scale );
		}

		var filepath:String = StringUtil.format( "Default{0}{1}{2}{3}.png", orientation, screenType, scaleFactor, deviceType );
		if ( AppHelper.isADL ) {
			filepath = "splash/" + filepath;
		}
		centerLoadingScreen = false;
		if( verbose ) trace( 'loading ios splash:', filepath );
		initLoadingScreen( filepath );
	}

	public function initLoadingScreen( filePath:String ):void {

		if( verbose ) trace( 'has starling..', _starling );
		if ( !_starling ) return;

		// show logo?
		if ( filePath.indexOf( '{0}x' ) > -1 ) {
			filePath = StringUtil.format( filePath, _scaleFactor );
		}
		var bgFile:File = AppHelper.appDir.resolvePath( filePath );
		var bytes:ByteArray = new ByteArray();
		var stream:FileStream = new FileStream();
		stream.open( bgFile, FileMode.READ );
		stream.readBytes( bytes, 0, stream.bytesAvailable );
		stream.close();

		_splash = new Loader();

		var ctx:LoaderContext = new LoaderContext();
		ctx.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
		_splash.loadBytes( bytes, ctx );
		// if its iphone 7, validate if its 3, or 2 (zoomed).
//		AppHelper.stage.fullScreenWidth

		_splash.scaleX = 1.0 / _scaleFactor;
		_splash.scaleY = 1.0 / _scaleFactor;
		_starling.nativeOverlay.addChild( _splash );
		_splash.contentLoaderInfo.addEventListener( "complete",
				function ( e:Object ):void {
					(_splash.content as Bitmap).smoothing = true;
					onStageResize( null );
				} );

		AppHelper.stage.addEventListener( Event.RESIZE, onStageResize );
	}

	private function onStageResize( e:Event ):void {
		if ( _splash ) {
			if ( centerLoadingScreen ) {
				var z:Number = Screener.zoomADL;
				_splash.x = AppHelper.stage.stageWidth / z - _splash.width >> 1;
				_splash.y = AppHelper.stage.stageHeight / z - _splash.height >> 1;
			}
		}
	}

	private function removeLoadingScreen():void {
		if ( _splash ) {
			_splash.unloadAndStop();
			_splash.parent.removeChild( _splash );
			_splash = null;
		}
		AppHelper.stage.removeEventListener( Event.RESIZE, onStageResize );
	}

	private var _onLoadProgress:Callback ;
	public function get onLoadProgress():Callback {
		if(!_onLoadProgress) _onLoadProgress = new Callback();
		return _onLoadProgress ;
	}
	public function loadAssets():void {
		if ( !assets ) {
			assets = new AssetManager( _scaleFactor, useMipmaps );
			assets.verbose = Capabilities.isDebugger;
		}
		if( verbose ) trace( 'Loading assets:', assetsToLoad );
		assets.enqueue( assetsToLoad );
		assets.loadQueue( function ( ratio:Number ):void {
			if( _onLoadProgress ) _onLoadProgress.dispatch( ratio );
//			trace('loading assets...', ratio)
//			_progressBar.ratio = ratio;
			if ( ratio == 1 ) {
				AppHelper.gc();
				onLoadComplete();
			}
		} );
	}

	public function addAsset( asset:* ):void {
		if ( asset is String ) {
			var url:String = String( asset );
			if ( url.indexOf( '://' ) == -1 ) {
				// look for app files.
				if ( url.indexOf( '{0}' ) > -1 ) {
					url = StringUtil.format( url, _scaleFactor );
				}
				assetsToLoad.push( AppHelper.appDir.resolvePath( url ) );
			} else {
				assetsToLoad.push( url );
			}
		} else {
			assetsToLoad.push( asset );
		}
	}

	public var splashScreenDelay:Number = 100;
	private var _rootCreated:Callback;

	private function onLoadComplete():void {
		setTimeout( removeLoadingScreen, splashScreenDelay );
		if ( _starling.root.hasOwnProperty( 'run' ) ) {
			var callback:Function = _starling.root["run"] as Function;
			var numArgs:int = callback.length;
			if ( numArgs == 0 ) callback();
			else if ( numArgs == 1 ) callback( assets );
		}
		if ( onComplete ) onComplete();
	}

	private function rootCreatedHandler():void {
		if ( _starling.root.hasOwnProperty( 'rootCreated' ) ) {
			_starling.root['rootCreated']();
		}
		if( _rootCreated ) {
			_rootCreated.dispatch();
			_rootCreated.dispose();
			_rootCreated = null ;
		}

		if ( Screener.isInited && Screener.starlingResizeMethod ) {
//			Screener.resizeStarling();
			Screener.starlingResizeMethod();
		}
//		AppHelper.screen.invalidateStageSize();
		if( assetsToLoad.length ){
            loadAssets();
        } else {
            onLoadComplete();
        }
	}

	public function get scaleFactor():Number {
		return _scaleFactor;
	}

	public function set scaleFactor( value:Number ):void {
		_scaleFactor = value;
		if( verbose ) trace( "using asset scale=", value );
	}

	public function get stats():Boolean {
		return _stats;
	}

	public function set stats( value:Boolean ):void {
		_stats = value;
		if ( _starling ) _starling.showStats = _stats;
	}

	public function get rootCreated():Callback {
		if( !_rootCreated ) _rootCreated = new Callback();
		return _rootCreated;
	}
}
}
