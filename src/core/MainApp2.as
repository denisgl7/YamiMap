// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package core
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Expo;
	import com.greensock.plugins.HexColorsPlugin;
	import com.greensock.plugins.TweenPlugin;
	
	import flash.ui.Keyboard;
	
	import maps.MapLiner;
	import maps.MapTileLoader;
	import maps.MapUtils;
	import maps.YAMIMap;
	import maps.config.GoogleMapsProvider;
	import maps.config.HereWeGoProvider;
	import maps.config.MapBoxProvider;
	import maps.config.OpenWeatherProvider;
	import maps.config.osm.ThunderforestProvider;
	import maps.geo.LatLng;
	import maps.geo.LatLngBounds;
	import maps.utils.GooglePolylineDencoder;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.ResizeEvent;
	
	public class MainApp2 extends Sprite
	{
		
		private var map:YAMIMap;
		private var path:MapLiner;
		
		public function MainApp2()
		{
			addEventListener(Event.ADDED_TO_STAGE, run);
			TweenPlugin.activate([HexColorsPlugin]);
		}
		
		public function run():void
		{
			MyAssets.init(onLoadComplete, 2);
		}
		
		private function onLoadComplete():void
		{
			ThunderforestProvider.apiKey = "783cd5daacd340a58b25b70acbc08d95";
			HereWeGoProvider.appId = "DirxmMmNgxG0oygf0Tvt";
			HereWeGoProvider.appCode = "r2zkKYdLnAu6U7tAM40WPQ";
			MapBoxProvider.token = "pk.eyJ1Ijoicm9pcGVrZXIiLCJhIjoiY2pjdnptbjc2MTFyNjJxbzczZ296cTF3NiJ9.df-1MYIPrB9QB5tAg9-4UQ";
			OpenWeatherProvider.apiKey = "1c3e4ef8e25596946ee1f3846b53218a";
			//        testShape() ;
			testMap();
			//        testMapBoxAPI();
			//        testMapPolylines();
			//        testLatLng();
			//        testPolylineDecoder();
			//        testMesh();
		}
		
		private function testLatLng():void
		{
			var acropoli:LatLng = LatLng.toLatLng(37.971465, 23.725995);
			var home:LatLng = LatLng.toLatLng(38.019022, 23.733552);
			trace("distance:", acropoli.distanceTo(home));
		}
		
		private function testMapBoxAPI():void
		{
			var api:MapBoxAPI = MapBoxAPI.instance;
			api.geocoding(function (info:Object)
			{
				if (info.isComplete)
				{
					trace("RESPONSE:", info.data);
				}
			}, "Mercedes,Buenos Aires,Argentina", null, {language: 'es'});
		}
		
		private function testMapPolylines():void
		{
			map = new YAMIMap(stage.stageWidth - 40, stage.stageHeight - 40, this);
			map.x = map.y = 20;
			map.addLayerByProvider(new GoogleMapsProvider(GoogleMapsProvider.MAPTYPE_ROADMAP, 2));
			//        map.addLayerByProvider(new MapBoxProvider(MapBoxProvider.TYPE_DARK, 2));
			map.setZoom(8);
			//        map.setCenterLatLon(37.971465, 23.725995); // acropoli
			//        map.setCenter(new LatLng(37.971465, 23.725995)); // acropoli
			
			// parse path Home/Acropoli
			// https://maps.googleapis.com/maps/api/directions/json?origin="38.019071, 23.733592"&destination="37.971524, 23.725792"
			// from 38.019071, 23.733592 > to 37.971524, 23.725792 (acropoli)
			//        var directionsString:String = "er`gFsnzoCbABPkHB}@nA@rB?zA?RBd@FzA@bC@xAHX@`D?x@R|AEf@AlADrABvC@xGPnBFvBBrDGnD@|CA|C\\\\tEn@lEv@`FpAjCf@zJ`BL@JLh@JvB`@nBXnFx@xB^|Cb@zDl@tLnBdFv@pAVhC^dFr@bHfAvH~@tEx@pCZvGfAVDVJdAu@vD{Cr@i@rGgFvC}BbCkBvBiB^WbGsETG\\\\@`@ZK^WbCUzChAPxARpAVG|AKzBQjDy@zHc@hCg@jCd@Dj@F|A\\\\j@FEd@EtA@HFBZNWzA[lBPHBB?F?~CfAJBCNeCDm@J@JALC`@Fb@_CZHt@JT?P?^FCwAEUIc@@u@@Wj@iAJa@LFHFH\\\\If@Kn@AXDl@JXPfA?^";
			
			// https://maps.googleapis.com/maps/api/directions/json?origin="37.999394184691255,23.722929678191917"&destination="38.02361577171462,23.73597193375531"
			var directionsString:String = "cw|fFulxoCaDSWYEOAIM?}DOP}Cp@uJb@yF@K]I_AQqBa@mE{@kDq@cDy@_EcAgEkAqBc@i@IgACy@AuDN}DTSBOG}@PkARu@PWJ}AXiCz@QBsAW{E_@eDi@U?s@GkASwBc@y@]eAc@wAs@gDgBgEkBkAk@]Ys@g@s@[GCT_Bx@uGHq@BcA@{@O?BuC@aAHcE?K]CW?q@a@]SmAu@kCcCsAiAGQo@g@IKKFa@TKLs@^cAx@a@n@Wj@]fAQx@Ob@Cv@@`@Rp@"
			
			// parse the encoded google directions string.
			var directionsArr:Array = GooglePolylineDencoder.decode(directionsString);
			var arr:Array = MapUtils.makeLatLngFromList(directionsArr);
			
			var from:LatLng = arr[0];
			var toLatlng:LatLng = arr[arr.length - 1];
			
			map.addMarkerLatLng('start', from, new MyCoolPin(0xc12238));
			map.addMarkerLatLng('end', toLatlng, new MyCoolPin(0xc12238));
			
			var bounds:LatLngBounds = new LatLngBounds(from, toLatlng);
			map.setCenter(bounds.getCenter());
			
			// create the path (warning, it is slow on high zoom levels!).
			path = new MapLiner();
			path.setLatLngData(arr);
			//        path.lineStyle(0xff0000, 2, .5);
			path.lineStyleTexture(BasicShape.createRectDotTexture(4, 10, 4), 0x1b76bc, 4);
			//        map.addPath(path);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function testPolylineDecoder():void
		{
			//  Sample: https://maps.googleapis.com/maps/api/directions/json?origin=%22228%20Mott,%20New%20York,%20NY%22&destination=%22102%20St%20Marks%20Pl,%20New%20York,%20NY%22
			var overviewPolyline:String = "}qpwFvdsbMvC|@|@wC|@sCDWFYOEeGcBoA[eGeB[CkCq@gCo@KCFW`CqHfE_NaC{A_EkC{GqE_C{A~@sC";
			var geoPoints:Array = GooglePolylineDencoder.decode(overviewPolyline);
			trace("Decoded points:", geoPoints);
			trace("(Re)encoded points:", GooglePolylineDencoder.encode(geoPoints));
		}
		
		private function testMap():void
		{
			var scale:Number = 2;
			map = new YAMIMap(stage.stageWidth - 40, stage.stageHeight - 40, this);
			
			//        map.addLayerByProvider(new CartoDBProvider(CartoDBProvider.MAPTYPE_ANTIQUE, scale));
			//        map.addLayerByProvider(new MapBoxProvider(MapBoxProvider.SAMPLE_TRANSPORT_OSM, scale));
			
			//        map.addLayerByProvider(new YandexProvider( YandexProvider.MAPTYPE_SATELITE, 2 ));
			//        map.addLayerByProvider(new YandexProvider( YandexProvider.MAPTYPE_TRAFFIC, 2 ));
			//        map.addLayerByProvider(new YandexProvider( YandexProvider.MAPTYPE_ROADS, 2, 'es-ES' ));
			
			//        map.addLayerByProvider(new EsriProvider( EsriProvider.MAPTYPE_TERRAIN ));
			
			//        map.addLayerByProvider(new GoogleMapsProvider( GoogleMapsProvider.MAPTYPE_ROADMAP, 2 ));
			
			//        map.addLayerByProvider(new BingMapsProvider( BingMapsProvider.MAPTYPE_SATELITE ));
			//        map.addLayerByProvider(new BingMapsProvider( BingMapsProvider.MAPTYPE_MAP ));
			
			//        map.addLayerByProvider(new OpenWeatherProvider( OpenWeatherProvider.MAPTYPE_WIND ));
			//        map.addLayerByProvider(new iPhotoProvider());
			
			//        map.addLayerByProvider(new BbbikeProvider(BbbikeProvider.MAPTYPE_CYCLEWAY));
			//        map.addLayerByProvider(new CartoProvider(CartoProvider.MAPTYPE_LIGHT));
			
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_LIGHTS));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_HYDDA_FULL));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_HYDDA_BASE));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_ASTERH));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_HIKEBIKE));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_HYDDA_ROADSLABELS));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_MAPNIK_BW));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_OPEN_PUBLIC_TRANSPORT_L));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_OSM_ADMIN_BOUNDRIES));
			//        map.addLayerByProvider(new OSMProvidersCollection(OSMProvidersCollection.PROVIDER_OSMFR_HOT));
			
			//        map.addLayerByProvider(new StamenProvider(StamenProvider.MAPTYPE_TONER));
			map.addLayerByProvider(new ThunderforestProvider(ThunderforestProvider.MAPTYPE_OUTDOORS));
			//        map.addLayerByProvider(new WayMarkedTrailsProvider(WayMarkedTrailsProvider.MAPTYPE_MTB));
			//        map.addLayerByProvider(new YandexProvider(YandexProvider.MAPTYPE_MAP, 2));
			//        map.addLayerByProvider(new GoogleMapsProvider(GoogleMapsProvider.MAPTYPE_ROADMAP, 2));
			
			map.setZoom(8);
			
			//        map.setCenterLatLon(-34.649929, -59.426756); // mercedes
			//        map.setCenterLatLon(41.005377, 28.962163); // istanbul
			map.setCenterLatLon(37.971465, 23.725995); // acropoli
			
			//        map.mapBounds = new Rectangle( -59.465319, -34.630190, -59.374393, -34.675162);
			map.x = map.y = 20;
			//        var q:Quad = new Quad(10, 10, 0xff0000);
			//        map.addMarkerAtCoords('uno', -34.606815, -58.435610, q, {title: "pepe"});
			//        map.addMarkerAtCoords('dos', 41.005377, 28.962163, q, {title: "pepe"});
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			/*var flightPlanCoordinates = [
				{lat: 37.772, lng: -122.214},
				{lat: 21.291, lng: -157.821},
				{lat: -18.142, lng: 178.431},
				{lat: -27.467, lng: 153.027}
			];
			var flightPath = new google.maps.Polyline({
				path: flightPlanCoordinates,
				geodesic: true,
				strokeColor: '#FF0000',
				strokeOpacity: 1.0,
				strokeWeight: 2
			});
			*/
			
			/*var flightPlanCoordinates:Array = [
				{lat: 37.772, lng: -122.214},
				{lat: 21.291, lng: -157.821},
				{lat: -18.142, lng: 178.431},
				{lat: -27.467, lng: 153.027}
			];*/
			//        var list:Array = [25.767368,-80.18930,
			//        34.088808,-118.40612,
			//        40.727093,-73.97864];
			
			/*var arr:Array = MapUtils.makeLatLngArrayFromNumbers(
					37.968293, 23.718267,
					37.971807, 23.726460,
					37.977846, 23.713588,
					38.018997, 23.733596
			);*/
			
			// This polyline takes half the world, so when zooming much, the performance is terrible.
			// all the line is rendered, not only what you see on the screen...
			// i need a way to crop the line to the current map's viewport.
			var travelPoints:Array = [
				-34.648926, -59.387190, // mercedes
				-34.812188, -58.539337, // ezeiza
				-23.433937, -46.481527, // sao pablo airport
				40.983681, 28.810406, // ataturk
				37.938725, 23.941998, // athens airport.
				37.977846, 23.713588 // acropoli
			];
			
			var arr:Array = MapUtils.makeLatLngFromNumbersPairs(travelPoints);
			for (var i:int = 0; i < arr.length; i++)
			{
				map.addMarkerLatLng('marker' + i, arr[i], new MyCoolPin(0xc12238));
			}
			
			map.addEventListener("markerTriggered", function (e:Event)
			{
				//            var marker:MyCoolPin = e.target as MyCoolPin;
				var marker:MyCoolPin = e.data as MyCoolPin;
				
				// direct center.
				//            map.setCenter( marker.latlng );
				
				// tween center.
				TweenMax.to(map.toucher, .6, {
					pivotX: marker.x,
					pivotY: marker.y,
					x: map.w >> 1,
					y: map.h >> 1,
					ease: Expo.easeOut
				});
			});
			
			// TODO: create a polygon.
			
			// create a polyline.
			path = new MapLiner();
			path.setLatLngData(arr);
			//        path.lineStyle(0x1b76bc, 2, 1);
			path.lineStyleTexture(BasicShape.createRectDotTexture(4, 10, 4), 0x1b76bc, 4);
			//        map.addPath(path);
			//        map.addMarkerAtCoords('i1', 37.971465, 23.725995, new Quad(10, 10, 0xff0000));
			//        map.addMarkerAtCoords('i2', 38.019174, 23.733530, new Quad(10, 10, 0xff0000));
			//        map.addMarkerAtCoords('i3', 38.239428, 21.742698, new Quad(10, 10, 0x00ff00));
			MapTileLoader.cleanupUnusedCacheInterval = 20;
			stage.addEventListener(ResizeEvent.RESIZE, onStageResize);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.A)
			{
				map.zoomCenter(1);
			} else if (event.keyCode == Keyboard.S)
			{
				map.zoomCenter(-1);
			} else if (event.keyCode == Keyboard.NUMBER_3)
			{
				path.lineStyle(0xe76e35, 4, 1);
			} else if (event.keyCode == Keyboard.NUMBER_4)
			{
				path.lineStyle(0x0, 1, 1);
			} else if (event.keyCode == Keyboard.NUMBER_5)
			{
				path.lineStyle(0x2374b3, 8, .5);
			} else if (event.keyCode == Keyboard.NUMBER_6)
			{
				path.lineStyle(0x1b76bc, 2, .9);
			}
		}
		
		private function onStageResize(event:Event):void
		{
			var sw:int = stage.stageWidth;
			var sh:int = stage.stageHeight;
			map.setSize(sw - 100, sh - 100);
		}
	}
}
