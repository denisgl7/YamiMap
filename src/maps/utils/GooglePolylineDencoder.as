// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 08/02/2018.
//
// =================================================================================================

package maps.utils
{
	
	/**
	 * Ported from https://github.com/mapbox/polyline/
	 *
	 * Encoder/Decoder for Google Polylines string.
	 *
	 * Get polylines from Google's API
	 *
	 * Sample:
	 * https://maps.googleapis.com/maps/api/directions/json?origin=%22228%20Mott,%20New%20York,%20NY%22&destination=%22102%20St%20Marks%20Pl,%20New%20York,%20NY%22
	 *
	 */
	public class GooglePolylineDencoder
	{
		
		/**
		 * Decodes to a [latitude, longitude] coordinates array.
		 * This is adapted from the implementation in Project-OSRM.
		 *
		 * @param str
		 * @param precision
		 * @return  Array
		 *
		 * @see https://github.com/Project-OSRM/osrm-frontend/blob/master/WebContent/routing/OSRM.RoutingGeometry.js
		 */
		public static function decode(str:String, precision:Number = 0):Array
		{
			var index:int = 0, lat:Number = 0, lng:Number = 0, coordinates:Array = [], shift:int = 0;
			var result:Number = 0, byte:int = 0, latChange:int, lngChange:int;
			var factor:Number = Math.pow(10, precision || 5);
			
			// Coordinates have variable length when encoded, so just keep
			// track of whether we've hit the end of the string. In each
			// loop iteration, a single coordinate is decoded.
			while (index < str.length)
			{
				// reset shift, result and byte
				byte = 0;
				shift = 0;
				result = 0;
				do
				{
					byte = str.charCodeAt(index++) - 63;
					result |= (byte & 0x1f) << shift;
					shift += 5;
				} while (byte >= 0x20);
				latChange = ((result & 1) ? ~(result >> 1) : (result >> 1));
				shift = result = 0;
				
				do
				{
					byte = str.charCodeAt(index++) - 63;
					result |= (byte & 0x1f) << shift;
					shift += 5;
				} while (byte >= 0x20);
				lngChange = ((result & 1) ? ~(result >> 1) : (result >> 1));
				
				lat += latChange;
				lng += lngChange;
				coordinates[coordinates.length] = [lat / factor, lng / factor];
			}
			return coordinates;
		}
		
		/**
		 *  Encodes the given [latitude, longitude] coordinates array.
		 * @param coordinates
		 * @param precision
		 * @return  String
		 */
		public static function encode(coordinates:Array, precision:Number = 0):String
		{
			if (!coordinates || !coordinates.length) return "";
			var factor:Number = Math.pow(10, precision || 5);
			var output:String = encodeValue(coordinates[0][0], 0, factor) + encodeValue(coordinates[0][1], 0, factor);
			for (var i:int = 1, len:int = coordinates.length; i < len; i++)
			{
				trace('wtf?', i);
				var a:Array = coordinates[i], b:Array = coordinates[int(i - 1)];
				output += encodeValue(a[0], b[0], factor);//lat
				output += encodeValue(a[1], b[1], factor);//lng
			}
			return output;
		}
		
		/**
		 * Encodes a GeoJSON LineString feature/geometry.
		 *
		 * @param geojson
		 * @param precision
		 * @return
		 */
		public static function fromGeoJson(geojson:Object, precision:Number = 0):String
		{
			if (geojson && geojson.type == "Feature")
			{
				geojson = geojson.geometry;
			}
			if (!geojson || geojson.type != "LineString")
			{
				throw new Error("Input must be a GeoJSON LineString");
			}
			return encode(flipped(geojson.coordinates), precision);
		}
		
		/**
		 * Decodes to a GeoJSON LineString geometry.
		 * @param str
		 * @param precision
		 * @return
		 */
		public static function toGeoJson(str:String, precision:Number = 0):Object
		{
			var coords:Array = decode(str, precision);
			return {
				type: 'LineString',
				coordinates: flipped(coords)
			};
		}
		
		private static function py2round(value:Number):Number
		{
			// Google's polyline algorithm uses the same rounding strategy as Python 2, which is different from JS for negative values
			return Math.floor(Math.abs(value) + 0.5) * (value >= 0 ? 1 : -1);
		}
		
		// geojson stuffs.
		
		private static function encodeValue(current:Number, prev:Number, factor:Number):String
		{
			current = py2round(current * factor);
			prev = py2round(prev * factor);
			var coordinate:Number = current - prev;
			coordinate <<= 1;
			if (current - prev < 0)
			{
				coordinate = ~coordinate;
			}
			var output:String = "";
			while (coordinate >= 0x20)
			{
				output += String.fromCharCode((0x20 | (coordinate & 0x1f)) + 63);
				coordinate >>= 5;
			}
			output += String.fromCharCode(coordinate + 63);
			return output;
		}
		
		private static function flipped(coords:Array):Array
		{
			var flipped:Array = [];
			for (var i:int = 0, len:int = coords.length; i < len; i++)
			{
				flipped.push(coords[i].slice().reverse());
			}
			return flipped;
		}
		
		// static class
		public function GooglePolylineDencoder()
		{
		}
		
	}
}
