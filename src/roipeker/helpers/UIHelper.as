/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/28/17.
 *
 */
package roipeker.helpers {
import roipeker.callbacks.AbsCallback;

import com.greensock.TweenLite;
import com.greensock.TweenMax;

import flash.events.IEventDispatcher;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import starling.core.Starling;
import starling.events.Event;
import starling.events.TouchEvent;

public class UIHelper {

	public static var matrix:Matrix = new Matrix();
	public static var point:Point = new Point();
	public static var rect:Rectangle = new Rectangle();

	public function UIHelper() {}


	public static function listener( targets:*, types:*, callback:Function, add:Boolean, priority:Number = 0,
									 weak:Boolean = false ):void {
		// separate between Starling and Flash event system
		var method:String = add ? 'addEventListener' : 'removeEventListener';
		var params:Array;
		var i:int = 0;
		var len:int;
		if ( targets is Array ) {
			len = targets.length;
			for ( i = 0; i < len; i++ ) {
				listener( targets[i], types, callback, add, priority, weak );
			}
		} else {
			if ( types is Array ) {
				len = types.length;
				for ( i = 0; i < len; i++ ) {
					listener( targets, types[i], callback, add, priority, weak );
				}
			} else {
				params = [String( types ), callback];
				if ( targets is IEventDispatcher ) {
					if ( weak && add ) params.push( 0, false, true );
				}
				targets[method].apply( null, params );
			}
		}
	}

	public static function listenerComplete( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.COMPLETE, callback, add );
	}

	public static function listenerRemoved( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.REMOVED_FROM_STAGE, callback, add );
	}

	public static function listenerAddedStage( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.ADDED_TO_STAGE, callback, add );
	}

	public static function listenerRemovedStage( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.REMOVED_FROM_STAGE, callback, add );
	}

	public static function listenerResize( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.RESIZE, callback, add );
	}

	public static function listenerChange( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.CHANGE, callback, add );
	}

	public static function listenerTap( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.TRIGGERED, callback, add );
	}

	public static function listenerScroll( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, Event.SCROLL, callback, add );
	}

	public static function listenerTouch( targets:*, callback:Function, add:Boolean = true ):void {
		listener( targets, TouchEvent.TOUCH, callback, add );
	}

	public static function signal( signals:*, callback:Function, add:Boolean ):void {
		if ( signals is Array ) {
			for ( var i:int = 0; i < Array( signals ).length; i++ ) {
				signal( signals[i], callback, add );
			}
		} else if ( signals is AbsCallback ) {
			var method:String = add ? 'add' : 'remove';
			AbsCallback( signals )[method].apply( null, [callback] );
		}
	}

	public static function signalGroup( targets:Array, signalProp:String, callback:Function, add:Boolean ):void {
		for ( var i:int = 0; i < targets.length; i++ ) {
			if ( targets[i].hasOwnProperty( signalProp ) && targets[i][signalProp] is AbsCallback ) {
				signal( AbsCallback( targets[i][signalProp] ), callback, add );
			}
		}
	}

	public static function callFunctionGroup( items:Array, methodName:String, args:Array = null ):void {
		if ( !items || items.length == 0 ) return;
		var len:uint = items.length;
		for ( var i:int = 0; i < len; i++ ) {
			if ( items[i] && items[i].hasOwnProperty( methodName ) && items[i][methodName] is Function ) {
				items[i][methodName].apply( null, args );
			}
		}
	}

	public static function activateGroup( items:Array, flag:Boolean ):void {
		var len:uint = items.length;
		for ( var i:int = 0; i < len; i++ ) {
			if ( items[i] && items[i].hasOwnProperty( 'activate' ) && items[i]['activate'] is Function ) {
				// validate if its already active.
				if ( items[i].hasOwnProperty( 'active' ) && items[i]['active'] != flag ) {
					items[i].activate( flag );
				}
			}
		}
	}

	public static function dly( callback:Function, killPrevious:Boolean = true, ...args ):void {
		if ( Starling.current ) {
			if ( killPrevious ) Starling.current.juggler.removeDelayedCalls( callback );
			if ( !killPrevious && Starling.current.juggler.containsDelayedCalls( callback ) ) return;
			args.unshift( callback, 0 );
			Starling.current.juggler.delayCall.apply( null, args );
		} else {
			if ( killPrevious ) TweenLite.killDelayedCallsTo( callback );
			if ( !killPrevious && TweenMax.isTweening( callback ) ) return;
			TweenLite.delayedCall( 0, callback, args );
		}
	}


	public static function scaleRectangle( scale:Number, rect:Rectangle = null, roundValue:Boolean = false ):Rectangle {
		if ( !rect ) rect = UIHelper.rect;
		rect.x *= scale;
		rect.y *= scale;
		rect.width *= scale;
		rect.height *= scale;
		if ( roundValue ) {
			rect.x |= 0;
			rect.y |= 0;
			rect.width |= 0;
			rect.height |= 0;
		}
		return rect;
	}

}
}
