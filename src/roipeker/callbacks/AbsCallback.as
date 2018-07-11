/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/16/17.
 *
 */
package roipeker.callbacks {
public class AbsCallback {

	// irrelevant.
	protected var _valueClasses:Array;

	protected var _listenersOnce:Array;
	protected var _listeners:Array;
	protected var _listenerCount:uint = 0;
	protected var _iteratingDispatch:uint = 0;

	public function AbsCallback(classes:Array = null ) {
		_valueClasses = !classes ? [] : classes;
		_listeners = [];
		_listenersOnce = [];
	}

	public function has( listener:Function ):Boolean {
//		asd /**/
		return _listeners.indexOf( listener ) > -1 || _listenersOnce.indexOf( listener ) > -1;
	}

	public function hasListeners():Boolean {
		return _listeners.length > 0 || _listenersOnce.length > 0;
	}

	public function add( listener:Function ):void {
		if ( listener && _listeners.indexOf( listener ) == -1 && _listenersOnce.indexOf( listener ) == -1 ) {
			_listeners[_listeners.length] = listener;
			_listenerCount++;
		}
	}

	public function addOnce( listener:Function ):void {
		if ( listener && _listeners.indexOf( listener ) == -1 && _listenersOnce.indexOf( listener ) == -1 ) {
			_listenersOnce[_listenersOnce.length] = listener;
		}
	}

	// the lower the better.
	public function addWithPriority( listener:Function, priority:int = 0 ):void {
		if ( listener && _listeners.indexOf( listener ) == -1 && _listenersOnce.indexOf( listener ) == -1 ) {
			priority = Math.max( 0, _listeners.length );
			_listeners.insertAt( priority, listener );
			_listenerCount++;
		}
	}

	public function remove( listener:Function ):void {
		var idx:int = _listeners.indexOf( listener );
		if ( idx >= 0 ) {
			if ( idx <= _iteratingDispatch ) _iteratingDispatch--;
			_listeners.removeAt( idx );
			_listenerCount--;
		} else {
			_listenersOnce.removeAt( _listenersOnce.indexOf( listener ) );
		}
	}

	public function removeAll():void {
		_listeners = [];
		_listenersOnce = [];
		_listenerCount = 0;
	}

	public function dispose():void {
		_listeners = null;
		_listenersOnce = null;
		_listenerCount = 0;
	}
}
}
