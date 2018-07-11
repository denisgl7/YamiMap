// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config
{
	import flash.display3D.Context3DTextureFormat;
	
	import roipeker.utils.StringUtils;
	
	/**
	 * Get the api key from https://home.openweathermap.org/api_keys
	 *
	 * Reference:
	 * https://msdn.microsoft.com/en-us/library/bb259689.aspx
	 *
	 * language:
	 * https://msdn.microsoft.com/en-us/library/hh441729.aspx
	 *
	 * This endpoint appears to be illegal.
	 * You should get an apiKey to avoid issues.
	 *
	 */
	
	public class BingMapsProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_SATELITE:String = "a";
		public static const MAPTYPE_HYBRID:String = "h";
		public static const MAPTYPE_MAP:String = "r";
		
		private static const TEMPLATE_URL:String =
				"https://ecn.${s}.tiles.virtualearth.net/tiles/${type}${qt}.jpeg?g=1${query}";
		
		public var language:String;
		
		public function BingMapsProvider(mapType:String = MAPTYPE_SATELITE, language:String = "es-ES")
		{
			super();
			minZoomLevel = 0;
			maxZoomLevel = 23;
			_subdomains = ["t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7"];
			this.language = language;
			this.mapType = mapType;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			var qt:String = xyzToQuadTree(x, y, zoom);
			var query:String = "";
			if (_mapType == MAPTYPE_MAP)
			{
				query = "&shading=hill";
			}
			query += "&mkt=" + language;
			
			return StringUtils.formatKeys(TEMPLATE_URL, {
				s: nextSubdomain,
				type: _mapType,
				query: query,
				qt: qt,
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override public function resolveFilepath(url:String):String
		{
			url = trimStart(url, "tiles/", 1);
			var filename:String = url.split("?")[0];
			var res:String = providerId + "/" + language + "/" + _mapType + "/" + filename;
			return res;
		}
		
		private static function xyzToQuadTree(x:int, y:int, z:int):String
		{
			var quadTree:String = "";
			for (var i:int = z; i > 0; i--)
			{
				var digit:int = 0;
				var mask:int = 1 << (i - 1);
				if ((x & mask) != 0)
				{
					++digit;
				}
				if ((y & mask) != 0)
				{
					++digit;
					++digit;
				}
				quadTree += digit;
			}
			return quadTree;
		}
		
		override protected function adjustTextureFormat():void
		{
			if (_mapType == MAPTYPE_MAP)
			{
				textureFormat = Context3DTextureFormat.BGRA_PACKED;
			} else
			{
				textureFormat = Context3DTextureFormat.BGRA;
			}
		}
	}
}
