// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package maps {
import flash.net.URLVariables;

import maps.geo.LatLng;

import roipeker.utils.StringUtils;

public class MapUtils {
    public function MapUtils() {
    }

    public static function formatNum(num:Number, digits:uint = 6):Number {
        var pow:uint = Math.pow(10, (digits));
        return Math.round(num * pow) / pow;
    }


    /**
     * Returns the number `num` module `range` in such a way so it lies within
     * `min` and `max`. The returned value will be always smaller than `max` unless
     * `includeMax`=true.
     *
     * @param num
     * @param min
     * @param max
     * @param includeMax
     * @return
     */
    public static function wrapNum(num:Number, min:Number, max:Number, includeMax:Boolean = false):Number {
        var d:Number = max - min;
        return num == max && includeMax ? num : ((num - min) % d + d) % d + min;
    }

    public static function getFilepathFromUrlParams(url:String, sortFields:Array = null):String {
        var params:URLVariables = getVariablesFromUrl(url);
        var key:String;
        var keys:Array = [];
        if (sortFields) {
            keys = sortFields;
        } else {
            for (key in params) {
                keys.push(key);
            }
            keys.sort();
        }
        url = "";
        for (var i:int = 0; i < keys.length; i++) {
            key = keys[i];
            url += params[key];
            if (i < keys.length - 1) {
                url += "/";
            }
        }
        return url;
    }

    public static function getVariablesFromUrl(url:String):URLVariables {
        var cleanUrl:String = stripParametersFromUrl(url);
        var urlVars:URLVariables = new URLVariables();
        if (url == cleanUrl)
            return urlVars;

        var urlParameters:String = url.substr(cleanUrl.length + 1); // +1 to exclude ? or # ;
        if (urlParameters == "")
            return urlVars;
        urlParameters = StringUtils.replace(urlParameters, "?", "&");
        urlParameters = StringUtils.replace(urlParameters, "#", "&");
        urlVars.decode(urlParameters);
        return urlVars;
    }

    public static function stripParametersFromUrl(url:String):String {
        var i:int;
        const SEARCH:Array = ["?", "#", "&"];
        for each(var key:String in SEARCH) {
            i = url.indexOf(key);
            if (i > -1) {
                url = url.substr(0, i);
            }
        }
        return url;
    }

    public static function convertNumbers2LatLngArray(list:Array):Array {
        var out:Array = [];
        for (var i:int = 0, len:int = list.length; i < len; i += 2) {
            out[out.length] = {lat: list[i], lng: list[i + i]};
        }
        return out;
    }

    public static function makeLatLngFromList(list:Array, coordsInverted:Boolean = false):Array {
        if (list[0] is Array) {
            return makeLatLngFromArrayPairs(list, coordsInverted);
        } else if (list[0] is Number) {
            return makeLatLngFromNumbersPairs(list, coordsInverted);
        } else if (Object(list[0]).hasOwnProperty('lat')) {
            return makeLatLngFromObject(list);
        }
        return null;
    }

    // This format [{lat:0,lng:0}, {lat:0,lng:0} .. ]
    public static function makeLatLngFromObject(list:Array):Array {
        // number list
        var len:int = list.length;
        var out:Array = [];
        for (var i:int = 0; i < len; i++) {
            out[i] = new LatLng(list[i].lat, list[i].lng);
        }
        return out;
    }

    // This format [0,0, 0,0, 0,0]
    public static function makeLatLngFromNumbersPairs(list:Array, coordsInverted:Boolean = false):Array {
        // number list
        var len:int = list.length;
        var out:Array = [];
        var off1:int = coordsInverted ? 1 : 0;
        var off2:int = coordsInverted ? 0 : 1;
        for (var i:int = 0; i < len; i += 2) {
            out[out.length] = new LatLng(list[int(i + off1)], list[int(i + off2)]);
        }
        return out;
    }

    // This format [[0,0],[0,0],[0,0]]
    public static function makeLatLngFromArrayPairs(list:Array, coordsInverted:Boolean = false):Array {
        // array list
        var len:int = list.length;
        var out:Array = [];
        var i1:int = coordsInverted ? 1 : 0;
        var i2:int = coordsInverted ? 0 : 1;
        for (var i:int = 0; i < len; i++) {
            out[i] = new LatLng(list[i][i1], list[i][i2]);
        }
        return out;
    }
}
}
