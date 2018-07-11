/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.utils {
import roipeker.callbacks.Callback;

/**
 * A simple pool factory to keep memory usage low, reusing objects.
 * Based on LoanShark.
 *
 Sample:

 var p:Pooler = Pooler.build( Quad, [100, 100, 0x00ff00], function ( q:Quad ):void {
			trace( "Reset Quad", q );
			q.alpha = .3;
		}, "dispose" );
 for ( var i:int = 0; i < 5; i++ ) {
		var q:Quad = p.get( true );
		q.x = i * 120;
		addChild( q );
	}
 trace( p );
 p.put( q );
 trace( p );
 p.put( q );
 trace( p );
 //        p.resetObjects();
 //        p.disposeObjects(true);

 */
public class Pooler {

	private var _ObjClass:Class;
	private var _maxBuffer:uint;
	private var _resetMethod:Object;
	private var _disposeMethod:Object;
	private var _bufferSize:int;
	private var _pool:Array;
	private var _objInUse:Array;
	private var _size:int;
	private var _constructorParams:Array;

	/**
	 * Constructor.
	 * @param objClass    Class to initialize the objects
	 * @param initPoolSize    initial pool size
	 * @param maxBuffer        max quantity of objects in pool.
	 * @param constructorParams    arguments for the Class instances
	 * @param resetMethod    Function callback or ObjectClass dynamic method String
	 * @param disposeMethod    Function callback or ObjectClass dynamic method String
	 */
	public function Pooler(objClass:Class, initPoolSize:uint = 0, maxBuffer:uint = 0, constructorParams:Array = null,
	                       resetMethod:Object = null,
	                       disposeMethod:Object = null ) {
		_ObjClass = objClass;
		_maxBuffer = maxBuffer;
		_resetMethod = resetMethod;
		_disposeMethod = disposeMethod;
		_constructorParams = constructorParams;
		_objInUse = [];
		_pool = [];
		if ( initPoolSize > 0 )
			init( initPoolSize );
	}

	private function init( size:uint ):void {
		for ( var i:int = 0; i < size; i++ ) {
			createAndAddObject();
		}
	}

	public function get( reset:Boolean = true ):* {
		var obj:Object;
		if ( _bufferSize <= 0 ) {
			obj = createObject();
			if ( reset && _resetMethod ) callFun( _resetMethod, obj );
		} else {
			--_bufferSize;
			obj = _pool[_bufferSize];
		}
		_objInUse[_objInUse.length] = obj;
		return obj;
	}

	public function put( o:Object ):void {
		var alreadyIn:Boolean = false;
		var correctType:Boolean = o is _ObjClass;
		var useIdx:int = _objInUse.indexOf( o );
		if ( useIdx == -1 ) {
			alreadyIn = true;
			trace( "[ Pooler ] ::put("+o+"); already in pool." );
		} else {
			_objInUse.removeAt( useIdx );
		}

		if ( o && correctType && used > 0 && !alreadyIn ) {
			addToPool( o, true );
		}
		if ( _maxBuffer && _bufferSize > _maxBuffer ) clean();
	}

	/**
	 * Check if the pool owns the objects
	 * @param o
	 * @return
	 */
	public function owns( o:Object ):Boolean {
		return _objInUse.indexOf( o ) > -1 || _pool.indexOf( o ) > -1;
	}

	public function inUse( o:Object ):Boolean {
        return _objInUse.indexOf( o ) > -1 ;
    }

	/**
	 * Prunes the pool of unused objects to conserve memory.
	 */
	public function clean():void {
		var u:int = _bufferSize;
		if ( u > 0 ) {
			var cleanCount:int = Math.min( _size, u );
			disposeObjects();
			createList();
			_bufferSize = 0;
			_size -= cleanCount;
		}
		if ( _cleaned ) _cleaned.dispatch();
	}

	/**
	 * Empties the pool completely and reinitialize it.
	 * @param forced        Forces the flush even if some objects are still being used.
	 * @param disposeUnused    Optionally dispose the unused objects.
	 */
	public function flush( forced:Boolean = false, disposeUnused:Boolean = false ):void {
		if ( used > 0 && !forced ) return;
		if ( disposeUnused ) disposeObjects();
		_size = _bufferSize = 0;
		createList();
		if ( _flushed ) _flushed.dispatch();
	}

	public function dispose():void {
		flush( true, true );
		_ObjClass = null;
		_pool = null;
		_objInUse = null;
		_resetMethod = null;
		_disposeMethod = null;
		if ( _disposed ) _disposed.dispatch();
		_cleaned = null;
		_flushed = null;
		_disposed = null;
	}

	private function createList():void {
		_pool = [];
		_objInUse = [];
	}

	/**
	 * Utility to call reset method on all available instances.
	 */
	public function resetObjects():void {
		if ( !_resetMethod ) return;
		var o:Object;
		for ( var i:int = used - 1; i >= 0; --i ) {
			o = _objInUse[i];
			if ( o ) {
				callFun( _resetMethod, o );
			}
		}
	}

	public function disposeObjects( includeUsed:Boolean = false ):void {
		if ( !_disposeMethod ) return;
		var o:Object;
		for ( var i:int = _bufferSize - 1; i >= 0; --i ) {
			o = _pool[i];
			if ( o ) {
				callFun( _disposeMethod, o );
			}
		}
		if ( includeUsed ) {
			for ( i = used - 1; i >= 0; --i ) {
				o = _objInUse[i];
				if ( o ) {
					callFun( _disposeMethod, o );
				}
			}
		}
	}

	private function addToPool( o:Object, reset:Boolean = false ):void {
		if ( reset && _resetMethod ) {
			callFun( _resetMethod, o );
		}
		_pool[_bufferSize] = o;
		_bufferSize++;
	}

	private function createAndAddObject():void {
		addToPool( createObject(), true );
	}

	private function createObject():Object {
		_size++;
		var p:Array = _constructorParams;
		var len:int = p ? p.length : 0;
		if ( len == 0 ) return new ObjClass();
		else if ( len == 1 ) return new ObjClass( p[0] );
		else if ( len == 2 ) return new ObjClass( p[0], p[1] );
		else if ( len == 3 ) return new ObjClass( p[0], p[1], p[2] );
		else if ( len == 4 ) return new ObjClass( p[0], p[1], p[2], p[3] );
		else if ( len == 5 ) return new ObjClass( p[0], p[1], p[2], p[3], p[4] );
		else if ( len == 6 ) return new ObjClass( p[0], p[1], p[2], p[3], p[4], p[5] );
		throw new Error( "[ Pooler ] :: Too many constructor parameters!" );
	}

	public function toString():String {
		return StringUtils.format(
				"[ Pooler ] used={0} unused={1} size={2} ObjClass={3}", used, unused, size, ObjClass
		);
	}

	private function callFun( method:Object, o:Object ):void {
		if ( method is String ) {
			o[method]();
		} else if ( method is Function ) {
			var fun:Function = method as Function;
			if ( fun.length == 0 ) fun();
			else fun( o );
		}
	}


	//============================
	// accessors --
	//============================

	private var _cleaned:Callback;
	public function get cleaned():Callback {
		if ( !_cleaned ) _cleaned = new Callback();
		return _cleaned;
	}

	private var _flushed:Callback;
	public function get flushed():Callback {
		if ( !_flushed ) _flushed = new Callback();
		return _flushed;
	}

	private var _disposed:Callback;
	public function get disposed():Callback {
		if ( !_disposed ) _disposed = new Callback();
		return _disposed;
	}


	public function get used():int {
		return _size - _bufferSize;
	}

	public function get unused():int {
		return _bufferSize;
	}

	public function get size():int {
		return _size;
	}

	public function get ObjClass():Class {
		return _ObjClass;
	}

	//============================
	// factory --
	//============================
	public static function build( objClass:Class, constructorParams:Array = null, resetMethod:Object = null,
								  disposeMethod:Object = null, initSize:int = 0, maxSize:int = 0 ):Pooler {
		return new Pooler( objClass, initSize, maxSize, constructorParams, resetMethod, disposeMethod );
	}
}
}
