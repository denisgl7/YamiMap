/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/27/17.
 *
 */
package roipeker.helpers {
import roipeker.callbacks.Callback;
import roipeker.io.SOMan;
import roipeker.utils.AppUtils;
import roipeker.utils.StringUtils;

import flash.desktop.NativeApplication;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.filesystem.File;
import flash.system.System;

import starling.core.Starling;
import starling.utils.SystemUtil;


public class AppHelper {

	private static var _stage:Stage;

	public static var maxFPS:uint = 60;
	public static var minFPS:uint = 4;


	private static var _exitingEvent:Event;
	private static var _allSavedBeforeExit:Boolean = false;

	private static var _appExited:Callback;
	private static var _appActivated:Callback;
	private static var _isActivated:Boolean;

	public static var adlBinFolderName:String = "bin-assets";
	public static var appDir:File;
	public static var storageDir:File;

	// -- Application descriptor data.
	private static var _appVersion:String;
	private static var _appFilename:String;
	private static var _appId:String;
	private static var _deviceGUID:String;

	public function AppHelper() {}

	public static function init( stage:Stage ):void {
		_stage = stage;

		// init AIR stuffs.
		initFolders();
		NativeApplication.nativeApplication.addEventListener( Event.ACTIVATE, appActivateHandler );
		NativeApplication.nativeApplication.addEventListener( Event.DEACTIVATE, appActivateHandler );
		NativeApplication.nativeApplication.addEventListener( Event.EXITING, exitAppHandler, false, 0, true );
	}

	public static function initStage( quality:String = "low" ):void {
		_stage.scaleMode = StageScaleMode.NO_SCALE;
		_stage.align = StageAlign.TOP_LEFT;
		_stage.quality = quality;
		_stage.showDefaultContextMenu = false;
	}

	private static function initFolders():void {
		storageDir = File.applicationStorageDirectory;
		appDir = File.applicationDirectory;
		if ( isADL ) {
			appDir = new File( appDir.nativePath ).parent.resolvePath( adlBinFolderName );
		}
	}

	private static function appActivateHandler( event:Event ):void {
		_isActivated = event.type == Event.ACTIVATE;
		// don't consume battery.
		if ( !isDesktop ) {
			_stage.frameRate = _isActivated ? maxFPS : minFPS;
		}
		if ( _appActivated ) _appActivated.dispatch( _isActivated );
	}

	private static function exitAppHandler( event:Event ):void {
		// - only when an object listens for appExited, we saved the state.
		// Is this only valid for desktop?
		if ( Starling.current ) Starling.current.stop( true );
		if ( !_allSavedBeforeExit && _appExited ) {
			event.preventDefault();
			trace( "AppHelper > Closing app, save stuffs in 1 frame." );
			if ( _appExited ) _appExited.dispatch();
			UIHelper.dly( onSaveStateComplete, true );
		} else {
			NativeApplication.nativeApplication.removeEventListener( Event.EXITING, exitAppHandler );
			NativeApplication.nativeApplication.exit( 1 );
			trace( "AppHelper > Bye!" );
		}

		function onSaveStateComplete():void {
			trace( "AppHelper > Save completed" );
			_allSavedBeforeExit = true;
			AppHelper.exitApp();
		}
	}

	public static function exitApp():void {
		if ( !_exitingEvent ) {
			_exitingEvent = new Event( Event.EXITING, false, true );
		}
		NativeApplication.nativeApplication.dispatchEvent( _exitingEvent );
		if ( !_exitingEvent.isDefaultPrevented() ) {
			NativeApplication.nativeApplication.exit( 0 );
		}
	}

	public static function get isAIR():Boolean {
		return SystemUtil.isAIR;
	}

	private static var _isADL:int = -1;
	public static var appOutputDirName:String = 'bin';
	public static function get isADL():Boolean {
		if ( _isADL == -1 ){
			var name:String = File.applicationDirectory.name ;
            trace('adl name:', name );
			_isADL = File.applicationDirectory.name==appOutputDirName ? 1 : 0;
		}
		return Boolean( _isADL );
	}

	public static function get isAndroid():Boolean {
		return SystemUtil.isAndroid;
	}

	public static function get isMobile():Boolean {
		return !isDesktop;
	}

	public static function get isDesktop():Boolean {
		return SystemUtil.isDesktop;
	}

	public static function get isIOS():Boolean {
		return SystemUtil.isIOS;
	}

	public static function get isMac():Boolean {
		return SystemUtil.isMac;
	}

	public static function get isWin():Boolean {
		return SystemUtil.isWindows;
	}

	public static function onLoaderInfoComplete( callback:Function, root:DisplayObject = null ):void {
		if ( !root ) {
			if ( !stage ) {
				trace( 'onLoaderInfoComplete() requires a root DisplayObject or stage assigned, call AppHelper.init(stage) first.' );
				return;
			} else {
				root = stage.getChildAt( 0 );
			}
		}
		if ( !root["loaderInfo"] ) return;
		if ( !callback ) {
			trace( 'onLoaderInfoComplete() requires a valid callback function.' );
			return;
		}
		UIHelper.listener( root.loaderInfo, "complete", function ( e:* ) {
			UIHelper.listener( e.target, e.type, arguments.callee, false );
			callback();
		}, true );
	}


	//===================================================================================================================================================
	//
	//      ------  PROXY LISTENER
	//
	//===================================================================================================================================================
	/*
	 private static var _listener:EventDispatcher;

	 private static function lazyInitListener():void {
	 _listener = new EventDispatcher();
	 }

	 public static function addEventListener( type:String, listener:Function ):void {
	 if ( !_listener ) lazyInitListener();
	 _listener.addEventListener( type, listener );
	 }

	 public static function removeEventListener( type:String, listener:Function ):void {
	 if ( !_listener ) return;
	 _listener.removeEventListener( type, listener );
	 }

	 public static function removeEventListeners( type:String = null ):void {
	 if ( !_listener ) return;
	 _listener.removeEventListeners( type );
	 }

	 public static function dispatchEvent( event:starling.events.Event ):void {
	 if ( !_listener ) lazyInitListener();
	 _listener.dispatchEvent( event );
	 }

	 public static function dispatchEventWith( type:String, bubbles:Boolean = false, data:Object = null ):void {
	 if ( !_listener ) lazyInitListener();
	 _listener.dispatchEventWith( type, bubbles, data );
	 }

	 public static function hasEventListener( type:String, listener:Function = null ):Boolean {
	 if ( !_listener ) return false;
	 return _listener.hasEventListener( type, listener );
	 }*/

	//===================================================================================================================================================
	//
	//      ------  system utils
	//
	//===================================================================================================================================================

	public static function gc():void {
		System.gc();
		System.pauseForGCIfCollectionImminent( .5 );
	}

	public static function get isActivated():Boolean {
		return _isActivated;
	}

	public static function get appActivated():Callback {
		if ( !_appActivated ) {
			_appActivated = new Callback( true );
		}
		return _appActivated;
	}

	public static function get appExited():Callback {
		if ( !_appExited ) _appExited = new Callback( true );
		return _appExited;
	}

	public static function get stage():Stage {
		return _stage;
	}

	public static function disableMouse( root:Sprite = null ):void {
		if ( !root ) {
			if ( !_stage ) {
				trace( 'call init(stage) first' );
				return;
			}
			root = _stage.getChildAt( 0 ) as Sprite;
		}
		root.mouseChildren = root.mouseEnabled = false;
	}

	//============================
	// App descriptor --
	//============================

	private static function initDescriptor():void {
		var descriptorXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
		var ns:Namespace = descriptorXML.namespace();
//		_appFilename = descriptorXML.ns::versionNumber[0];
		_appVersion = descriptorXML.ns::versionNumber[0];
		_appId = String( descriptorXML.ns::id[0] );
		_appFilename = String( descriptorXML.ns::filename[0] );
		_deviceGUID = getDeviceGUID();
		trace( "[ AppHelper ] app filename = " + _appFilename );
		trace( "[ AppHelper ] app version = " + _appVersion );
	}

	private static function getDeviceGUID():String {
		if( !SOMan.instance.has( "guid" )){
			SOMan.instance.set( "guid", AppUtils.generateGUID() );
			trace( "[ AppHelper ] Generating UDID ..." );
		}
		return SOMan.instance.get("guid");
	}

	public static function get appVersion():String {
		if( !_appVersion ) initDescriptor();
		return _appVersion;
	}

	public static function get appFilename():String {
		if( !_appFilename ) initDescriptor();
		return _appFilename;
	}

	public static function get appId():String {
		if( !_appId ) initDescriptor();
		return _appId;
	}

	public static function get deviceGUID():String {
		if( !_deviceGUID ) initDescriptor();
		return _deviceGUID;
	}
}
}
