/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/18/17.
 *
 */
package roipeker.utils {
import roipeker.callbacks.Callback;

import com.greensock.TweenLite;

import flash.utils.getTimer;

import starling.animation.Juggler;
import starling.core.Starling;

/**
 * Simple callback queue class that runs each x seconds... and dispatches the items
 * of an array.
 *
 * Sample:
 *
 var arr:Array = [];
 for ( var i:int = 0; i < 1000; i++ ) arr[i] = "Hola " + i;
 CallbackQueue.get( arr, 5, .01, null, onBatch, onComplete, true );
 function onBatch( elements:Array, queue:CallbackQueue ):void {
			trace( 'batched:', elements.length );
			if( queue ){
				trace( 'remains:', queue.remaining );
			}
		}

 function onComplete():void {
			trace( 'queue completed!' );
		}


 */
public class CallbackQueue {

	private static var _pool:Pooler;

	public static function get( data:Array = null, processMax:uint = 1, delayBulk:Number = 0.1,
								processed:Function = null,
								batched:Function = null, completed:Function = null,
								autoStart:Boolean = true ):CallbackQueue {
		if ( !_pool ) _pool = new Pooler( CallbackQueue, 0, 0, null, "reset" );
		var c:CallbackQueue = _pool.get();
		c.data = data;
		c.processMax = processMax || 1;
		c.delayBulk = delayBulk || 0;
		if ( processed ) c.processed.add( processed );
		if ( batched ) c.batched.add( batched );
		if ( completed ) c.completed.add( completed );
		if ( autoStart ) {
			// delay start.
			c.delayedStart( 0.1 );
		}
		return c;

	}

	public function returnToPool():void {
		_pool.put( this );
	}

	public function reset():void {
		_isProcessing = false;
		_data = null;
		counter = 0;
		processMax = 0;
		total = 0;
		remaining = 0;
		delayBulk = .1;
		numBatches = 0;
		if ( _completed ) _completed.removeAll();
		if ( _batched ) _batched.removeAll();
		if ( _processed ) _processed.removeAll();
	}

	// relay on starling juggler?
	public static var juggler:Juggler;

	private var _isProcessing:Boolean = false;
	private var _data:Array;

	private var _completed:Callback;
	private var _batched:Callback;
	private var _processed:Callback;

	public var processMax:int = 1;
	public var counter:int = 0;
	public var total:uint;
	public var remaining:int;
	public var delayBulk:Number = .1;
	public var numBatches:uint;

	public var startTime:int = 0;
	public var currentdelay:Number;
	public var verbose:Boolean = false;

	public function CallbackQueue() {
		if ( !juggler ) {
			if ( Starling.current ) juggler = Starling.current.juggler;
		}
	}

	public function get processed():Callback {
		if ( !_processed ) _processed = new Callback( true );
		return _processed;
	}

	public function get batched():Callback {
		if ( !_batched ) _batched = new Callback( true );
		return _batched;
	}

	public function get completed():Callback {
		if ( !_completed ) _completed = new Callback();
		return _completed;
	}

	public function get data():Array {
		return _data;
	}

	public function set data( value:Array ):void {
		if ( !value ) {
			trace( "[ CallbackQueue ] ::data can't be null" );
			return;
		}
		_data = value.concat();
		remaining = _data.length;
	}

	private function delayedStart( dly:Number ):void {
		runDelay( start, dly );
	}

	public function start():void {
		if ( _isProcessing ) return;
		numBatches = _data.length / processMax;
		total = _data.length;
		_isProcessing = true;
		log( "num batches = {0}", numBatches );
		startTime = getTimer();
		loadNext();
	}

	public function pause():void {
		_isProcessing = false;
		stopDelay( loadNext );
	}

	private function runDelay( fun:Function, dly:Number ):void {
		if ( juggler && !juggler.containsDelayedCalls( fun ) ) {
			juggler.delayCall( fun, dly );
		} else {
			TweenLite.delayedCall( dly, fun );
		}
	}

	private function stopDelay( fun:Function ):void {
		if ( juggler && juggler.containsDelayedCalls( fun ) ) {
			juggler.removeDelayedCalls( fun );
		} else {
			TweenLite.killTweensOf( fun );
		}
	}

	public function resume():void {
		if ( remaining > 0 ) {
			loadNext();
		}
	}

	private function loadNext():void {
		_isProcessing = true;
		var len:int = Math.min( _data.length, counter + processMax );
		var tmp:Array = [];
		currentdelay = (getTimer() - startTime) / 1000;
		for ( counter; counter < len; counter++ ) {
			if ( _processed ) _processed.dispatch( counter, _data[counter], this );
			tmp[tmp.length] = _data[counter];
		}
		remaining = _data.length - len;
		log( " call remain = {0}", remaining );
		if ( _batched ) _batched.dispatch( tmp, this );

		if ( remaining > 0 ) {
			runDelay( loadNext, delayBulk );
		} else {
			_isProcessing = false;
			processComplete();
		}
	}

	private function processComplete():void {
		log( "complete" );
		_isProcessing = false;
		if ( _completed ) _completed.dispatch();
		returnToPool();
	}

	//============================
	// log --
	//============================

	private function log( ...args ):void {
		if ( !verbose ) return;
		var msg:String = ( args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ) ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ CallbackQueue ] " + msg );
	}

}
}
