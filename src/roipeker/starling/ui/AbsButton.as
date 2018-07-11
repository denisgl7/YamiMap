/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.starling.ui {
import roipeker.helpers.UIHelper;

import flash.geom.Rectangle;
import flash.ui.Mouse;
import flash.ui.MouseCursor;

import starling.display.ButtonState;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;

public class AbsButton extends AbsSprite {

	public static const INVALIDATE_HITQUAD:String = "hitquad";

	public var preventPropagation:Boolean = false;
	private var lastTouch:Touch;

	private var _state:String;
	private var _isOver:Boolean;
	private var _triggerBounds:Rectangle;

	public static var maxDragDistance:Number = 10;
	private var _isDown:Boolean;
	private var _wasDown:Boolean;
	public var dispatchAllEvents:Boolean = false;

	public var hitQuad:Quad;

	public function AbsButton(doc:Sprite = null ) {
		super( doc );
	}

	override protected function addedToStageHandler( event:Event ):void {
		super.addedToStageHandler( event );
		// activate by default
		activate( true );
	}

	override protected function initialize():void {
		super.initialize();
		touchGroup = true;
		useHandCursor = true;
		_enabled = true;
	}

	override public function activate( flag:Boolean ):void {
		super.activate( flag );
		UIHelper.listenerTouch( this, touchHandler, flag );
	}

	private function touchHandler( event:TouchEvent ):void {
		if ( preventPropagation ) {
			event.stopImmediatePropagation();
		}
		if ( !_enabled ) return;
		if ( useHandCursor ) {
			var useCursor:String = _enabled && event.interactsWith( this ) ? MouseCursor.BUTTON : MouseCursor.AUTO;
			if ( Mouse.cursor != useCursor && useCursor != MouseCursor.AUTO ) {
				Mouse.cursor = useCursor;
			}
		}

		var touch:Touch = event.getTouch( this );
		lastTouch = touch;
		if ( touch ) {
			if ( touch.phase == TouchPhase.BEGAN && _state != ButtonState.DOWN ) {
				_triggerBounds = getBounds( stage, _triggerBounds );
				_triggerBounds.inflate( maxDragDistance, maxDragDistance );
				_state = ButtonState.DOWN;
				_isDown = true;
				press();
				if ( dispatchAllEvents ) dispatchEventWith( UIDef.PRESS );
			} else if ( touch.phase == TouchPhase.MOVED ) {
				var isBounds:Boolean = _triggerBounds.contains( touch.globalX, touch.globalY );
				mouseMove( isBounds, _triggerBounds, touch.globalX, touch.globalY );
				if ( _state == ButtonState.DOWN && !isBounds ) {
					_state = ButtonState.UP;
					_isDown = false;
					if ( dispatchAllEvents ) dispatchEventWith( UIDef.RELEASE );
					release( false );
				} else if ( _state == ButtonState.UP && isBounds ) {
					_state = ButtonState.DOWN;
					_isDown = true;
					if ( dispatchAllEvents ) dispatchEventWith( UIDef.PRESS );
					press();
				}
			} else if ( touch.phase == TouchPhase.ENDED && _state == ButtonState.DOWN ) {
				_state = ButtonState.UP;
				_wasDown = true;
				_isDown = false;
				release( true );
				if ( dispatchAllEvents ) dispatchEventWith( UIDef.RELEASE );
				if ( !touch.cancelled ) {
					dispatchEventWith( Event.TRIGGERED, true, cid ? cid : cidx );// send cid, or cidx depends on what is defined.
				}
			}
		} else {
			if ( _state == ButtonState.DOWN ) {
				_isOver = false;
				release( false );
				if ( dispatchAllEvents ) dispatchEventWith( UIDef.RELEASE );
			} else if ( _state == ButtonState.OVER ) {
				_isOver = true;
			}
			_state = ButtonState.UP;
		}
	}

	private function mouseMove( inBounds:Boolean, rectangle:Rectangle, x:Number, y:Number ):void {
	}

	protected function press():void {
	}

	protected function release( flag:Boolean ):void {
	}

	public function cancelTouch():void {
		if ( _isDown ) release( false );
		_isDown = false;
		_isOver = false;
		_state = ButtonState.UP;
		_triggerBounds.setEmpty();
	}

	private var _hitQuadAlpha:Number = 0;
	private var _hitQuadOffset:Number = 10;

	public function get hitQuadAlpha():Number { return _hitQuadAlpha;}

	public function get hitQuadOffset():Number { return _hitQuadOffset;}

	public function set hitQuadAlpha( value:Number ):void {
		_hitQuadAlpha = value;
		setInvalidationFlag( INVALIDATE_HITQUAD );
	}

	public function set hitQuadOffset( value:Number ):void {
		_hitQuadOffset = value;
		setInvalidationFlag( INVALIDATE_HITQUAD );
	}

	public function addHitQuad():void {
		if ( hitQuad ) return;
		hitQuad = new Quad(10,10,0xffff00);
		setInvalidationFlag( INVALIDATE_HITQUAD );
		addChild( hitQuad );
	}

	override protected function draw():void {
		super.draw();
		if ( hitQuad && isInvalid( INVALIDATE_HITQUAD ) ) {
			hitQuad.alpha = _hitQuadAlpha;
			hitQuad.readjustSize( _w + _hitQuadOffset * 2, _h + _hitQuadOffset * 2 );
			hitQuad.x = -_hitQuadOffset
			hitQuad.y = -_hitQuadOffset
		}
	}

	public function removeHitQuad():void {
		if ( hitQuad ) {
			hitQuad.removeFromParent( true );
			hitQuad = null;
		}
	}

	protected var _selected:Boolean = false;

	override public function set enabled( value:Boolean ):void {
		super.enabled = value;
		touchable = value;
		invalidate( INVALIDATE_STATE );
	}

	public function get selected():Boolean {
		return _selected;
	}

	public function set selected( value:Boolean ):void {
		if ( _selected == value ) return;
		_selected = value;
		invalidate( INVALIDATE_SELECTED );
	}
}
}
