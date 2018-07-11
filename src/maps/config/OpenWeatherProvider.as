// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config
{
	import roipeker.utils.StringUtils;
	
	/**
	 * Get the api key from https://home.openweathermap.org/api_keys
	 *
	 */
	public class OpenWeatherProvider extends AbsLayerProvider
	{
		
		public static var apiKey:String;
		
		public static const MAPTYPE_WIND:String = 'wind_new';
		public static const MAPTYPE_TEMPERATURE:String = 'temp_new';
		public static const MAPTYPE_PRESSURE:String = 'pressure_new';
		public static const MAPTYPE_PRECIPITATIONS:String = 'precipitation_new';
		public static const MAPTYPE_CLOUDS:String = 'clouds_new';
		
		private static const TEMPLATE_URL:String = "http://tile.openweathermap.org/map/${type}/${z}/${x}/${y}.png?APPID=${apikey}";
		
		public function OpenWeatherProvider(mapType:String = MAPTYPE_WIND)
		{
			super();
			if (!apiKey)
			{
				trace(this + " please get an API key");
			}
			minZoomLevel = 0;
			maxZoomLevel = 19;
			this.mapType = mapType;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(TEMPLATE_URL, {
				type: _mapType,
				apikey: apiKey,
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override public function resolveFilepath(url:String):String
		{
			return providerId + "/" + trimBetween(url, "map/", "?");
		}
	}
}
