/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/16/17.
 *
 */
package roipeker.callbacks {
public class Callback2 extends AbsCallback {
	public function Callback2(clase1:Class, clase2:Class ) {
		super( [clase1, clase2] );
	}

	public function dispatch( type1:Object, type2:Object ):void {
		for ( _iteratingDispatch = 0; _iteratingDispatch < _listenerCount; _iteratingDispatch++ ) {
			Function( _listeners[_iteratingDispatch] )( type1, type2 );
		}

		var onceCount:int = _listenersOnce.length;
		for ( var i:int = onceCount; i >= 0; i-- ) {
			Function( _listenersOnce.removeAt( 0 ) )( type1, type2 );
		}
	}
}
}
