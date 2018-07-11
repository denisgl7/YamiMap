package maps {
import flash.geom.Point;

/**
 * Geographical utils using mercator projection algorithms.
 */
public class GeoUtils {
    public static const DEG_RAD:Number = PI / 180;
    public static const RAD_DEG:Number = 180 / PI;

    public static var MAX_LATITUDE:uint = 67108864;
    public static var MAX_LONGITUDE:uint = 67108864; // should be 86442291 || -19333427
    public static var EARTH_RADIUS:uint = 6371000; // in meters

    private static const PI:Number = Math.PI;
    private static var C_LONGITUDE:Number = 360 / MAX_LONGITUDE;
    private static var C_LATITUDE:Number = 2 * PI / MAX_LATITUDE;
    private static var C_LATITUDE2:Number = MAX_LATITUDE / 2;

    private static var COS_1_EARTH_RADIUS:Number = Math.cos(1 / EARTH_RADIUS);
    private static var SIN_1_EARTH_RADIUS:Number = Math.sin(1 / EARTH_RADIUS);

    public static function project(lngLat:Point, tileSize:int = 256):Point {
        var siny:Number = Math.sin(lngLat.y * Math.PI / 180);
        // Truncating to 0.9999 effectively limits latitude to 89.189. This is
        // about a third of a tile past the edge of the world tile.
        siny = Math.min(Math.max(siny, -0.9999), 0.9999);
        return new Point(
                tileSize * (0.5 + lngLat.x / 360),
                tileSize * (0.5 - Math.log((1 + siny) / (1 - siny)) / (4 * Math.PI)));
    }

    public static function getPixelCoords(point:Point, zoom:int):Point {
        var scale:int = Math.pow(2, zoom);
        var worldCord:Point = project(point);
        worldCord.x = worldCord.x * scale;
        worldCord.y = worldCord.y * scale;
        return worldCord;
    }

    public static function project2(lngLat:Point, passby:Boolean = false):Point {
        var ratio:Number = passby ? Math.pow(2, 18) : 1;
        var p:Point = new Point();
        p.x = lon2x(lngLat.x) / ratio;
        p.y = lat2y(lngLat.y) / ratio;
        return p;
    }

    /**
     * Converts x coordinate to lon.
     */
    public static function x2lon(x:Number):Number {
        return x * C_LONGITUDE - 180;
    }

    /**
     * Converts lon to x coordinate.
     */
    public static function lon2x(lon:Number):Number {
        return (lon + 180) / C_LONGITUDE
    }

    public static function setMaxZoom(num:Number):void {
        var res:int = GeoUtils.getPixelCoords(new Point(180, 90), num).x;
        trace("result:", res);
        MAX_LONGITUDE = MAX_LATITUDE = res;
//        MAX_LONGITUDE = (num * 67108864) / 18;
//        MAX_LATITUDE = (num * 67108864) / 18;
        C_LONGITUDE = 360 / MAX_LONGITUDE;
        C_LATITUDE = 2 * PI / MAX_LATITUDE;
        C_LATITUDE2 = MAX_LATITUDE / 2;
        /*EARTH_RADIUS = (num * 6371000) / 18;
        COS_1_EARTH_RADIUS = Math.cos(1 / EARTH_RADIUS);
        SIN_1_EARTH_RADIUS = Math.sin(1 / EARTH_RADIUS);*/
//        trace(MAX_LONGITUDE);
    }

    /**
     * Converts y coordinate to lat.
     */
    public static function y2lat(y:Number):Number {
        return Math.atan(sinh(PI - (C_LATITUDE * y))) * RAD_DEG;
    }

    /**
     * Converts lat to y coordinate.
     */
    public static function lat2y(lat:Number):Number {
        var latRad:Number = lat * DEG_RAD;
        return (1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / PI) * C_LATITUDE2;
    }

    /**
     * Returns the hyperbolic sine of value.
     */
    public static function sinh(value:Number):Number {
        return (Math.exp(value) - Math.exp(-value)) / 2;
    }

    /**
     * Returns distance in meters.
     */
    public static function distance(lon1:Number, lat1:Number,
                                    lon2:Number, lat2:Number):Number {
        var v:Number = Math.cos(lat1)
                * Math.cos(lat2)
                * Math.cos(lon2 - lon1)
                + Math.sin(lat1)
                * Math.sin(lat2);
        return v > 1 ? 0 : EARTH_RADIUS * Math.acos(v);
    }

    /**
     * Returns distance using deg parameters.
     */
    public static function distanceDeg(lon1:Number, lat1:Number,
                                       lon2:Number, lat2:Number):Number {
        return distance(lon1 * DEG_RAD, lat1 * DEG_RAD,
                lon2 * DEG_RAD, lat2 * DEG_RAD);
    }

    /**
     * Given a start point, initial bearing, and distance, this will
     * calculate the destination point and final bearing travelling along
     * a (shortest distance) great circle arc.
     * http://www.movable-type.co.uk/scripts/latlong.html
     *
     * @distance in meters
     */

    public static function destination(lon:Number, lat:Number, bearing:Number, distance:Number):Point {
        var a:Number = distance / EARTH_RADIUS;
        var lat2:Number = Math.asin(Math.sin(lat) * Math.cos(a) +
                Math.cos(lat) * Math.sin(a) * Math.cos(bearing));
        var lon2:Number = lon + Math.atan2(Math.sin(bearing) * Math.sin(a) * Math.cos(lat),
                Math.cos(a) - Math.sin(lat) * Math.sin(lat2));
        return new Point(lon2, lat2);
    }

    /**
     * Returns destination point using deg parameters.
     */
    public static function destionationDeg(lon:Number, lat:Number, bearing:Number, distance:Number):Point {
        var result:Point = destination(lon * DEG_RAD, lat * DEG_RAD, bearing * DEG_RAD, distance);
        result.x *= RAD_DEG;
        result.y *= RAD_DEG;
        return result;
    }

    /**
     * Returns lat coordinate at specific distance and 90 degree angle.
     */
    public static function lonAtDistanceDeg(lon:Number, lat:Number, distance:Number):Number {
        return destionationDeg(lon, lat, 90, distance).x;
    }

    /**
     * Returns latitude at distance from original point.
     */
    public static function latAtDistanceDeg(lat:Number, distance:Number):Number {
        lat *= DEG_RAD;
        var a:Number = distance / EARTH_RADIUS;
        return Math.asin(Math.sin(lat) * Math.cos(a) + Math.cos(lat) * Math.sin(a)) * RAD_DEG;
    }

    /**
     * Returns pixels per meter in specific geo location.
     */
    public static function pixelsPerMeter(lat:Number):Number {
        var result:Number = lat2y(lat) - lat2y(
                Math.asin(
                        Math.sin(lat * DEG_RAD) * COS_1_EARTH_RADIUS +
                        Math.cos(lat * DEG_RAD) * SIN_1_EARTH_RADIUS
                ) * RAD_DEG);
        return result < 0 ? -result : result;
    }

    /**
     * Returns pixels per meter in specific coordinates.
     */
    public static function pixelPerMeterByCenter(center:Point):Number {
        return pixelsPerMeter(y2lat(center.y));
    }

    /**
     * Returns pixels per meter using destination algorithm.
     */
    public static function pixelsPerMeterPrecise(lon:Number, lat:Number):Number {
        var destination:Point = destionationDeg(lon, lat, 45, 1);
        var x:Number = lon2x(lon) - lon2x(destination.x);
        var y:Number = lat2y(lat) - lat2y(destination.y);
        return Math.sqrt(x * x + y * y);
    }

}
}