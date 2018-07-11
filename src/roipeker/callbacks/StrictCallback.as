/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/16/17.
 *
 */
package roipeker.callbacks {
public class StrictCallback extends AbsCallback {

	public function StrictCallback() {
		super();
	}

	public function dispatch( ...args ):void {
		var fun:Function, argslen:uint = args.length, flen:uint;
		for ( _iteratingDispatch = 0; _iteratingDispatch < _listenerCount; _iteratingDispatch++ ) {
			// check length?
			fun = _listeners[_iteratingDispatch] as Function;
			flen = fun.length;
			if ( flen != argslen ) {
				throw new Error( "SimpeCallback ::: arguments doesnt match" );
			}
			if ( flen == 0 ) {
				fun();
			} else if ( flen == 1 ) {
				fun( args[0] );
			} else if ( flen == 2 ) {
				fun( args[0], args[1] );
			} else if ( flen == 3 ) {
				fun( args[0], args[1], args[2] );
			} else if ( flen == 4 ) {
				fun( args[0], args[1], args[2], args[3] );
			}
//			Function( _listeners[_iteratingDispatch] )();
		}

		var onceCount:int = _listenersOnce.length;
		for ( var i:int = onceCount; i >= 0; i-- ) {
			fun = _listenersOnce.removeAt( 0 ) as Function;
			flen = fun.length;
			if ( flen != argslen ) {
				throw new Error( "SimpeCallback ::: arguments doesnt match" );
			}
			if ( flen == 0 ) {
				fun();
			} else if ( flen == 1 ) {
				fun( args[0] );
			} else if ( flen == 2 ) {
				fun( args[0], args[1] );
			} else if ( flen == 3 ) {
				fun( args[0], args[1], args[2] );
			} else if ( flen == 4 ) {
				fun( args[0], args[1], args[2], args[3] );
			}
		}
	}
}
}
