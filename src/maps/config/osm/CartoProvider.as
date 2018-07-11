// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config.osm
{
	import maps.config.*;
	
	import roipeker.utils.StringUtils;
	
	import starling.utils.MathUtil;
	
	/**
	 * Based on
	 * https://carto.com/location-data-services/basemaps/
	 *
	 */
	public class CartoProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_LIGHT:String = "light_all";
		public static const MAPTYPE_DARK:String = "dark_all";
		public static const MAPTYPE_VOYAGER:String = "voyager";
		
		private static const TEMPLATE_URL:String = "https://${s}.basemaps.cartocdn.com/rastertiles/${type}/${z}/${x}/${y}${retina}.png";
		
		public function CartoProvider(mapType:String = MAPTYPE_LIGHT, textureScale:Number = 1)
		{
			super();
			maxZoomLevel = 22;
			_subdomains = ['a', 'b', 'c'];
			this.mapType = mapType;
			this.textureScale = textureScale;
		}
		
		public function set textureScale(value:Number):void
		{
			// round numbers., 1x, 2x, 3x... 5x..
			if (!value) value = 1;
			value = MathUtil.max(Math.ceil(value), 1);
			_textureScale = value;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(TEMPLATE_URL, {
				s: nextSubdomain,
				type: _mapType,
				retina: "@" + _textureScale + "x",
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override public function resolveFilepath(url:String):String
		{
			url = providerId + "/" + trimStart(url, "rastertiles/");
			return url;
		}
	}
}
