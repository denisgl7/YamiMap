package
{
	import maps.MapLiner;
	import maps.MapUtils;
	import maps.YAMIMap;
	import maps.config.GoogleMapsProvider;
	import maps.geo.LatLng;
	import maps.utils.GooglePolylineDencoder;
	
	import roipeker.utils.BasicShape;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public class YamiMap extends Sprite
	{
		
		public function YamiMap()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
		}
		
		private function onAddToStage(event:Event):void
		{
			this.createYamiMap();
		}
		
		private var map:YAMIMap;
		private var path:MapLiner;
		
		private function createYamiMap():void
		{
			
			map = new YAMIMap(stage.stageWidth, stage.stageHeight, this);
			var provider:GoogleMapsProvider = new GoogleMapsProvider(GoogleMapsProvider.MAPTYPE_ROADMAP, 2, 'ru-RU');
			
			provider.useFileCache = true;
			provider.useMemCache = false;
			map.addLayerByProvider(provider);
			map.setCenter(new LatLng(64.560139, 39.815226));
			var q:Quad = new Quad(20, 20, 0xff0000);
			map.addMarkerAtCoords('uno', 64.560139, 39.815226, q, {title: "pepe"});
			map.setZoom(14);
			var directionsString:String = "cw|fFulxoCaDSWYEOAIM?}DOP}Cp@uJb@yF@K]I_AQqBa@mE{@kDq@cDy@_EcAgEkAqBc@i@IgACy@AuDN}DTSBOG}@PkARu@PWJ}AXiCz@QBsAW{E_@eDi@U?s@GkASwBc@y@]eAc@wAs@gDgBgEkBkAk@]Ys@g@s@[GCT_Bx@uGHq@BcA@{@O?BuC@aAHcE?K]CW?q@a@]SmAu@kCcCsAiAGQo@g@IKKFa@TKLs@^cAx@a@n@Wj@]fAQx@Ob@Cv@@`@Rp@"
			
			var directionsArr:Array = GooglePolylineDencoder.decode(directionsString);
			var arr:Array = MapUtils.makeLatLngFromList(directionsArr);
			path = new MapLiner();
			path.setLatLngData(arr);
			path.lineStyleTexture(BasicShape.createRectDotTexture(4, 10, 4), 0x1b76bc, 4);
			map.addPath(path);
		}
	}
}
