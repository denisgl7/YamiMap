/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/3/17.
 *
 */
package roipeker.starling {
import roipeker.helpers.AppHelper;
import roipeker.helpers.IOSScreenHelper;
import roipeker.helpers.UIHelper;
import roipeker.utils.MathUtils;

import flash.display.Stage;
import flash.display.StageDisplayState;
import flash.display.StageOrientation;
import flash.events.Event;
import flash.events.StageOrientationEvent;
import flash.geom.Rectangle;
import flash.system.Capabilities;

import starling.core.Starling;
import starling.utils.RectangleUtil;
import starling.utils.ScaleMode;
import starling.utils.StringUtil;

public class Screener {

	private static var _availableAssetScales:Array;
	private static var _stage:Stage;

	// helper to get screen ratios.
	public static var designResolutionX:Number = 1 ;
	public static var designResolutionY:Number = 1 ;

	public static var screenW:Number;
	public static var screenH:Number;
	private static var appW:Number;
	private static var appH:Number;
	private static var screenDPI:int;

	// special to resize ADL screen.
	private static var _zoomADL:Number = 1;


	private static var _assetScale:Number = 1;
	private static var _stageWidth:Number;
	private static var _stageHeight:Number;
	private static var _viewport:Rectangle = new Rectangle();

	// mobile stuffs.
	public static var minInchesTablet:Number = 6;

	private static var iosDownsamplingScreenFactory:Number = 1;
	private static var _screenInchesX:Number = 0;
	private static var _screenInchesY:Number = 0;
	private static var _screenInches:Number = 0;
	private static var _dpiScale:Number;
	private static var _densityScale:Number;
	private static var _isTablet:Boolean;
	private static var _zoomingADL:Boolean;

	// 160 mobile, 72 desktop
	private static var _baseScreenDPI:Number;

	public static var starlingResizeMethod:Function;

	private static var _designDPI:Number;
	private static var _appPPIScale:Number;
	private static var _lastADLStageW:int;
	private static var _lastADLStageH:int;


	public function Screener() {
	}

	public static function get isInited():Boolean {
		return _stage != null;
	}

	public static function init( assetScales:Array,
								 sw:int = 0, sh:int = 0, dpi:int = 0 ):void {
		_stage = AppHelper.stage;

		// desktop works 1:1
		if ( !assetScales || !assetScales.length ) assetScales = [1];

		// based on stage::contentScaleFactor.
		_baseScreenDPI = AppHelper.isMobile ? 160 : 72;

		// dpi is irrelevant on desktop.
		_availableAssetScales = assetScales;

		screenW = _stage.fullScreenWidth;
		screenH = _stage.fullScreenHeight;
//		if ( sw == 0 ) sw = ;
//		if ( sh == 0 ) sh = _stage.fullScreenHeight;
		if ( dpi == 0 ) dpi = Capabilities.screenDPI;

		// in mobile we use this to calculate the dpiScale based on resolution.
		appW = sw;
		appH = sh;

        trace("FPI OS" , dpi );
		if ( dpi == 72 && AppHelper.isDesktop ) {
			// is it a mac, on desktop reconfigure the dpi based on the resolution.
			dpi *= _stage.contentsScaleFactor;
		}

		sw = screenW;
		sh = screenH;

		screenDPI = dpi;

		if ( !AppHelper.isDesktop ) {
			if ( AppHelper.isIOS ) {
				IOSScreenHelper.init();
				// check if its iphone6+ or 7+, downsampling. (if display zoom is enabled) or phones that allows
				// ZOOM or STANDARD views. (changes resolution)
				// 1125x2001
				// @check https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
				var portraitW:int = _stage.fullScreenWidth < _stage.fullScreenHeight ? _stage.fullScreenWidth : _stage.fullScreenHeight;
				if ( IOSScreenHelper.isIphonePlus || (AppHelper.isADL && screenDPI == 401 && ( portraitW == 1125 || portraitW == 1242 )) ) {
					iosDownsamplingScreenFactory = 1080 / portraitW; // 0.8695652174 = 1.15
					sw *= iosDownsamplingScreenFactory;
					sh *= iosDownsamplingScreenFactory;
					log( 'iphone 6+/7+ detected!' );
				} else if ( IOSScreenHelper.isIpadMini ) {
					// adjust for the ipad mini retina
					// @check https://forum.starling-framework.org/topic/capabilitiesscreendpi-giving-wrong-values
					screenDPI = 326;
				}
			}
			_screenInchesX = sw / screenDPI;
			_screenInchesY = sh / screenDPI;
			_screenInches = MathUtils.roundToPrecision( Math.sqrt( _screenInchesX * _screenInchesX + _screenInchesY * _screenInchesY ), 1 );
			_isTablet = _screenInches >= minInchesTablet;
			log( "MOBILE screenInches={0}, isTablet={1} inchesX={2}, inchesY={3}", _screenInches, _isTablet, _screenInchesX, _screenInchesY );
		}
		log( "appW={0}, appH={1}, screenDPI={2}, contentScaleFactor={7}, fullscreenW={3}, fullscreenH={4}, _os={5}, _version={6}", appW, appH, screenDPI, _stage.fullScreenWidth, _stage.fullScreenHeight, Capabilities.os, Capabilities.version, _stage.contentsScaleFactor );
		_stage.addEventListener( Event.RESIZE, onNativeStageResize, false, 2 );
	}

	private static function onNativeStageResize( event:Event ):void {
		if( AppHelper.isADL ) {
			// detect if we are shifting the orientation.
			if ( _zoomingADL ) {
				// prevent starling from listen stage resize.
				event.stopImmediatePropagation();
				return;
			} else {
				// validate if we are rotating the screen...
				if( !_changingOrientation ){
					if( _lastADLStageW != _stage.stageWidth || _lastADLStageH != _stage.stageHeight ){
						// we have an issue
						event.stopImmediatePropagation();
						log("Wrong stage dimensions, retry > last stage={0}x{1}, current stage={0}x{1}", _lastADLStageW, _lastADLStageH, _stage.stageWidth, _stage.stageHeight);
						handleStageOrientationChange(null);
						return ;
					}
				}
			}
		}
		log( "native stage resize w={0}, h={1}", _stage.stageWidth, _stage.stageHeight );
		if ( starlingResizeMethod ) {
			starlingResizeMethod();
		}
	}

	// FEATHERS way.
	public static function calculateDensity():void {
		// valid for mobile...
		_dpiScale = screenDPI / 160;
		var screenDensity:Number = screenDPI;
		if ( AppHelper.isIOS && isTablet ) {
			// compensate fix for ipad mini retina dpi
			if ( IOSScreenHelper.isIpadMini ) screenDensity = 264;
			screenDensity *= 1.23484848484848;
		}
		_densityScale = FeathersDensityResolver.getBucketScale( screenDensity );
		if ( AppHelper.isDesktop ) {
			_assetScale = _stage.contentsScaleFactor;
		} else {
			selectMatchingAssetScale();
		}
		starlingResizeMethod = resizeStageFluid;
		log( "dpiScale={0}, densityScale={1}, assetScale={2}", _dpiScale, _densityScale, _assetScale );
//		UIHelper.dly( starlingResizeMethod, true );
	}

	private static function selectMatchingAssetScale():void {
		_availableAssetScales.sort( Array.NUMERIC | Array.DESCENDING );
		_assetScale = _availableAssetScales[0];
		for ( var i:int = 0; i < _availableAssetScales.length; ++i )
			if ( _availableAssetScales[i] >= _densityScale ) _assetScale = _availableAssetScales[i];
	}

	// --- stage resize -----

	public static function resizeStageLetterbox():void {
		_stageWidth = appW;
		_stageHeight = appH;
		RectangleUtil.fit(
				new Rectangle( 0, 0, _stageWidth, _stageHeight ),
				new Rectangle( 0, 0, _stage.stageWidth, _stage.stageHeight ),
				ScaleMode.SHOW_ALL, false, _viewport );
		resizeStarling();
	}

	public static function resizeStageStretch():void {
		_stageWidth = _stage.stageWidth * _densityScale;
		_stageHeight = _stage.stageHeight * _densityScale;
		_viewport.setTo( 0, 0, _stage.stageWidth, _stage.stageHeight );
		resizeStarling();
		/*var starling:Starling = Starling.current;
		 var v:Rectangle = starling.viewPort;
		 var s:Number = stage.contentsScaleFactor;
		 v.setTo( 0, 0, stage.stageWidth, stage.stageHeight );
		 starling.stage.stageWidth = v.width * s;
		 starling.stage.stageHeight = v.height * s;
		 //		trace("AppUtil::resizeStarlingViewport() viewport=" + v + " starling stage=" + starling.stage.stageWidth + "x" + starling.stage.stageHeight + "");
		 Starling.current.viewPort = v;*/
	}

	public static function resizeStageFluid():void {
		var needsDivide:Boolean = int( _densityScale ) != _densityScale;
        trace('fluid resuze', _densityScale );
		_stageWidth = int( _stage.stageWidth / _densityScale * _zoomADL ) ;
		_stageHeight = int( _stage.stageHeight / _densityScale * _zoomADL );
		if ( needsDivide ) {
			_stageWidth = MathUtils.roundToNearest( _stageWidth, 2 );
			_stageHeight = MathUtils.roundToNearest( _stageHeight, 2 );
		}
		_viewport.setTo( 0, 0, _stageWidth * _densityScale / _zoomADL, _stageHeight * _densityScale / _zoomADL );
		resizeStarling();
	}

	public static function resizeStarling():void {
		var starling:Starling = Starling.current;
		log( "starling resize: stageWidth={0}, stageHeight={1}, viewport={2}", _stageWidth, _stageHeight, _viewport );
		if ( starling ) {
			starling.stage.stageWidth = _stageWidth;
			starling.stage.stageHeight = _stageHeight;
			try {
				starling.viewPort = _viewport;
			} catch ( e:Error ) {}
			// UPDATE: not needed as we stop the propagation of stage.resize
			// important if we are using ADL zoom factor.
//			starling.stage.dispatchEventWith( "customResize" );
		}
	}


	//===================================================================================================================================================
	//
	//      ------  ADL ZOOM
	//
	//===================================================================================================================================================

	public static function zoomADLWindow( factor:Number ):void {
		if ( !AppHelper.isADL ) return;

		// in desktop only works if we have an appW/appH defined?
        trace('asdfasdfasdf', appW, appH);
		if ( AppHelper.isDesktop && (appW == 0 || appH == 0 ) ) return;
trace('asdfasdfasdf');
		_zoomADL = factor;
		log( 'zoom ADL={0}', _zoomADL );

		// Stage resize emulation ONLY WORKS WHEN fullscreen = false;
		if ( fullscreen ) {
			fullscreen = false;
		}
		trace( "orientation    ", _stage.orientation );
		if ( !AppHelper.isDesktop ) {
			_stage.addEventListener( StageOrientationEvent.ORIENTATION_CHANGING, handleStageOrientationChange, true,0 );
			_stage.addEventListener( StageOrientationEvent.ORIENTATION_CHANGE, handleStageOrientationChange, true, 0 );
			// we have an issue in this project, dunno why, tiny delay required...
//			UIHelper.dly(resizeADLWindow, false, screenW, screenH );
//			UIHelper.dly( handleStageOrientationChange, false , null);
			resizeADLWindow( screenW, screenH );
		} else {
			resizeADLWindow( appW, appH );
		}
	}

	private static var _lastADLOrientation:String ;
	private static function handleStageOrientationChange( event:StageOrientationEvent ):void {
		if( event ) trace("orientation change!");
		if ( !AppHelper.isADL ) {
			return;
		}
		var invertedOrientation:Boolean = false;
		if ( event ) {
			event.stopImmediatePropagation();
			event.preventDefault();
			invertedOrientation = event.afterOrientation.indexOf( "rotated" ) > -1;
		} else {
			invertedOrientation = _stage.orientation.indexOf( "rotated" ) > -1;
		}
		_lastADLOrientation = _stage.orientation ;
		trace('handleStageOrientationChange!', _lastADLOrientation);
		if ( invertedOrientation ) {
			resizeADLWindow( screenH, screenW );
		} else {
			resizeADLWindow( screenW, screenH )
		}
	}

	private static function resizeADLWindow( w:Number, h:Number, z:Number = 0 ):void {
		if ( z <= 0 ) z = _zoomADL;
		log( "resizing adl {0}x{1}@{2} - output = {3}x{4}", w, h, z, w/z|0, h/z|0 );
		_lastADLStageW = w / z ;
		_lastADLStageH = h / z ;
		_zoomingADL = true;
		_stage.stageWidth = _lastADLStageW;
		_zoomingADL = false;
		_stage.stageHeight = _lastADLStageH;
	}

	// matches design values
	public static function set designDPI( value:Number ):void {
		_designDPI = value;
		_appPPIScale = Math.round( value / 160 );
		log( 'designDPI={0}, ppiRatio={1}', value, _appPPIScale );
	}

	// shortcut.
	public static function setDesignValues( resolutionX:Number, resolutionY:Number, screenDPI:Number):void {
		designResolutionX = resolutionX ;
		designResolutionY = resolutionY ;
		designDPI = screenDPI ;
	}

	public static function designScale( value:Number ):Number {
		return value / _appPPIScale;
	}

	public static function starlingScale( value:Number ):Number {
		return value * _viewport.width / _stageWidth;
	}

	//============================
	// helpers for screen ratio convertions --
	//============================
	public static function designRatioX(val:Number):Number {
		return val / designResolutionX ;
	}

	public static function designRatioY(val:Number):Number {
		return val / designResolutionY ;
	}


	// based on 160.
	// this returns a perfect physical size for any screen resolution.
	public static function ppiPerfectScale( ppi:Number, baseDpi:Number = 160, isStarling:Boolean = true ):Number {
		var ratioBase:Number = 160 / baseDpi;
		ppi *= ratioBase;
		if ( isStarling ) {
			ppi /= _densityScale;
		}
		return ( _dpiScale / iosDownsamplingScreenFactory ) * ppi;
	}

	private static var _changingOrientation:Boolean = false ;

	public static function blockOrientation(block:Boolean=false):void {
		_stage.autoOrients = !block ;
	}

	public static function setPortrait(block:Boolean=false):void {
		if ( AppHelper.isMobile ) {
			if( _stage.orientation == StageOrientation.DEFAULT ) {
				_stage.autoOrients = !block ;
				return ;
			}
			_changingOrientation = true ;
			_stage.autoOrients = true ;
			_stage.setOrientation( StageOrientation.DEFAULT );
			_stage.autoOrients = !block ;
			_changingOrientation = false ;
		}
	}
	public static function setLandscape(block:Boolean=false):void {
		if ( AppHelper.isMobile ) {
			if( _stage.orientation == StageOrientation.ROTATED_RIGHT ) {
				_stage.autoOrients = !block ;
				return ;
			}
			_changingOrientation = true ;
			_stage.autoOrients = true ;
			_stage.setOrientation( StageOrientation.ROTATED_RIGHT );
			_stage.autoOrients = !block ;
			_changingOrientation = false ;
		}
	}
	public static function get isLandscape():Boolean {
		return AppHelper.stage.stageWidth > AppHelper.stage.stageHeight;
	}

	public static function get isTablet():Boolean {
		return _isTablet;
	}

	public static function get fullscreen():Boolean { return AppHelper.stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE;}

	public static function set fullscreen( value:Boolean ):void {
		AppHelper.stage.displayState = value ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
	}
	public static function toggleFullscreen():void {
		fullscreen=!fullscreen;
	}


	/*
	 // STARLING method to setup stage, uncomment.
	 public static function calculateDensityStarlingWay():void {
	 _dpiScale = screenDPI / 160;
	 if ( AppHelper.isIOS ) {
	 _densityScale = Math.round( _dpiScale );
	 } else {
	 if ( _dpiScale < 1.25 ) _densityScale = 1.0;
	 else if ( _dpiScale < 1.75 ) _densityScale = 1.5;
	 else _densityScale = Math.round( _dpiScale );
	 }
	 selectMatchingAssetScale();
	 }
	 public static function resizeStageStarlingWay():void {
	 // use ceil instead of floor (or int cast) to make sure it fits the entire screen when NOT in fullscreen.
	 _stageWidth = Math.ceil( _stage.stageWidth / _densityScale * _zoomADL );
	 _stageHeight = Math.ceil( _stage.stageHeight / _densityScale * _zoomADL );
	 _viewport.setTo( 0, 0, _stageWidth * _densityScale / _zoomADL, _stageWidth * _densityScale / _zoomADL );
	 resizeStarling();
	 }*/


	//===================================================================================================================================================
	//
	//      ------  log
	//
	//===================================================================================================================================================
	public static var verbose:Boolean = true;
	private static const className:String = "[Screener] ";

	private static function log( ...args ):void {
		if ( !verbose ) return;
		var msg:String = args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ? StringUtil.format.apply( null, args ) : String( args );
		trace( className + msg );
	}

	private static function error( ...args ):void {
		var msg:String = args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ? StringUtil.format.apply( null, args ) : String( args );
		trace( className + " ERROR=" + msg );
	}

	public static function get assetScale():Number {
		return _assetScale;
	}

	public static function get zoomADL():Number {
		return _zoomADL;
	}

	public static function get densityScale():Number {
		return _densityScale;
	}

	public static function get stage():Stage {
		return _stage;
	}
}
}


//===================================================================================================================================================
//
//      ------  SPECIAL CLASS FOR RESOLVE DENSITY LIKE FEATHERS
//
//===================================================================================================================================================

internal class FeathersDensityResolver {

	private static var buckets:Array;

	public function FeathersDensityResolver():void {}

	private static function init():void {
		buckets = [];
		addBucket( 120, .75 );
		addBucket( 160, 1 );
		addBucket( 240, 1.5 );
		addBucket( 320, 2 );
		addBucket( 480, 3 );
		addBucket( 640, 4 );
	}

	public static function addBucket( dpi:Number, scale:Number ):void {
		buckets.push( {dpi: dpi, scale: scale} );
	}

	public static function getBucketScale( dpi:Number ):Number {
		if ( !buckets ) init();
		// looking for the proper scale for this density.
		var prevBuck:Object;
		var currBuck:Object = buckets[0];
		if ( dpi <= currBuck.dpi ) return currBuck.scale;
		var len:int = buckets.length;
		for ( var i:int = 0; i < len; i++ ) {
			currBuck = buckets[i];
			if ( dpi > currBuck.dpi ) {
				prevBuck = currBuck;
				continue;
			}
			// curr bucket is bigger than required.
			var midDpi:Number = (currBuck.dpi + prevBuck.dpi ) / 2;
			if ( dpi < midDpi ) return prevBuck.scale;
			return currBuck.scale;
		}
		return currBuck.scale;
	}
}