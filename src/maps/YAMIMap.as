// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package maps
{
	import com.greensock.TweenMax;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import maps.config.AbsLayerProvider;
	import maps.geo.LatLng;
	
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.MathUtil;
	import starling.utils.MatrixUtil;
	
	public class YAMIMap extends Sprite
	{
		
		private var _w:int;
		private var _h:int;
		private var bg:Quad;
		
		private var centerBackup:Point = new Point();
		public var toucher:TouchMap;
		private var _viewport:Rectangle = new Rectangle();
		private var mapContainer:Sprite;
		private var _layers:Array = [];
		private var _active:Boolean;
		
		private var _zoom:uint = 0;
		private var _scaleRatio:Number = 0;
		private var prevTouchScale:Number;
		private var prevTouchPos:Point = new Point();
		private var prevTouchPivot:Point = new Point();
		
		public var invalidateZoom:Boolean;
		public var invalidatePosition:Boolean;
		public var invalidateAll:Boolean;
		
		private var _msk:Quad;
		private var _maxZoomLevel:int = 21;
		private var _pathContainer:Sprite;
		private var changedZoom:Boolean;
		
		// wrong name.
		
		public function YAMIMap(w:int, h:int, doc:Sprite = null)
		{
			super();
			if (doc) doc.addChild(this);
			init();
			setSize(w, h);
		}
		
		private function invalidate():void
		{
			bg.width = _w;
			bg.height = _h;
			_msk.width = _w;
			_msk.height = _h;
			toucher.constrainScale();
		}
		
		private function init():void
		{
			bg = new Quad(100, 100, 0xdddddd);
			_msk = new Quad(100, 100, 0x00ff00);
			
			mapContainer = new Sprite();
			toucher = new TouchMap(mapContainer, this);
			_markersContainer = new Sprite();
			_circContainer = new Sprite();
			_pathContainer = new Sprite();
			_pathContainer.scale = 1 / 2;
			mapContainer.addChild(_pathContainer);
			mapContainer.addChild(_circContainer);
			mapContainer.addChild(_markersContainer);
			
			addChild(bg);
			addChild(toucher);
			addChild(_msk);
			toucher.mask = _msk;
			
			activate(true);
			maxZoomLevel = _maxZoomLevel;
			this.addEventListener(Event.CHANGE, onMapRotation);
		}
		
		private function onMapRotation(event:Event):void
		{
			invalidateAll = true;
		}
		
		public function activate(flag:Boolean):void
		{
			_active = flag;
			var method:String = flag ? 'addEventListener' : 'removeEventListener';
			this[method](EnterFrameEvent.ENTER_FRAME, handleEnterFrame);
			this[method](TouchEvent.TOUCH, handleTouch);
			toucher[method]("touchStatus", toucherStatus);
		}
		
		private function toucherStatus(e:Event, touching:Boolean):void
		{
			if (!touching)
			{
				/*var len:int = _layers.length;
				for (var i:int = 0; i < len; i++) {
					// validate if touch ends.
					MapLayer(_layers[i]).refresh();
				}*/
			}
		}
		
		private var _pntCenter:Point = new Point();
		
		public function getCenter():Point
		{
			_pntCenter.x = _viewport.x + _viewport.width / 2;
			_pntCenter.y = _viewport.y + _viewport.height / 2;
			return _pntCenter;
		}
		
		public function getCenterLatLng():LatLng
		{
			_pntCenter.x = _viewport.x + _viewport.width / 2;
			_pntCenter.y = _viewport.y + _viewport.height / 2;
			return new LatLng(GeoUtils.y2lat(_pntCenter.y), GeoUtils.x2lon(_pntCenter.x));
		}
		
		public function zoomCenter(factor:Number = 1):void
		{
			var z:Number = _zoom + factor;
			z = getZoomScale(z);
			setCenterXY(_viewport.x + _viewport.width / 2, _viewport.y + _viewport.height / 2);
			TweenMax.to(toucher, .5, {scale: z, onComplete: forceRender});
		}
		
		private function forceRender():void
		{
			invalidateAll = true;
		}
		
		private function handleTouch(e:TouchEvent):void
		{
			// see if we touch a marker.
			var touch:Touch;
			touch = e.getTouch(_markersContainer, TouchPhase.ENDED);
			
			if (touch)
			{
				var displayObject:DisplayObject = touch.target;
				if (displayObject && displayObject.parent.parent == _markersContainer)
				{
					//                trace("OK!", displayObject);
					//                var marker:MapMarker = getMarker(displayObject.parent.name);
					dispatchEventWith("markerTriggered", false, displayObject.parent);
				}
			} else
			{
				toucher.handleTouch(e);
			}
			
		}
		
		private function handleEnterFrame(e:Event):void
		{
			// apply transformations.
			toucher.handleEnterFrame(e);
			invalidateZoom = toucher.scaleX != prevTouchScale;
			invalidatePosition =
					toucher.x != prevTouchPos.x ||
					toucher.y != prevTouchPos.y ||
					toucher.pivotX != prevTouchPivot.x ||
					toucher.pivotY != prevTouchPivot.y;
			
			// validate if we rescale the toucher.
			if (invalidateZoom)
			{
				changedZoom = false;
				var buffZoom:uint = _zoom;
				updateZoom();
				changedZoom = _zoom != buffZoom;
			}
			
			if (invalidateAll || invalidateZoom || invalidatePosition)
			{
				getBounds(toucher, _viewport);
			}
			
			if (invalidateAll || invalidateZoom || invalidatePosition)
			{
				updateMarkers();
			}
			
			//        if (!toucher.touching) {
			var len:int = _layers.length;
			for (var i:int = 0; i < len; i++)
			{
				// validate if touch ends.
				MapLayer(_layers[i]).handleEnterFrame(e);
			}
			//        }
			
			invalidateAll = false;
			toucher.applyBounds();
			//        changedZoom = false ;
			prevTouchPos.x = toucher.x;
			prevTouchPos.y = toucher.y;
			prevTouchPivot.x = toucher.pivotX;
			prevTouchPivot.y = toucher.pivotY;
		}
		
		private function updateMarkers():void
		{
			var invSX:Number = 1 / toucher.scaleX;
			var len:int = _markersContainer.numChildren;
			var marker:DisplayObject;
			var i:int;
			for (i = 0; i < len; i++)
			{
				marker = _markersContainer.getChildAt(i);
				marker.visible = _viewport.intersects(marker.bounds);
				trace(_scaleHash[marker.name]);
				marker.scale = invSX * _scaleHash[marker.name];
				//	        marker.scale = invSX;
				marker.rotation = -toucher.rotation;
			}
			
			len = _circContainer.numChildren;
			const minRenderThreshold:Number = 10;
			for (i = 0; i < len; i++)
			{
				marker = _circContainer.getChildAt(i);
				var circ:MapCircOverlay = _circhash[marker.name];
				var inMap:Boolean = _viewport.intersects(marker.bounds);
				var scaled:Number = marker.width * toucher.scaleX;
				marker.visible = inMap && (scaled > minRenderThreshold);
			}
			
			if (invalidateAll || invalidateZoom)
			{
				//      if (invalidateAll || (invalidateZoom && changedZoom)) {
				len = _paths.length;
				for (i = 0; i < len; i++)
				{
					var path:MapLiner = _paths[i];
					path.updateScaleRender();
				}
			}
		}
		
		public function addLayerByProvider(layerProvider:AbsLayerProvider):MapLayer
		{
			return addLayer(new MapLayer(layerProvider));
		}
		
		public function addLayer(layer:MapLayer):MapLayer
		{
			mapContainer.addChild(layer);
			mapContainer.addChild(_pathContainer);
			mapContainer.addChild(_circContainer);
			mapContainer.addChild(_markersContainer);
			layer.map = this;
			// detect if it exists.
			if (_layers.indexOf(layer) == -1) _layers.push(layer);
			return layer;
		}
		
		public var centrLatLng:LatLng = new LatLng(0, 0);
		
		public function setCenter(latlng:LatLng):void
		{
			centrLatLng = latlng;
			setCenterXY(latlng.worldX, latlng.worldY);
		}
		
		public function setCenterLatLon(lat:Number, lon:Number):void
		{
			setCenterXY(GeoUtils.lon2x(lon), GeoUtils.lat2y(lat));
		}
		
		private function updateZoom():void
		{
			_zoom = _scaleRatio = 1;
			var sx:Number = toucher.scaleX;
			var z:int = 1 / sx;
			while (_scaleRatio < z) _scaleRatio <<= 1;
			var s:uint = _scaleRatio;
			while (s > 1)
			{
				s >>= 1;
				++_zoom;
			}
			trace("updateZoom:", _scaleRatio, _zoom, sx);
			prevTouchScale = sx;
		}
		
		private function setCenterXY(x:Number, y:Number):void
		{
			centerBackup.setTo(x, y);
			toucher.pivotX = x;
			toucher.pivotY = y;
			toucher.x = _w >> 1;
			toucher.y = _h >> 1;
		}
		
		public function setSize(w:int, h:int):void
		{
			_w = w;
			_h = h;
			invalidate();
		}
		
		private var HELPER_POINT:Point = new Point();
		private var HELPER_MATRIX:Matrix = new Matrix();
		private var _mapBounds:Rectangle;
		
		// feathers stuffs.
		override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle
		{
			if (!resultRect)
			{
				resultRect = new Rectangle();
			}
			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
			if (targetSpace == this) // optimization
			{
				minX = 0;
				minY = 0;
				maxX = this._w;
				maxY = this._h;
			}
			else
			{
				var matrix:Matrix = HELPER_MATRIX;
				getTransformationMatrix(targetSpace, matrix);
				MatrixUtil.transformCoords(matrix, 0, 0, HELPER_POINT);
				minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
				maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
				minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
				maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;
				MatrixUtil.transformCoords(matrix, 0, this._h, HELPER_POINT);
				minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
				maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
				minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
				maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;
				MatrixUtil.transformCoords(matrix, this._w, 0, HELPER_POINT);
				minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
				maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
				minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
				maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;
				MatrixUtil.transformCoords(matrix, this._w, this._h, HELPER_POINT);
				minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
				maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
				minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
				maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;
				matrix.identity();
			}
			resultRect.x = minX;
			resultRect.y = minY;
			resultRect.width = maxX - minX;
			resultRect.height = maxY - minY;
			return resultRect;
		}
		
		public function setZoomBounds(minZoom:int = -1, maxZoom:int = -1):void
		{
			var scaleMin:Number;
			var scaleMax:Number;
			
			if (minZoom > -1)
			{
				scaleMax = getZoomScale(minZoom);
			}
			if (maxZoom > -1)
			{
				scaleMin = getZoomScale(maxZoom);
			}
			toucher.maximumScale = scaleMax;
			toucher.minimumScale = scaleMin;
			toucher.scale = MathUtil.clamp(toucher.scaleX, scaleMin, scaleMax);
		}
		
		private function getZoomScale(level:int):Number
		{
			var scale:Number = 1;
			if (level <= 0) return scale;
			// constrain max?
			var len:int = level - 1;
			for (var i:int = 0; i < len; i++)
			{
				scale *= 0.5;
			}
			//        trace('scale is:', scale, level);
			return scale;
		}
		
		public function get viewport():Rectangle
		{
			return _viewport;
		}
		
		public function get zoom():uint
		{
			return _zoom;
		}
		
		public function get scaleRatio():Number
		{
			return _scaleRatio;
		}
		
		public function setZoom(level:int):void
		{
			var scale:Number = getZoomScale(_maxZoomLevel - level + 1);
			toucher.scale = MathUtil.clamp(scale, toucher.minimumScale, toucher.maximumScale);
		}
		
		public function set mapBounds(mapBounds:Rectangle):void
		{
			_mapBounds = mapBounds;
			toucher.setMapBounds(mapBounds);
		}
		
		public function get mapBounds():Rectangle
		{
			return _mapBounds;
		}
		
		/* public function get _textureScale():Number {
			 return _textureScale;
		 }
	
		 public function set _textureScale(value:Number):void {
			 // this is ONLY valid for maps that supports retina reoslution.
			 if (value <= 0 ) value = 1;
			 // max scale 4 in Google.
			 if( value > 4 ) value = 4 ;
			 else if( value < .125 ) value = .125 ;
			 _textureScale = value;
			 MapTileLoader._textureScale = value;
		 }*/
		
		public function get w():int
		{
			return _w;
		}
		
		public function get h():int
		{
			return _h;
		}
		
		public function get maxZoomLevel():int
		{
			return _maxZoomLevel;
		}
		
		public function set maxZoomLevel(value:int):void
		{
			_maxZoomLevel = value;
			GeoUtils.setMaxZoom(_maxZoomLevel);
			toucher.worldMinScale = 1 / Math.pow(2, _maxZoomLevel - 1);
		}
		
		private var _markersDisplay:Array = [];
		private var _markersArray:Array = [];
		private var _circDisplay:Array = [];
		private var _markersContainer:Sprite;
		private var _circContainer:Sprite;
		private var _markersHash:Object = {};
		private var _circhash:Object = {};
		private var map:Dictionary = new Dictionary();
		
		public function addMarkerLatLng(id:String, latlng:LatLng, displayObj:DisplayObject, data:Object = null):MapMarker
		{
			return addMarkerXY(id, latlng.worldX, latlng.worldY, displayObj, data);
		}
		
		public function addMarkerAtCoords(id:String, lat:Number, long:Number, displayObj:DisplayObject, data:Object = null):MapMarker
		{
			return addMarkerXY(id, GeoUtils.lon2x(long), GeoUtils.lat2y(lat), displayObj, data);
		}
		
		public function addCircCoords(id:String, lat:Number, lon:Number, radius:Number, displayObj:DisplayObject, data:Object):MapMarker
		{
			var tx:Number = GeoUtils.lon2x(lon);
			var ty:Number = GeoUtils.lat2y(lat);
			var latlon90:Point = GeoUtils.destionationDeg(lon, lat, 90, radius);
			var edgeLon:Number = latlon90.x;
			var edgeLat:Number = latlon90.y;
			
			//        var midX:Number = GeoUtils.lon2x(lon);
			//        var midY:Number = GeoUtils.lat2y($lat);
			
			var edgeX:Number = GeoUtils.lon2x(edgeLon);
			var edgeY:Number = GeoUtils.lat2y(edgeLat);
			
			var numRadiusDistance:Number = (tx > edgeX) ? tx - edgeX : edgeX - tx;
			var numDistance:Number = numRadiusDistance * 2;
			
			displayObj.width = displayObj.height = radius;
			return addCircXY(id, tx, ty, displayObj, numDistance, data);
		}
		
		public function addCircXY(id:String, x:Number, y:Number, displayObj:DisplayObject, size:Number, data:Object):MapMarker
		{
			displayObj.name = id;
			displayObj.x = x;
			displayObj.y = y;
			_circContainer.addChild(displayObj);
			var mapCircle:MapCircOverlay = new MapCircOverlay(id, displayObj, data);
			mapCircle.size = size;
			_circhash[id] = mapCircle;
			_circDisplay.push(displayObj);
			return mapCircle;
		}
		
		private var initialScaleArray:Array = [];
		private var _scaleHash:Object = {};
		
		public function addMarkerXY(id:String, x:Number, y:Number, displayObj:DisplayObject, data:Object):MapMarker
		{
			displayObj.name = id;
			displayObj.x = x;
			displayObj.y = y;
			_scaleHash[id] = displayObj.scale;
			//        trace('adding marker:', x, y);
			_markersDisplay.push(displayObj);
			_markersDisplay = _markersDisplay.sortOn('y', Array.NUMERIC);
			var idx:int = _markersDisplay.indexOf(displayObj);
			_markersContainer.addChildAt(displayObj, idx);
			var mapMarker:MapMarker = createMarker(id, displayObj, data);
			_markersArray.push(mapMarker);
			_markersHash[id] = mapMarker;
			
			invalidateAll = true;
			return mapMarker;
		}
		
		private function createMarker(id:String, displayObj:DisplayObject, data:Object = null):MapMarker
		{
			return new MapMarker(id, displayObj, data);
		}
		
		private var _paths:Array = [];
		
		public function addPath(path:MapLiner):void
		{
			_paths.push(path);
			_pathContainer.addChild(path);
			path.map = this;
			invalidateAll = true;
		}
		
		public function clearPaths(dispose:Boolean = false):void
		{
			_pathContainer.removeChildren(0, -1, dispose);
			_paths = [];
			invalidateAll = true;
			
		}
		
		public function removeMarker(displayObj:DisplayObject):void
		{
			displayObj.removeFromParent();
			_markersDisplay.splice(_markersDisplay.indexOf(displayObj));
			_markersDisplay = _markersDisplay.sortOn('y', Array.NUMERIC);
			var currentCount:int;
			for (var i:int = 0; i < _markersArray.length; i++)
			{
				if (_markersArray[i].displayObject == displayObj)
					currentCount = i;
			}
			_markersArray.splice(currentCount);
			invalidateAll = true;
		}
		
	}
}
