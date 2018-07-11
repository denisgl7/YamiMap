// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package core {
import flash.geom.Rectangle;
import flash.ui.Keyboard;

import maps.GeoUtils;
import maps.MapTileLoader;
import maps.YAMIMap;
import maps.config.MapBoxProvider;
import maps.config.osm.ThunderforestProvider;

import roipeker.helpers.AppHelper;

import starling.display.Canvas;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.events.ResizeEvent;
import starling.utils.AssetManager;

public class MainApp extends Sprite {
    public function MainApp() {
        // nothing.
        addEventListener(Event.ADDED_TO_STAGE, run);
    }

    var assets:AssetManager = new AssetManager(1, false);

    public function run():void {
        trace('run');
        assets.enqueue(AppHelper.appDir.resolvePath('assets'));
        assets.loadQueue(onLoadProgress);
    }

    private function onLoadProgress(p:Number):void {
        if (p == 1) {
            init();
        }
    }

    private function init():void {
        ThunderforestProvider.apiKey = "783cd5daacd340a58b25b70acbc08d95";
        test2();
    }

    var map:YAMIMap;

    private function test2():void {

        map = new YAMIMap(stage.stageWidth - 40, stage.stageHeight - 40, this);
        var scale:Number = 2;

        // setup provider gmaps!
        /*
        var gmaps:GoogleMapsProvider = new GoogleMapsProvider();
        gmaps.textureScale = scale;
        gmaps.mapType = GoogleMapsProvider.MAPTYPE_SATELLITE_ONLY ;
        map.addLayerByProvider( gmaps );

        gmaps = new GoogleMapsProvider();
        gmaps.textureScale = 2;
        gmaps.mapType = GoogleMapsProvider.MAPTYPE_ROAD_ONLY;
        map.addLayerByProvider( gmaps );
        */

        // setup provider OSM
//        var osmProv1:OSMProvider=new OSMProvider();
//        map.addLayerByProvider(osmProv1);

        /*var cartoProvider:CartoDBProvider=new CartoDBProvider();
        cartoProvider.mapType = CartoDBProvider.MAPTYPE_MIDNIGHT;
        cartoProvider.textureScale = 2;
        map.addLayerByProvider(cartoProvider);*/

//        var provider:OSMProvider=new OSMProvider();
//        provider.mapType = CartoDBProvider.MAPTYPE_MIDNIGHT;
//        provider.textureScale = 2;
//        map.addLayerByProvider(provider);

//        map.addLayerByProvider(new StamenProvider(StamenProvider.MAPTYPE_TERRAIN,2));

//        map.addLayerByProvider(new WayMarkedTrailsProvider(WayMarkedTrailsProvider.MAPTYPE_HILLSHADING));
//        map.addLayerByProvider(new OpenCycleProvider(1));
//        map.addLayerByProvider(new ThunderforestProvider(ThunderforestProvider.MAPTYPE_OUTDOORS,2));
//        map.addLayerByProvider(new ThunderforestProvider(ThunderforestProvider.MAPTYPE_MOBILEATLAS,2)).blendMode = BlendMode.MULTIPLY;
//        map.addLayerByProvider(new ThunderforestProvider(ThunderforestProvider.MAPTYPE_TRANSPORTDARK,2));

        /*map.addLayerByProvider(new CartoProvider(CartoProvider.MAPTYPE_DARK,2));
        map.addLayerByProvider(new WayMarkedTrailsProvider(WayMarkedTrailsProvider.MAPTYPE_CYCLING));

//        map.addLayerByProvider(new CartoDBProvider(CartoDBProvider.MAPTYPE_ANTIQUE,2));
        map.addLayerByProvider(new StamenProvider(StamenProvider.MAPTYPE_WATERCOLOR,2));

        var p:GoogleMapsProvider = new GoogleMapsProvider(GoogleMapsProvider.MAPTYPE_ROAD_ONLY,2);
        p.textureFormat = Context3DTextureFormat.BGRA;
        map.addLayerByProvider(p );*/

//        MapBoxProvider.token = "xxxxx";
//        var mapbox:MapBoxProvider = new MapBoxProvider("mapbox.mapbox-terrain-v2,mapbox.mapbox-streets-v7", 2, MapBoxProvider.FORMAT_PNG32 ) ;
//        map.addLayerByProvider(mapbox);

//        map.addLayerByProvider(new CartoDBProvider(CartoDBProvider.MAPTYPE_MIDNIGHT,1));
//        map.addLayerByProvider(new GoogleMapsProvider(GoogleMapsProvider.MAPTYPE_ROADMAP,2));
//        map.addLayerByProvider(new CartoProvider(CartoProvider.MAPTYPE_DARK, 2));
//        map.addLayerByProvider(new WayMarkedTrailsProvider(WayMarkedTrailsProvider.MAPTYPE_CYCLING));

//        map.addLayerByProvider(new BbbikeProvider(BbbikeProvider.MAPTYPE_HANDICAP));
//        map.addLayerByProvider(new OSMFRProvider(OSMFRProvider.MAPTYPE_HOT));


//        map.addLayerByProvider(new OSMProvider(OSMProvider.MAPTYPE_OSM));
//        map.addLayerByProvider(new OSMProvider(OSMProvider.MAPTYPE_GPS));
//        map.addLayerByProvider( new OSMProvidersCollection( OSMProvidersCollection.PROVIDER_OPEN_TOPO));
//        map.addLayerByProvider( new OSMProvidersCollection( OSMProvidersCollection.PROVIDER_LIGHTS));
//        "7a239db582c6ba4d5d4d79b3fd61ed14"
//        map.addLayerByProvider( new CustomProvider("http://tile.openweathermap.org/map/temp_new/${z}/${x}/${y}.png?APPID=1c3e4ef8e25596946ee1f3846b53218a"));

//        map.addLayerByProvider( new iPhotoProvider());
//        map.addLayerByProvider( new OpenWeatherProvider(OpenWeatherProvider.MAPTYPE_CLOUDS));
//        map.addLayerByProvider( new BingMapsProvider(BingMapsProvider.MAPTYPE_HYBRID));

//        map.addLayerByProvider(new BingMapsProvider(BingMapsProvider.MAPTYPE_HYBRID));
//        map.addLayerByProvider(new EsriProvider(EsriProvider.MAPTYPE_TRANSPORTATION));
//        map.addLayerByProvider(new MapBoxProvider("mapbox.mapbox-terrain-v2,mapbox.mapbox-streets-v7", 2));
//        map.addLayerByProvider(new MapBoxProvider("mapbox.mapbox-terrain-v2,mapbox.mapbox-streets-v7,jonahadkins.3oshvpyy", 2));
//        return ;
//        map._textureScale = Starling.contentScaleFactor;
//        trace('content factor issss', Starling.contentScaleFactor);
        map.setZoom(13);
        map.setCenterLatLon(-34.649929, -59.426756);
//        map.mapBounds = new Rectangle( -59.465319, -34.630190, -59.374393, -34.675162);
        map.x = map.y = 20;

//        var q:Quad = new Quad(50, 50, 0xff0000);
//        map.addMarkerAtCoords('uno', -34.606815, -58.435610, q, {title: "pepe"});

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        MapTileLoader.cleanupUnusedCacheInterval = 30;
        stage.addEventListener(ResizeEvent.RESIZE, onStageResize);
    }

    private function onKeyDown(event:KeyboardEvent):void {
//        if (event.altKey) {
        if (event.keyCode == Keyboard.A) {
            map.zoomCenter(1);
        } else if (event.keyCode == Keyboard.S) {
            map.zoomCenter(-1);
        }
//        }
    }

    private function onStageResize(event:Event):void {
        trace("stage size:", stage.stageWidth);
        var sw:int = stage.stageWidth;
        var sh:int = stage.stageHeight;
        map.setSize(sw - 100, sh - 100);
    }

    private function trash():void {


        /*
                // update max zoom!
        //        GeoUtils.setMaxZoom( 19 );

                var point:Point = new Point(-87.715813,41.837223);

        //        var worldCoords:Point = GeoUtils.project(point);
        //        var worldCoords2:Point = GeoUtils.project2( point, false );
        //        var worldCoords3:Point = GeoUtils.project2( point, true );
        //        var worldCoords4:Point = GeoUtils.getPixelCoords( point, 18 );
                var worldCoords5:Point = GeoUtils.getPixelCoords( new Point(180, 90), 18 );
                trace(worldCoords5);



        //        trace(worldCoords); //(x=65.62431075555556, y=95.18712285783812)
        //        trace(worldCoords2); //
        //        trace(worldCoords3); //
        //        trace(worldCoords4); //

                trace('//////');
        //        trace( 134217728 ) ;
        //        trace( (19*67108864)/18)

        //        return ;*/

        var map:YAMIMap = new YAMIMap(stage.stageWidth - 100, stage.stageHeight - 100, this);
//        map.setCenterLatLonPoint(new Point(-87.650, 41.850));
//        map.maxZoomLevel = 19;
//        map._textureScale = Starling.contentScaleFactor + 1;
//        map.setZoomBounds(-1, 19);
        map.setZoom(17);
//        map.setCenterLatLon(-34.649929, -59.426756);
//        map.setCenterLatLon(-34.6562761,-59.4302552);
//        map.setCenterLatLon(41.837223, -87.715813);
//        map.setCenterLatLon(-34.606815, -58.435610);
//        map.mapBounds = new Rectangle(
//                -58.436,-34.61,
//                -58.434,-34.62
//        );

        var q:Quad = new Quad(50, 50, 0xff0000);
        map.addMarkerAtCoords('uno', -34.606815, -58.435610, q, {title: "pepe"});

//        var r:Quad = new Quad(50,50,0x0000ff);
//        r.alpha = .5  ;
//        r.alignPivot();

        var valor:Number = GeoUtils.pixelsPerMeter(-34.606815);
        // craete circle.
        var circ:Canvas = new Canvas();
        var sizeInMeters:Number = 90;
        circ.beginFill(0x00ff00, .4);
        circ.drawCircle(0, 0, valor * sizeInMeters);
        map.addCircCoords('ocho', -34.606, -58.435610, circ.width, circ, {title: "pepe"});

        /*TweenLite.delayedCall(1, function(){
//            var p:Point = new Point(GeoUtils.x2lon(map.viewport.left), GeoUtils.y2lat(map.viewport.top));
//            trace(p, map.viewport.left, map.viewport.right);
//            map.addMarkerAtCoords( 'dos',p.y, p.x, q,{title:"pepe"});
            map.addMarkerXY( 'dos',map.viewport.x, map.viewport.y, q,{title:"pepe"});
        });*/


        // mercedes bounds.
        map.setCenterLatLon(-34.649929, -59.426756);
        map.mapBounds = new Rectangle(
                -59.465319, -34.630190
                - 59.374393, -34.675162
        );
        map.x = map.y = 50;

        MapTileLoader.cleanupUnusedCacheInterval = 10;

        /*var url:String = "http://mt1.google.com/vt/lyrs=r&hl=en&x=2744&y=4937&z=13&scale=4";
        MapTileLoader.requestTile( url, function(e:Event){
            var loader:MapTileLoader = e.target as MapTileLoader ;
            trace( "data:", loader.texture, loader.usingMemCache );
        });
        MapTileLoader.addPendingDisposal(url);*/


//        map.zoom = 3;
//        map.centerLatLong(chicago);
//        LatLng: (41.85, -87.64999999999998)
    }
}
}
