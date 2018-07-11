// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 08/02/2018.
//
// =================================================================================================

package maps.geo {
import starling.utils.MathUtil;


/*
 * @class LatLngBounds
 * @aka L.LatLngBounds
 *
 * Represents a rectangular geographical area on a map.
 *
 * @example
 *
 * ```js
 * var corner1 = L.latLng(40.712, -74.227),
 * corner2 = L.latLng(40.774, -74.125),
 * bounds = L.latLngBounds(corner1, corner2);
 * ```
 *
 * All Leaflet methods that accept LatLngBounds objects also accept them in a simple Array form (unless noted otherwise), so the bounds example above can be passed like this:
 *
 * ```js
 * map.fitBounds([
 * 	[40.712, -74.227],
 * 	[40.774, -74.125]
 * ]);
 * ```
 *
 * Caution: if the area crosses the antimeridian (often confused with the International Date Line), you must specify corners _outside_ the [-180, 180] degrees longitude range.
 *
 * Note that `LatLngBounds` does not inherit from Leafet's `Class` object,
 * which means new classes can't inherit from it, and new methods
 * can't be added to it with the `include` function.
 */


public class LatLngBounds {
    private var _southWest:LatLng;
    private var _northEast:LatLng;

    /**
     * Constructor.
     * @param corner1    LatLng or []LatLng
     * @param corner2
     */
    public function LatLngBounds(corner1:*, corner2:* = null) {
        if (!corner1) return;

        var list:Array = corner2 ? [corner1, corner2] : [corner1];
        for (var i:int = 0, len:int = list.length; i < len; i++) {
            extend(list[i]);
        }
    }


    /**
     * Extend the bounds to contain the given point.
     * @param obj
     */
    private function extend(obj:Object):LatLngBounds {
        var sw:LatLng = _southWest;
        var ne:LatLng = _northEast;
        var sw2:LatLng, ne2:LatLng;
        if (obj instanceof LatLng) {
            sw2 = ne2 = LatLng(obj);
        } else if (obj instanceof LatLngBounds) {
            sw2 = obj._southWest;
            ne2 = obj._northEast;
            if (!sw2 || !ne2) return this;
        } else {
            return obj ? extend(LatLng.toLatLng(obj) || LatLngBounds.toLatLngBounds(obj)) : this;
        }

        if (!sw && !ne) {
            _southWest = new LatLng(sw2.lat, sw2.lng);
            _northEast = new LatLng(ne2.lat, ne2.lng);
        } else {
            sw.lat = MathUtil.min(sw2.lat, sw.lat);
            sw.lng = MathUtil.min(sw2.lng, sw.lng);
            ne.lat = MathUtil.max(ne2.lat, ne.lat);
            ne.lng = MathUtil.max(ne2.lng, ne.lng);
        }
        return this;
    }


    /**
     * Returns bounds created by extending or contracting the current bounds by a given ratio `bufferRatio` in
     * each direction.
     * For example, a ratio of 0.5 extends the bounds by 50% in each direction.
     * Negative ratio will retract the bounds.
     * @param bufferRatio
     * @return
     */
    public function pad(bufferRatio:Number):LatLngBounds {
        var sw:LatLng = _southWest;
        var ne:LatLng = _northEast;
        var hBuffer:Number = Math.abs(sw.lat - ne.lat) * bufferRatio;
        var wBuffer:Number = Math.abs(sw.lng - ne.lng) * bufferRatio;
        return new LatLngBounds(
                new LatLng(sw.lat - hBuffer, sw.lng - wBuffer),
                new LatLng(ne.lat + hBuffer, ne.lng + wBuffer));
    }


    /**
     * Returns the center of the bounds.
     * @return
     */
    public function getCenter(out:LatLng = null):LatLng {
        if (!out) out = new LatLng(0, 0);
        out.setTo(
                (_southWest.lat + _northEast.lat) * .5,
                (_southWest.lng + _northEast.lng) * .5);
        return out;
    }

    /**
     * Returns `true` if the rectangle contains the given point|bounds.
     * @param obj   LatLng | LatLngBounds
     * @return
     */
    public function contains(obj:*):Boolean {
        if (typeof obj[0] == 'number' || obj instanceof LatLng || 'lat' in obj) {
            obj = LatLng.toLatLng(obj);
        } else {
            obj = LatLngBounds.toLatLngBounds(obj);
        }
        var sw:LatLng = _southWest;
        var ne:LatLng = _northEast;
        var sw2:LatLng, ne2:LatLng;
        if (obj instanceof LatLngBounds) {
            sw2 = LatLngBounds(obj)._southWest;
            ne2 = LatLngBounds(obj)._northEast;
        } else {
            sw2 = ne2 = LatLng(obj);
        }
        return (sw2.lat >= sw.lat) && (ne2.lat <= ne.lat) &&
                (sw2.lng >= sw.lng) && (ne2.lng <= ne.lng);
    }

    /**
     * Returns `true` if the rectangle intersects with the given bounds.
     * 2 bounds intersects if they have at least 1 point in common.
     * @param obj
     * @return
     */
    public function intersects(obj:*):Boolean {
        var bounds:LatLngBounds = toLatLngBounds(obj);
        var sw:LatLng = _southWest;
        var ne:LatLng = _northEast;
        var sw2:LatLng = bounds._southWest;
        var ne2:LatLng = bounds._northEast;
        var latIntersects:Boolean = (ne2.lat >= sw.lat) && (sw2.lat <= ne.lat);
        var lngIntersects:Boolean = (ne2.lng >= sw.lng) && (sw2.lng <= ne.lng);
        return latIntersects && lngIntersects;
    }

    /**
     * Returns `true` if the rectangle overlaps with the given bounds.
     * 2 bounds overlap if they intersection is an area.
     * @param bounds
     * @return
     */
    public function overlaps(bounds:Object):Boolean {
        var bb:LatLngBounds = toLatLngBounds(bounds);
        var sw:LatLng = _southWest;
        var ne:LatLng = _northEast;
        var sw2:LatLng = bb._southWest;
        var ne2:LatLng = bb._northEast;
        var latOverlaps:Boolean = (ne2.lat > sw.lat) && (sw2.lat < ne.lat);
        var lngOverlaps:Boolean = (ne2.lng > sw.lng) && (sw2.lng < ne.lng);
        return latOverlaps && lngOverlaps;
    }

    /**
     * Returns a String with bounding box coordinates
     * Useful for sending requests to web services that return geo data.
     * @return
     */
    public function toBBoxString():String {
        return [west, south, east, north].join(',');
    }

    /**
     * Returns `true` if the rectangle is equivalent (with a `maxMargin` error) to the given bbounds.
     *
     * @param bounds
     * @param maxMargin
     * @return
     */
    public function equals(bounds:Object, maxMargin:Number = 0):Boolean {
        if (!bounds) return false;
        var bb:LatLngBounds = toLatLngBounds(bounds);
        return _southWest.equals(bounds._southWest, maxMargin) &&
                _northEast.equals(bounds._northEast, maxMargin);
    }

    /**
     * Returns `true` if the bounds is properly initialized.
     * @return
     */
    public function isValid():Boolean {
        return _southWest && _northEast;
    }

    public function get southWest():LatLng {
        return _southWest;
    }

    public function get northEast():LatLng {
        return _northEast;
    }

    public function get northWest():LatLng {
        return new LatLng(north, west);
    }

    public function get southEast():LatLng {
        return new LatLng(south, east);
    }

    public function get north():Number {
        return _northEast.lat;
    }

    public function get south():Number {
        return _southWest.lat;
    }

    public function get east():Number {
        return _northEast.lng;
    }

    public function get west():Number {
        return _southWest.lng;
    }


    /**
     * Factory to create a `LatLngBounds`.
     *
     * latLngBounds(corner1: LatLng, corner2: LatLng)
     * Creates a `LatLngBounds` object defining two diagonally opposite corners of a rectangle.
     *
     * latLngBounds(latlngs:[] LatLng)
     * Creates a `LatLngBounds` object defined by the geographical points it contains.
     * Very useful for zooming the map to fit a particular set of locations with `map.fitBounds()`
     *
     * @param a
     * @param b
     * @return
     */
    public static function toLatLngBounds(a:*, b:* = null):LatLngBounds {
        if (a instanceof LatLngBounds) return a;
        return new LatLngBounds(a, b);
    }

}
}
