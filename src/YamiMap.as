package
{
	import cz.j4w.map.MapLayerOptions;
	import cz.j4w.map.MapOptions;
	import cz.j4w.map.geo.GeoMap;
	import cz.j4w.map.geo.GeoUtils;
	import cz.j4w.map.geo.Maps;
	
	import feathers.controls.LayoutGroup;
	
	import flash.geom.Point;
	
	import maps.YAMIMap;
	import maps.config.GoogleMapsProvider;
	import maps.geo.LatLng;
	
	import starling.assets.AssetManager;
	import starling.display.Image;
	import starling.textures.Texture;
	
	public class YamiMap extends LayoutGroup
	{
		private static var sAssets:AssetManager;
		public function start(assets:AssetManager):void
		{
			sAssets = assets;
			super.initialize();
			
			this.createYamiMap();
//			this.createFeathersMap();
		}
		
		private var map:YAMIMap;
		private var mainRoadMarker:Image;
		private function createYamiMap():void
		{
			
			map = new YAMIMap(stage.stageWidth, stage.stageHeight, this);
			
			var provider:GoogleMapsProvider = new GoogleMapsProvider(GoogleMapsProvider.MAPTYPE_ROADMAP, 2, 'ru-RU');
			provider.useFileCache = true;
			provider.useMemCache = false;
			map.addLayerByProvider(provider);
			map.setZoom(18);
			map.maxZoomLevel = 18;
			
			mainRoadMarker = new Image(Texture.fromColor(10, 10));
			mainRoadMarker.alignPivot();
			mainRoadMarker.scale = 0.2;
			map.addMarkerAtCoords('address', 64.546472, 39.765013, mainRoadMarker);
			var pos:LatLng = new LatLng(64.546472, 39.765013);
			map.setCenter(pos);
		}
		
		private function createFeathersMap():void
		{
			var mapOptions:MapOptions = new MapOptions();
			mapOptions.initialCenter = new Point(39.765013, 64.546472);
			mapOptions.initialScale = 1 / 32;
			mapOptions.disableRotation = true;
			
			var geoMap:GeoMap = new GeoMap(mapOptions);
			geoMap.setSize(stage.stageWidth, stage.stageHeight);
			addChild(geoMap);
			
			var mapScale:Number = 2; // use 1 for non-retina displays
			GeoUtils.scale = mapScale;
			
			var googleMaps:MapLayerOptions = Maps.GOOGLE_MAPS_SCALED(mapScale);
			googleMaps.notUsedZoomThreshold = 1;
			geoMap.addLayer("googleMaps", googleMaps);
		}
	}
}
