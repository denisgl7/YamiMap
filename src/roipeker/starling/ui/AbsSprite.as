/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.starling.ui {
import roipeker.helpers.UIHelper;
import roipeker.starling.MyAssets;
import roipeker.starling.StarlingUtils;
import roipeker.utils.StringUtils;
import roipeker.starling.Screener;

import com.greensock.TweenLite;
import com.greensock.TweenMax;


import flash.utils.getQualifiedClassName;

import starling.animation.Juggler;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.TextField;

public class AbsSprite extends Sprite {

	// defined externally.
	public static var APP_W:uint;
	public static var APP_H:uint;

	public static const INVALIDATE_ALL:String = "all";
	public static const INVALIDATE_LAYOUT:String = "layout";
	public static const INVALIDATE_DATA:String = "data";
	public static const INVALIDATE_SCROLL:String = "scroll";
	public static const INVALIDATE_SELECTED:String = "selected";
	public static const INVALIDATE_SIZE:String = "size";
	public static const INVALIDATE_STATE:String = "state";
	public static const INVALIDATE_DEBUG_CHILD:String = "debugChild";
	public static const INVALIDATE_STYLE:String = "style";
	public static const INVALIDATE_SKIN:String = "skin";

	private var _isInitialized:Boolean = false;
	private var _isInitializing:Boolean = false;

	protected var _invalidationFlags:Object = {};
	protected var _delayedInvalidationgFlags:Object = {};
	protected var _isAllInvalid:Boolean = false;

	protected var _w:int;
	protected var _h:int;
	private var _depth:int;
	private var _validationQueue:UIValidateQueue;
	private var _isValidating:Boolean;
	private var _invalidateCount:uint;
	private var _isDisposed:Boolean = false;
	private var _hasValidated:Boolean = false;

	protected var _uiReady:Boolean = false;
	protected var _enabled:Boolean = true;
	protected var _active:Boolean = false;

	public static var juggler:Juggler;

	// component id number.
	public var cid:String=null;
	public var cidx:int=0;

	// userData object to store anything.
	public var udata:Object = {};

	public function AbsSprite(doc:Sprite = null ) {
		super();

		if ( !juggler ) juggler = Starling.current.juggler;
		addEventListener( Event.ADDED_TO_STAGE, addedToStageHandler );
		addEventListener( Event.REMOVED_FROM_STAGE, removedFromStageHandler );
		if ( doc ) doc.addChild( this );
	}

	//============================
	// INVALIDATION routines --
	//============================
	protected function addedToStageHandler( event:Event ):void {
		if ( !_isInitialized ) {
			initNow();
		}
		_depth = StarlingUtils.getDisplayObjectDepth( this );
		_validationQueue = UIValidateQueue.instance;
		if ( isInvalid() ) {
			_invalidateCount = 0;
			_validationQueue.addUI( this );
		}
	}

	protected function removedFromStageHandler( event:Event ):void {
		_depth = -1;
		_validationQueue = null;
		// DEACTIVATE by default.
		if( _active ) {
			activate( false );
		}
	}

	private function initNow():void {
		if ( _isInitialized || _isInitializing ) return;
		_isInitializing = true;
		initialize();
		invalidate( INVALIDATE_ALL );
		_isInitializing = false;
		_isInitialized = true;
		dispatchEventWith( UIEvt.INITIALIZED );
	}

	protected function invalidate( flag:String = INVALIDATE_ALL ):void {
		var isAlreadyInvalid:Boolean = isInvalid();
		var isAlreadyDelayedInvalid:Boolean = false;
		if ( _isValidating ) {
			// check if we have delayed invalidations.
			for ( var f:String in _delayedInvalidationgFlags ) {
				isAlreadyDelayedInvalid = true;
				break;
			}
		}

		if ( !flag || flag == INVALIDATE_ALL ) {
			if ( _isValidating ) {
				_delayedInvalidationgFlags[INVALIDATE_ALL] = true;
			} else {
				_isAllInvalid = true;
			}
		} else {
			if ( _isValidating ) {
				// if its already validating, added it to the next loop.
				_delayedInvalidationgFlags[flag] = true;
			} else if ( flag != INVALIDATE_ALL && !_invalidationFlags.hasOwnProperty( flag ) ) {
				_invalidationFlags[flag] = true;
			}
		}

		if ( !_validationQueue || !_isInitialized )
			return;

		// delayed invalidation.
		if ( _isValidating ) {
			if ( isAlreadyDelayedInvalid )
				return;

			_invalidateCount++;
			if ( _invalidateCount >= 10 ) {
				throw new Error( getQualifiedClassName( this ) + " returned validation queue too many times during validation." );
			}
			_validationQueue.addUI( this );
			return;
		}

		if ( isAlreadyInvalid )
			return;

		_invalidateCount = 0;
		_validationQueue.addUI( this );
	}

	public function validate():void {
		if ( _isDisposed ) return;
		if ( !_isInitialized ) {
			if ( _isInitializing ) {
				trace( "A component cannot validate until after it has finished initializing." );
				return;
			}
			initNow();
		}
		if ( !isInvalid()) return;
		if ( _isValidating) return;
		_isValidating = true;
		draw();
		var flag:String ;

		for ( flag in _invalidationFlags )
			delete _invalidationFlags[flag];

		_isAllInvalid = false;
		// now pass delayed invalidation to the next invalidation "loop"
		for ( flag in _delayedInvalidationgFlags ) {
			if ( flag == INVALIDATE_ALL ) {
				_isAllInvalid = true;
			} else {
				_invalidationFlags[flag] = true;
			}
			delete _delayedInvalidationgFlags[flag];
		}
		_isValidating = false;
		if ( !_hasValidated ) {
			_hasValidated = true;
			dispatchEventWith( UIEvt.CREATION_COMPLETE );
		}
	}

	protected function isInvalidStyle():Boolean {
		return isInvalid( INVALIDATE_STYLE );
	}
	protected function isInvalidSize():Boolean {
		return isInvalid( INVALIDATE_SIZE );
	}

	protected function isInvalidData():Boolean {
		return isInvalid( INVALIDATE_DATA );
	}

	protected function isInvalidLayout():Boolean {
		return isInvalid( INVALIDATE_LAYOUT );
	}

	protected function isInvalidScroll():Boolean {
		return isInvalid( INVALIDATE_SCROLL );
	}

	protected function isInvalidSelected():Boolean {
		return isInvalid( INVALIDATE_SELECTED );
	}

	protected function isInvalidState():Boolean {
		return isInvalid( INVALIDATE_STATE );
	}

	protected function isInvalid( flag:String = null ):Boolean {
		if ( _isAllInvalid ) return true;
		if ( !flag ) {
			for ( flag in _invalidationFlags ) return true;
			return false;
		}
		return _invalidationFlags[flag];
	}

	protected function setInvalidationFlag( flag:String ):void {
		if ( _invalidationFlags.hasOwnProperty( flag ) ) return;
		_invalidationFlags[flag] = true;
	}

	protected function clearInvalidationFlag( flag:String ):void {
		delete  _invalidationFlags[flag];
	}

	protected function draw():void {

		// debug quad...
		if ( _debugSizeQuad ) {
			if ( isInvalid( INVALIDATE_SIZE ) ) {
				_debugSizeQuad.width = _w;
				_debugSizeQuad.height = _h;
			}
			if ( isInvalid( INVALIDATE_DEBUG_CHILD ) ) {
				addChild( _debugSizeQuad );
			}
		}

	}

	protected function initialize():void {
	}

	//============================
	// Class blnk UI code --
	//============================

	public function activate( flag:Boolean ):void {
		_active = flag;
	}

	public function setupUI():void {
		_uiReady = true;
	}

	public function clearUI():void {
		_uiReady = false;
	}

	override public function dispose():void {
		_isDisposed = true;
		_validationQueue = null;
		super.dispose();
	}

	public function move( x:Number, y:Number, round:Boolean = false ):void {
		this.x = !round ? x : Math.round( x );
		this.y = !round ? y : Math.round( y );
	}

	public function get sw():uint {
		return stage ? stage.stageWidth : Starling.current.stage.stageWidth;
	}

	public function get sh():uint {
		return stage ? stage.stageHeight : Starling.current.stage.stageHeight;
	}

	public function useAppSize():void {
		useSize( APP_W, APP_H );
	}

	public function useStageSize():void {
		useSize( sw, sh );
	}

	public function useSize( w:Number = 0, h:Number = 0 ):void {
		_w = w;
		_h = h;
		saveSize();
	}

	public function setSize( w:Number = -1, h:Number = -1 ):Boolean {
		var changed:Boolean = false ;

		if ( w < 0 && h < 0 ) return changed ;

		if ( w > -1 && w != _w ){
			changed = true ;
			_w = w;
		}
		if ( h > -1 && h != _h ) {
			changed = true ;
			_h = h;
		}
		if( changed ) {
			saveSize();
		}
		return changed ;
	}

	public function get w():int {return _w;}

	public function set w( value:int ):void {
		if ( _w == value ) return;
		_w = value;
		saveSize();
	}

	private function saveSize():void {
//		trace("WW",_isInitializing, _isInitialized );
		dispatchEventWith( Event.RESIZE );
		if ( _isInitialized ) {
			invalidate( INVALIDATE_SIZE );
		}
	}

	public function get h():int {return _h;}

	public function set h( value:int ):void {
		if ( _h == value ) return;
		_h = value;
		saveSize();
	}

	public function get depth():int {return _depth;}

	public function get enabled():Boolean {return _enabled;}

	public function set enabled( value:Boolean ):void {
		if ( _enabled == value ) return;
		_enabled = value;
		this.touchable = _enabled ;
		invalidate( INVALIDATE_STATE );
	}

	protected function get starling():Starling {
		return stage ? stage.starling : Starling.current ;
	}

	// shortcut for design scale.
	[Inline]
	public final function dsc(val:Number):Number {
		return Screener.designScale( val ) ;
	}

	[Inline]
	public final function propW( obj:DisplayObject, val:Number, useDesignDPI:Boolean=false):void {
		StarlingUtils.proportionalWidth( obj, val, useDesignDPI );
	}

	[Inline]
	public final function propH( obj:DisplayObject, val:Number, useDesignDPI:Boolean=false):void {
		StarlingUtils.proportionalHeight( obj, val, useDesignDPI );
	}


	//============================
	// Greensock --
	//============================
	public function twn( target:Object, duration:Number, props:Object,
						 killPreviousTweens:Boolean = false ):TweenMax {
		if ( !target ) target = this;
		if ( killPreviousTweens ) TweenLite.killTweensOf( target );
		return TweenMax.to( target, duration, props );
	}

	public function kill( ...args ):void {
		var len:int = args.length;
		for ( var i:int = 0; i < len; i++ ) {
			if ( args[i] is Array ) {
				kill.apply( null, args[i] as Array );
			} else {
				TweenLite.killTweensOf( args[i] );
			}
		}
	}

	public function setProps( obj:Object, props:Object ):void {
		if ( !obj ) obj = this;
		TweenLite.set( obj, props );
	}

	public function tint( obj:Object, color:* = null ):void {
		if ( !obj ) return;
		if ( typeof( color ) == "number" && color < 0 ) color = null;
		if ( color == null ) color = 0xFFFFFF;
		if ( obj is TextField ) {
			( obj as TextField ).format.color = color;
		} else {
			setProps( obj, {color: color} );
		}
	}

	public function dly( seconds:Number, callback:Function, ...args ):void {
		if ( juggler.containsDelayedCalls( callback ) ) {
			juggler.removeDelayedCalls( callback );
		}
		args.unshift( callback, seconds );
		juggler.delayCall.apply( null, args );
	}

	//============================
	// Debug code --
	//============================
	protected var _debugSizeQuad:Quad;
	protected var _debugSizeColor:uint = 0xffff00;

	public function debugSize( flag:Boolean = true ):void {
		if ( flag ) {
			if ( !_debugSizeQuad ) {
				_debugSizeQuad = MyAssets.getColorQuad( 0xffffff, null, w, h );
				_debugSizeQuad.touchable = false;
				_debugSizeQuad.color = _debugSizeColor;
				_debugSizeQuad.alpha = .6;
				UIHelper.listener( this, Event.ADDED, debugAddedHandler, true );
				addChild( _debugSizeQuad );
			} else {
				_debugSizeQuad.width = w;
				_debugSizeQuad.height = h;
			}
		} else {
			if ( _debugSizeQuad ) {
				UIHelper.listener( this, Event.ADDED, debugAddedHandler, false );
				_debugSizeQuad.removeFromParent( true );
				_debugSizeQuad = null;
			}
		}
	}

	private function debugAddedHandler( event:Event ):void {
		if ( event.target != _debugSizeQuad ) {
			// use invalidation...
//			invalidate(INVALIDATE_DEBUG_CHILD);
			addChild( _debugSizeQuad );
		}
	}

	//============================
	// logs --
	//============================
	public var verbose:Boolean = true;

	private var _myClassName:String;

	public function get className():String {
		if ( !_myClassName ) initClassName();
		return _myClassName;
	}

	private var _lastTrackId:String;
	private var _trackPreprend:String;

	// TRACK and SPENT time routines.
	// TODO: include DateUtils
	protected function _t( id:String, showClassname:Boolean = true ):void {
		_trackPreprend = showClassname ? className + "::" : _trackPreprend;
		id = StringUtils.replace( id, " ", "." );
		_lastTrackId = _trackPreprend + id;
//		DateUtils.track( _lastTrackId, true );
	}

	protected function _s( id:String = null ):void {
		id = !id ? _lastTrackId : _trackPreprend + StringUtils.replace( id, " ", "." );
//		DateUtils.spent( id, true, true );
	}

	private function initClassName():void {
		_myClassName = StringUtils.replace( StringUtils.replace( String( this ), "[object " ), "]" );
	}

	protected function log( ...args ):void {
		if ( !verbose ) return;
		var msg:String = ( args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ) ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ " + className + " ] " + msg );
	}

	protected function error( ...args ):void {
		var msg:String = ( args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ) ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ " + className + " ] ERROR =" + msg );
	}

}
}
