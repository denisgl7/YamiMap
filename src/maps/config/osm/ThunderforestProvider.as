// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config.osm {
import maps.config.*;

import flash.display3D.Context3DTextureFormat;

import roipeker.utils.StringUtils;

import starling.utils.MathUtil;

/**
 * Based on
 * http://www.thunderforest.com/docs/map-tiles-api/
 *
 * Get api key in http://www.thunderforest.com/
 *
 * for image formats: http://www.thunderforest.com/docs/image-formats/
 *
 * tile is 256x256 only PNG.
 */

public class ThunderforestProvider extends AbsLayerProvider {

    // remove l8r!
    public static var apiKey:String;

    private static const TEMPLATE_URL:String = "https://${s}.tile.thunderforest.com/${type}/${z}/${x}/${y}${scale}.${format}${apikey}";

    public static const MAPTYPE_CYCLE:String = "cycle";
    public static const MAPTYPE_TRANSPORT:String = "transport";
    public static const MAPTYPE_LANDSCAPE:String = "landscape";
    public static const MAPTYPE_OUTDOORS:String = "outdoors";
    public static const MAPTYPE_TRANSPORTDARK:String = "transport-dark";
    public static const MAPTYPE_SPINALMAP:String = "spinal-map";
    public static const MAPTYPE_PIONEER:String = "pioneer";
    public static const MAPTYPE_MOBILEATLAS:String = "mobile-atlas";
    public static const MAPTYPE_NEIGHBOURHOOD:String = "neighbourhood";

    public static const FORMAT_PNG256:String = "png256";
    public static const FORMAT_PNG128:String = "png128";
    public static const FORMAT_PNG64:String = "png64";
    public static const FORMAT_PNG32:String = "png32";
    public static const FORMAT_JPG70:String = "jpg70";
    public static const FORMAT_JPG80:String = "jpg80";
    public static const FORMAT_JPG90:String = "jpg90";
    public static const FORMAT_JPG:String = "jpg"; // = png256
    public static const FORMAT_PNG:String = "png"; // = jpg80

    public function ThunderforestProvider(mapType:String = MAPTYPE_TRANSPORT, textureScale:Number = 1) {
        super() ;
        maxZoomLevel = 22;
        _subdomains = ["a", "b", "c"];
        this.mapType = mapType;
        this.textureScale = textureScale;
        this.imageFormat = FORMAT_PNG;
    }

    override public function resolveUrl(x:uint, y:uint, zoom:Number):String {
        var scale:String = _textureScale > 1 ? "@" + _textureScale + "x" : "";
        // if apikey is provided, append.
        var apikey:String = ThunderforestProvider.apiKey ? ("?apikey=" + ThunderforestProvider.apiKey) : "";
        return StringUtils.formatKeys(TEMPLATE_URL, {
            s: nextSubdomain,
            format: _imageFormat,
            type: _mapType,
            x: x,
            scale: scale,
            y: y,
            z: zoom,
            apikey: apikey
        });
    }

    override public function resolveFilepath(url:String):String {
        return super.resolveFilepath(trimEnd(url,"?"));
    }

    override protected function adjustTextureFormat():void {
        textureFormat = Context3DTextureFormat.BGRA_PACKED;
    }

    public function set textureScale(value:Number):void {
        if (!value) value = 0;
        _textureScale = MathUtil.clamp(Math.ceil(value), 1, 2);
    }
}
}
