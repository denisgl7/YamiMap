// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 08/02/2018.
//
// =================================================================================================

package maps.geo
{
	import maps.MapUtils;
	
	public class Earth
	{
		public function Earth()
		{
		}
		
		// Mean Earth Radius, as recommended for use by
		// the International Union of Geodesy and Geophysics,
		// see http://rosettacode.org/wiki/Haversine_formula
		public static const EARTH_RADIUS:Number = 6371000;
		
		public static const RAD:Number = Math.PI / 180;
		
		public static var wrapLng:Array = [-180, 180];
		
		// define if u wanna wrapit
		public static var wrapLat:Array = null;
		
		public static function distance(latlng1:LatLng, latlng2:LatLng):Number
		{
			var lat1:Number = latlng1.lat * RAD;
			var lat2:Number = latlng2.lat * RAD;
			var sinDLat:Number = Math.sin((latlng2.lat - latlng1.lat) * RAD * .5);
			var sinDLon:Number = Math.sin((latlng2.lng - latlng1.lng) * RAD * .5);
			var a:Number = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon;
			var c:Number = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
			return EARTH_RADIUS * c;
		}
		
		// Returns a `LatLng` where lat and lng has been wrapped according to the
		// CRS's `wrapLat` and `wrapLng` properties, if they are outside the CRS's bounds.
		
		/**
		 * Returns `LatLng` where lat and lng has been wrapped according to Earth.wrapLat and Earth.wrapLng,
		 * if they're outside bounds.
		 * @param latlng
		 * @return
		 */
		public static function wrapLatLng(latlng:LatLng):LatLng
		{
			var lng:Number = wrapLng ? MapUtils.wrapNum(latlng.lng, wrapLng[0], wrapLng[1], true) : latlng.lng;
			var lat:Number = wrapLat ? MapUtils.wrapNum(latlng.lat, wrapLat[0], wrapLat[1], true) : latlng.lat;
			return new LatLng(lat, lng, latlng.alt);
		}
	}
}
