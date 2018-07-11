// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 06/02/2018.
//
// =================================================================================================

package maps.geo {
import maps.*;

import flash.geom.Point;

import maps.geo.Earth;
import maps.geo.LatLngBounds;

public class LatLng {

    // latitude in degrees
    private var _lat:Number;

    // longitud in degrees
    private var _lng:Number;

    // altitud in meters
    public var alt:Number;

    public function LatLng(lat:Number, lng:Number, altitud:Number = 0) {
        if (isNaN(lat) || isNaN(lng)) {
            throw new Error('Invalid LatLng object: (' + lat + ', ' + lng + ')');
        }
        this.lat = lat;
        this.lng = lng;
        this.alt = alt;
    }

    /**
     * Returns a string representation of the point.
     * @param precision
     * @return
     */
    public function toString(precision:Number = 0):String {
        return "LatLng(lat=" + MapUtils.formatNum(_lat, precision) + ", lng=" + MapUtils.formatNum(_lng, precision) + ")";
    }

    /**
     * Get distance (in meters) from another LatLng
     * @param other
     * @return  Number, distance (in meters) to `other` LatLng calculated using the Spherical Law of Cosines.
     */
    public function distanceTo(other:Object):Number {
        return Earth.distance(this, toLatLng(other));
    }

    /**
     * Returns a new `LatLng` object with longitude wrapped so it's always between -180 and +180 degrees.
     * @return
     */
    public function wrap():LatLng {
        return Earth.wrapLatLng(this);
    }

    /**
     * Returns a new `LatLngBounds` object in which each boundry is `sizeInMeters/2` meters aparts
     * from the`LatLng`
     * @param sizeInMeters
     * @return
     */
    public function toBounds(sizeInMeters:Number):LatLngBounds {
        var latAcc:Number = 180 * sizeInMeters / 40075017;
        var lngAcc:Number = latAcc / Math.cos(Earth.RAD*_lat);
        return LatLngBounds.toLatLngBounds(
                [_lat-latAcc, _lng-lngAcc],
                [_lat+latAcc, _lng+lngAcc]
        );
    }

    public function clone():LatLng {
        return new LatLng(_lat, _lng, alt );
    }

    public function get lat():Number {
        return _lat;
    }

    public function setTo(lat:Number, lng:Number):LatLng{
        _lat = lat;
        _lng = lng;
        return this ;
    }

    public function set lat(value:Number):void {
        _lat = value;
    }

    public function get lng():Number {
        return _lng;
    }

    public function set lng(value:Number):void {
        _lng = value;
    }

    public function get worldX():Number {
        return GeoUtils.lon2x(_lng);
    }

    public function get worldY():Number {
        return GeoUtils.lat2y(_lat);
    }

    public function get worldPoint():Point {
        return new Point(worldX, worldY);
    }

    public function setXY(worldX:Number, worldY:Number):void {
        lng = GeoUtils.x2lon(worldX);
        lat = GeoUtils.y2lat(worldY);
    }

    public function equals(obj:Object, maringError:Number = 0):Boolean {
        // object to compare could be LatLng, Array or Object
        if (!obj) return false;
        var latlng:LatLng = LatLng.toLatLng(obj);
        var margin:Number = Math.max(
                Math.abs(lat - latlng.lat),
                Math.abs(lng - latlng.lng));
        return margin <= (maringError == 0 ? 1.0E-9 : maringError);
    }

    /**
     * Factory method.
     *
     * (latitude: Number, longitude: Number, altitude?: Number): LatLng
     * Creates an object representing a geographical point with the given latitude and longitude (and optionally altitude).
     *
     * latLng(coords: Array): LatLng
     * Expects an array of the form `[Number, Number]` or `[Number, Number, Number]` instead.
     *
     * latLng(coords: Object): LatLng
     * Expects an plain object of the form `{lat: Number, lng: Number}` or `{lat: Number, lng: Number, alt: Number}` instead.
     *
     * @param a
     * @param b
     * @param c
     * @return
     */
    public static function toLatLng(a:*, b:* = null, c:* = null):LatLng {
        if (!a) return null;
        if (a instanceof LatLng) return a as LatLng;
        if (a is Array && typeof a[0] != 'object') {
            if (a.length === 3) return new LatLng(a[0], a[1], a[2]);
            if (a.length === 2) return new LatLng(a[0], a[1]);
            return null;
        }
        if (typeof a == 'object' && a.hasOwnProperty('lat')) {
            return new LatLng(a.lat, 'lng' in a ? a.lng : a.lon, a.alt || 0);
        }
        if (!b) return null;
        return new LatLng(Number(a), b, c);
    }
}
}
