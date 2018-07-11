// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package maps
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.MathUtil;
	
	public class TouchMap extends Sprite
	{
		
		private var _container:Sprite;
		public var touching:Boolean;
		private var movement:Point;
		private var disableMovement:Boolean;
		private var disableZooming:Boolean;
		private var disableRotation:Boolean = false;
		public var minimumScale:Number;
		public var maximumScale:Number;
		public var worldMinScale:Number = 0;
		public var mapBounds:Rectangle = new Rectangle();
		private var decelerationRatio:Number = .92;
		
		public static var MIN_SPEED:Number = .05;
		public static var MAX_SPEED:Number = 90;
		private var _map:YAMIMap;
		
		public function TouchMap(container:Sprite, map:YAMIMap)
		{
			_container = container;
			_map = map;
			addChild(container);
			init();
		}
		
		private function init():void
		{
			movement = new Point();
		}
		
		public function applyBounds():void
		{
			//        return ;
			var viewport:Rectangle = _map.viewport;
			if (mapBounds.x != 0 && mapBounds.y != 0 && viewport.x != 0 && viewport.y != 0)
			{
				// get transforms.
				var pivx:Number = pivotX;
				var pivy:Number = pivotY;
				var posx:Number = x;
				var posy:Number = y;
				var scale:Number = scaleX;
				
				var px:Number = pivx - posx / scale;
				var py:Number = pivy - posy / scale;
				//            trace('jump around?', x, y)
				if (px <= mapBounds.x)
				{
					x = (pivx - mapBounds.x) * scale;
				} else if (px + viewport.width >= mapBounds.right)
				{
					x = (pivx - mapBounds.right + viewport.width) * scale;
				}
				if (py <= mapBounds.y)
				{
					y = (pivy - mapBounds.y) * scale;
				} else if (py + viewport.height >= mapBounds.bottom)
				{
					y = (pivy - mapBounds.bottom + viewport.height) * scale;
				}
				
			}
		}
		
		public function handleEnterFrame(e:Event):void
		{
			/*var allowMovement:Boolean = movement.x > MIN_SPEED || movement.x < -MIN_SPEED &&
					movement.y > MIN_SPEED || movement.y < -MIN_SPEED ;*/
			var allowMovement:Boolean = movement.x != 0 || movement.y != 0;
			var isMoving:Boolean = !touching && allowMovement;
			if (isMoving)
			{
				movement.x *= decelerationRatio;
				movement.y *= decelerationRatio;
				if (Math.abs(movement.x) < MIN_SPEED) movement.x = 0;
				if (Math.abs(movement.y) < MIN_SPEED) movement.y = 0;
				x += movement.x;
				y += movement.y;
				//            applyBounds();
			}
		}
		
		public function handleTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this, TouchPhase.BEGAN);
			if (touch)
			{
				if (!touching)
				{
					dispatchEventWith("touchStatus", false, true);
					touching = true;
					movement.setTo(0, 0);
				}
			}
			
			var touches:Vector.<Touch> = e.getTouches(this, TouchPhase.MOVED);
			if (touches.length == 0)
			{
				if (e.getTouch(this, TouchPhase.ENDED))
				{
					if (touching)
					{
						dispatchEventWith("touchStatus", false, false);
						touching = false;
					}
					
				}
			} else if (touches.length == 1)
			{
				// one finger touching -> move
				touches[0].getMovement(parent, movement);
				if (!disableMovement)
				{
					movement.x = MathUtil.clamp(movement.x, -MAX_SPEED, MAX_SPEED);
					movement.y = MathUtil.clamp(movement.y, -MAX_SPEED, MAX_SPEED);
					x += movement.x;
					y += movement.y;
				}
				if (!touching)
				{
					dispatchEventWith("touchStatus", false, true);
				}
				touching = true;
				
			} else if (touches.length == 2)
			{
				if (!touching)
				{
					dispatchEventWith("touchStatus", false, true);
				}
				touching = true;
				//            dragging = true ;
				// two fingers touching -> rotate and myscale
				var touchA:Touch = touches[0];
				var touchB:Touch = touches[1];
				var currentPosA:Point = touchA.getLocation(parent);
				var previousPosA:Point = touchA.getPreviousLocation(parent);
				var currentPosB:Point = touchB.getLocation(parent);
				var previousPosB:Point = touchB.getPreviousLocation(parent);
				
				var currentVector:Point = currentPosA.subtract(currentPosB);
				var previousVector:Point = previousPosA.subtract(previousPosB);
				
				var currentAngle:Number = Math.atan2(currentVector.y, currentVector.x);
				var previousAngle:Number = Math.atan2(previousVector.y, previousVector.x);
				var deltaAngle:Number = currentAngle - previousAngle;
				
				// update pivot point based on previous center
				var previousLocalA:Point = touchA.getPreviousLocation(this);
				var previousLocalB:Point = touchB.getPreviousLocation(this);
				if (!disableMovement && !disableZooming)
				{
					pivotX = (previousLocalA.x + previousLocalB.x) * 0.5;
					pivotY = (previousLocalA.y + previousLocalB.y) * 0.5;
					
					// update location based on the current center
					x = (currentPosA.x + currentPosB.x) * 0.5;
					y = (currentPosA.y + currentPosB.y) * 0.5;
				}
				
				// rotate
				if (!disableRotation)
				{
					dispatchEventWith(Event.CHANGE);
					rotation += deltaAngle;
				}
				
				// myscale
				if (!disableZooming)
				{
					var sx:Number = scaleX;
					var sizeDiff:Number = currentVector.length / previousVector.length;
					sx *= sizeDiff;
					//                this.scaleX *= sizeDiff;
					//                this.scaleY *= sizeDiff;
					if (minimumScale && minimumScale >= sx)
					{
						trace('contstraining', minimumScale);
						sx = minimumScale;
					} else if (worldMinScale && worldMinScale > sx)
					{
						sx = worldMinScale;
					}
					if (maximumScale && maximumScale < sx)
					{
						sx = maximumScale;
					}
					scaleX = scaleY = sx;
				}
			}
			//        applyBounds();
		}
		
		public function setMapBounds(rect:Rectangle):void
		{
			if (!rect)
			{
				mapBounds.setEmpty();
			} else
			{
				mapBounds.x = GeoUtils.lon2x(rect.x);
				mapBounds.y = GeoUtils.lat2y(rect.y);
				mapBounds.right = GeoUtils.lon2x(rect.width);
				mapBounds.bottom = GeoUtils.lat2y(rect.height);
				constrainScale();
			}
		}
		
		public function constrainScale():void
		{
			if (mapBounds.x)
			{
				minimumScale = Math.max(_map.w / (mapBounds.right - mapBounds.left), _map.h / (mapBounds.top - mapBounds.bottom));
				trace("min scale is", minimumScale);
				scaleX = scaleY = MathUtil.max(scaleX, minimumScale);
			}
		}
	}
}
