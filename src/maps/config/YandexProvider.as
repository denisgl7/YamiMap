// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config {
import flash.display3D.Context3DTextureFormat;
import flash.net.URLVariables;

import roipeker.utils.StringUtils;

import starling.utils.MathUtil;

/**
 * API docs
 * https://tech.yandex.com/maps/doc/staticapi/1.x/dg/concepts/input_params-docpage/
 *
 * https://tech.yandex.com/maps/doc/staticapi/1.x/dg/concepts/map_type-docpage/
 */

public class YandexProvider extends AbsLayerProvider {

    public static const MAPTYPE_SATELITE:String = "sat";
    public static const MAPTYPE_ROADS:String = "skl";
    public static const MAPTYPE_MAP:String = "map";
    public static const MAPTYPE_TRAFFIC:String = "trf";

    // traffic should not be stored.
    private static const TEMPLATE_TRAFFIC_URL:String =
            "https://jgo.maps.yandex.net/1.1/tiles?l=trf,trfe&lang=${lang}&x=${x}&y=${y}&z=${z}&scale=${scale}&tm=${tm}";

    private static const TEMPLATE_URL:String =
            "https://${s}.maps.yandex.net/tiles?l=${type}&x=${x}&y=${y}&z=${z}&scale=${scale}&lang=${lang}";

    public var language:String;

    public function YandexProvider(mapType:String = MAPTYPE_SATELITE, textureScale:Number = 1, language:String = "es-ES") {
        super();
        minZoomLevel = 0;
        maxZoomLevel = 23;
        _subdomains = ["01", "02", "03", "04"];
        _urlParamsToFolderSort = ['lang', 'scale', 'l', 'z', 'x', 'y'];

        this.language = language;
        this.mapType = mapType;
        this.textureScale = textureScale;

        if (_mapType == MAPTYPE_TRAFFIC) {
            useFileCache = false;
        }
    }

    override public function resolveUrl(x:uint, y:uint, zoom:Number):String {
        var isTraffic:Boolean = _mapType == MAPTYPE_TRAFFIC;
        if (isTraffic) {
            return StringUtils.formatKeys(TEMPLATE_TRAFFIC_URL, {
                scale: _textureScale,
                lang: language,
                x: x,
                y: y,
                z: zoom,
                tm: (new Date().getTime() / 1000 | 0)
            });
        } else {
            return StringUtils.formatKeys(TEMPLATE_URL, {
                s: (_mapType == MAPTYPE_SATELITE ? "sat" : "vec") + nextSubdomain,
                type: _mapType,
                scale: _textureScale,
                lang: language,
                x: x,
                y: y,
                z: zoom
            });
        }
    }

    override protected function adjustTextureFormat():void {
        if (_mapType == MAPTYPE_SATELITE) {
            textureFormat = Context3DTextureFormat.BGRA;
        } else {
            textureFormat = Context3DTextureFormat.BGRA_PACKED;
        }
    }

    public function set textureScale(value:Number):void {
        if (!value) value = 0;
        _textureScale = MathUtil.clamp(value, 1, 4);
    }

    override public function resolveFilepath(url:String):String {
        // op1 - automatically resolve url path with parameters (will start with yandex/tiles/) though.
//        return super.resolveFilepath(url);
        // op2 - use only the url parameters for the file path.
        return resolveFilepathFromParamsOnly( url, "tiles?" );
    }

}
}
