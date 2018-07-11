/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.starling.ui {
import starling.animation.IAnimatable;
import starling.core.Starling;

public class UIValidateQueue implements IAnimatable {

	private static var _instance:UIValidateQueue;
	public static function get instance():UIValidateQueue {
		if ( !_instance ) _instance = new UIValidateQueue();
		return _instance;
	}

	private var _starling:Starling;
	private var _isValidating:Boolean = false ;
	private var _queue:Array;

	public function UIValidateQueue() {
		_starling = Starling.current ;
		_queue = [] ;
	}

	public function advanceTime( time:Number ):void {
		if( _isValidating || !_starling.contextValid ) return ;
		var len:int = _queue.length ;
		if( len == 0 ) return ;
		_isValidating = true ;
		if( len > 1 ) _queue = _queue.sort(queueSort);
		while(_queue.length>0){
			var itm:AbsSprite = _queue.removeAt(0);
			if( itm.depth < 0 ) {
				// not added to stage.
				continue;
			}
			itm.validate() ;
		}
		_isValidating = false ;
	}

	public function addUI(ui:AbsSprite):void{
		// ui controls removes themselves after invalidation.
		if( !_starling.juggler.contains(this)) _starling.juggler.add(this);
		// already in queue.
		if (_queue.indexOf(ui)>=0) return ;
		var len:int = _queue.length;
		if( _isValidating ){
			var depth:int = ui.depth ;
			for( var i:int = len-1;i>=0;--i){
				var other:AbsSprite = _queue[i] as AbsSprite ;
				var otherDepth:int = other.depth ;
				if( depth > otherDepth ) break;
			}
			++i ;
			_queue.insertAt(i, ui);
		} else {
			_queue[len] = ui ;
		}
	}

	public function dispose():void{
		if( _starling ) {
			_starling.juggler.remove(this);
			_starling = null ;
		}
	}

	private function queueSort(first:AbsSprite,second:AbsSprite):int{
		var diff:int = second.depth - first.depth ;
		if( diff > 0 ) return -1 ;
		else if( diff < 0 ) return 1 ;
		return 0 ;
	}

	public function get isValidating():Boolean {return _isValidating;}
}
}
