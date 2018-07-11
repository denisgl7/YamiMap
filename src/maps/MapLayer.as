// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package maps
{
	import flash.geom.Rectangle;
	
	import maps.config.AbsLayerProvider;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.utils.MathUtil;
	
	public class MapLayer extends Sprite
	{
		
		public function MapLayer(config:AbsLayerProvider)
		{
			super();
			this._provider = config;
			init();
			touchGroup = true;
		}
		public var map:YAMIMap;
		var sx:int;
		var ex:int;
		var sy:int;
		var ey:int;
		//    private var urlTemplate:String;
		private var _tiles:Array;
		private var _tilesHash:Object = {};
		
		private var _provider:AbsLayerProvider;

		public function get provider():AbsLayerProvider
		{
			return _provider;
		}

		public function refresh():void
		{
			removeUnused();
			checkTiles();
		}

		private function init():void
		{
			//        urlTemplate = YAMIMap.GOOGLE_TEMPLATE;
			_tiles = [];
		}
		
		private function checkTiles():void
		{
			var viewport:Rectangle = map.viewport;
			var zoom:uint = map.zoom;
			var scale:Number = map.scaleRatio;
			var scaledTileSize:Number = _provider.tileSize * scale;
			
			/*var sx:int = Math.floor(viewport.x / scaledTileSize);
			var ex:int = Math.ceil((viewport.x + viewport.width) / scaledTileSize);
			var sy:int = Math.floor(viewport.y / scaledTileSize);
			var ey:int = Math.ceil((viewport.y + viewport.height) / scaledTileSize);*/
			
			sx = Math.floor(viewport.x / scaledTileSize);
			ex = Math.ceil((viewport.x + viewport.width) / scaledTileSize);
			sy = Math.floor(viewport.y / scaledTileSize);
			ey = Math.ceil((viewport.y + viewport.height) / scaledTileSize);
			
			//        if( _tiles.length ) return ;
			//        trace("Miewrasdadasd", _tiles.length );
			
			var i:int, j:int;
			var createdCounter:int = 0;
			for (i = sx; i < ex; ++i)
			{
				for (j = sy; j < ey; ++j)
				{
					if (createTile(i, j, scaledTileSize, zoom, scale))
					{
						createdCounter++;
					}
				}
			}
			
			if (createdCounter > 0)
			{
				trace('used tiles::', MapTile.getUsed());
				_tiles = _tiles.sortOn('loadPriority', Array.NUMERIC);
				// apply a delay of 0.2;
				var pendingTiles:int = 0;
				for (i = 0; i < _tiles.length; i++)
				{
					var item:MapTile = _tiles[i];
					if (item.loadPriority < 1)
					{
						item.load(pendingTiles * 0.01);
						if (item.loadPriority > 0)
						{
							++pendingTiles;
						}
					}
				}
			}
		}
		
		private function createTile(x:int, y:int, scaledTileSize:Number, zoom:uint, scale:Number):Boolean
		{
			//        trace('applying zom:',zoom);
			var key:String = getKey(x, y, zoom);
			if (_tilesHash[key])
			{
				return false;
			}
			//        trace('new tile:', key );
			var tile:MapTile = MapTile.get(key, this);
			tile.textureFormat = _provider.textureFormat;
			tile.textureScale = _provider.textureScale;
			tile.tileSize = _provider.tileSize;
			tile.scale = scale;
			//        trace("Scale is:", scale, map.toucher.scaleX );
			tile.zoom = zoom;
			
			//        trace("scaled tilesize:", scaledTileSize );
			
			// position tile.
			tile.x = x * scaledTileSize;
			tile.y = y * scaledTileSize;
			
			var relZoom:int = map.maxZoomLevel - zoom + 1;
			//        var relZoom:int = provider.maxZoomLevel - zoom + 1;
			tile.debugPosition(x, y, relZoom);
			
			// x rel to screen coords.
			//        trace( sx, ex, x, y, relZoom );
			//        var diffX:int = ex-sx;
			//        var diffY:int = ey-sy;
			
			/*var relX:Number = ex-sx >> 1;
			var relY:Number = ex-sx >> 1;
			var cx:Number= sx + relX;
			var cy:Number= sy + relY;
			var dx:Number = x-cx;
			var dy:Number = y-cy;*/
			
			//        var dist:Number = Math.sqrt(dx*dx+dy*dy);
			//var alp:Number = dist/relX;
			//        trace("viewport ", map.viewport );
			
			var viewport:Rectangle = map.viewport;
			var cx:Number = viewport.x + (viewport.width / 2);
			var cy:Number = viewport.y + (viewport.height / 2);
			
			var dx:Number = (tile.x + scaledTileSize / 2) - cx;
			var dy:Number = (tile.y + scaledTileSize / 2) - cy;
			var d:Number = Math.sqrt(dx * dx + dy * dy);
			
			var max:Number = MathUtil.max(viewport.width, viewport.height);
			var r:Number = d / max;
			tile.loadPriority = r;
			//        tile.alpha = r ;
			
			var url:String = _provider.resolveUrl(x, y, relZoom);
			tile.setUrl(url);
			//        tile.load();
			addChild(tile);
			_tiles.push(tile);
			_tilesHash[key] = tile;
			return true;
		}
		
		[Inline]
		private function getKey(x:int, y:int, zoom:uint):String
		{
			return zoom + "x" + x + "x" + y;
		}
		
		private function removeUnused():void
		{
			var viewport:Rectangle = map.viewport;
			var zoom:int = map.zoom;
			var len:int = _tiles.length;
			var tile:MapTile;
			for (var i:int = len - 1; i >= 0; i--)
			{
				tile = _tiles[i];
				//            trace("diff zoom", tile.zoom - zoom);
				//            if (!viewport.intersects(tile.bounds)) {
				if (!viewport.intersects(tile.bounds) || tile.zoom != zoom)
				{
					// remove tile.
					_tiles.removeAt(i);
					_tilesHash[tile.key] = null;
					delete _tilesHash[tile.key];
					tile.returnPool(true);
				}
			}
		}
		
		public function handleEnterFrame(e:Event):void
		{
			if (map.invalidateZoom || map.invalidatePosition)
			{
				removeUnused();
				checkTiles();
			}
		}
	}
}
