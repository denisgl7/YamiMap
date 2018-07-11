// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config {
import roipeker.utils.StringUtils;

import starling.utils.MathUtil;

/**
 * Based on
 * https://carto.com/location-data-services/basemaps/
 *
 */
public class MapBoxProvider extends AbsLayerProvider {

    public static var token:String;

    private static const TEMPLATE_URL:String = "https://api.mapbox.com/v4/${type}/${z}/${x}/${y}${scale}.${format}?access_token=${token}";

    // used as maptypes.
    public static const SAMPLE_HYBRID:String = "tmcw.map-j5fsp01s";
    public static const SAMPLE_RUNKEEPERS:String = "heyitsgarrett.kf2a2nb1";
    public static const SAMPLE_TERRAIN:String = "matt.72ef5189";
    public static const SAMPLE_TRANSPORT_OSM:String = "peterqliu.9d05be4d";

    // as defined by https://www.mapbox.com/api-documentation/#maps
    public static const TYPE_STREETS:String = "mapbox.streets";
    public static const TYPE_LIGHT:String = "mapbox.light";
    public static const TYPE_DARK:String = "mapbox.dark";
    public static const TYPE_SATELLITE:String = "mapbox.satellite";
    public static const TYPE_STREETS_SATELLITE:String = "mapbox.streets-satellite";
    public static const TYPE_WHEATPASTE:String = "mapbox.wheatpaste";
    public static const TYPE_STREETS_BASIC:String = "mapbox.streets-basic";
    public static const TYPE_COMIC:String = "mapbox.comic";
    public static const TYPE_OUTDOORS:String = "mapbox.outdoors";
    public static const TYPE_RUN_BIKE_HIKE:String = "mapbox.run-bike-hike";
    public static const TYPE_PENCIL:String = "mapbox.pencil";
    public static const TYPE_PIRATES:String = "mapbox.pirates";
    public static const TYPE_EMERALD:String = "mapbox.emerald";
    public static const TYPE_HIGH_CONTRAST:String = "mapbox.high-contrast";

    public static const FORMAT_PNG256:String = "png256";
    public static const FORMAT_PNG128:String = "png128";
    public static const FORMAT_PNG64:String = "png64";
    public static const FORMAT_PNG32:String = "png32";
    public static const FORMAT_JPG70:String = "jpg70";
    public static const FORMAT_JPG80:String = "jpg80";
    public static const FORMAT_JPG90:String = "jpg90";
    public static const FORMAT_JPG:String = "jpg"; // = png256
    public static const FORMAT_PNG:String = "png"; // = jpg80

    public function MapBoxProvider(mapType:String = "mapbox.streets", textureScale:Number = 1, imageFormat:String = FORMAT_PNG) {
        super();
        maxZoomLevel = 22;
        this.mapType = mapType;
        this.textureScale = textureScale;
        this.imageFormat = imageFormat;
    }

    override public function resolveUrl(x:uint, y:uint, zoom:Number):String {
        var scale:String = _textureScale > 1 ? "@" + _textureScale + "x" : "";
        return StringUtils.formatKeys(TEMPLATE_URL, {
            type: _mapType,
            token: MapBoxProvider.token,
            format: _imageFormat,
            scale: scale,
            x: x,
            y: y,
            z: zoom
        });
    }

    public function set textureScale(value:Number):void {
        if (!value) value = 1;
        value = MathUtil.clamp(Math.round(value), 1, 2);
        _textureScale = value;
    }

    override public function resolveFilepath(url:String):String {
        // remove token.
        return super.resolveFilepath(trimEnd(url,"?"));
    }
}
}
