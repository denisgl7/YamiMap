/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/16/17.
 *
 */
package roipeker.callbacks {
public class Callback0 extends AbsCallback {
	public function Callback0() {
		super();
	}

	public function dispatch():void {
		for ( _iteratingDispatch = 0; _iteratingDispatch < _listenerCount;_iteratingDispatch++) {
			Function(_listeners[_iteratingDispatch])() ;
		}

		var onceCount:int = _listenersOnce.length ;
		for ( var i:int = onceCount; i >= 0; i-- ) {
			Function(_listenersOnce.removeAt(0))();
		}
	}
}
}
