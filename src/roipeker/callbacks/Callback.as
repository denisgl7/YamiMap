/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/16/17.
 *
 */
package roipeker.callbacks {
public class Callback extends AbsCallback {

	// slower, but more practical.
	private var _adaptArguments:Boolean;

	/**
	 * Constructor.
	 * @param adapt
	 */
	public function Callback(adapt:Boolean = false ) {
		_adaptArguments = adapt;
		super();
	}

	public function dispatch( ...args ):void {
		var fun:Function;
		var onceCount:int;
		var i:int;
		if ( _adaptArguments ) {
			var funLen:int;
			for ( _iteratingDispatch = 0; _iteratingDispatch < _listenerCount; _iteratingDispatch++ ) {
				fun = _listeners[_iteratingDispatch] as Function;
				funLen = fun.length;
				if ( funLen == 0 ) fun();
				else if ( funLen == 1 ) fun( args[0] );
				else if ( funLen == 2 ) fun( args[0], args[1] );
				else if ( funLen == 3 ) fun( args[0], args[1], args[2] );
			}
			onceCount = _listenersOnce.length - 1;
			for ( i = onceCount; i >= 0; i-- ) {
				fun = _listenersOnce.removeAt( 0 ) as Function;
				funLen = fun.length;
				if ( funLen == 0 ) fun();
				else if ( funLen == 1 ) fun( args[0] );
				else if ( funLen == 2 ) fun( args[0], args[1] );
				else if ( funLen == 3 ) fun( args[0], args[1], args[2] );
			}
		} else {
			for ( _iteratingDispatch = 0; _iteratingDispatch < _listenerCount; _iteratingDispatch++ ) {
				fun = _listeners[_iteratingDispatch] as Function;
				fun.apply( null, args );
			}
			onceCount = _listenersOnce.length - 1;
			for ( i = onceCount; i >= 0; i-- ) {
				fun = _listenersOnce.removeAt( 0 ) as Function;
				fun.apply( null, args );
			}
		}

	}
}
}
