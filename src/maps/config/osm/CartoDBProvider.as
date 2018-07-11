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
	 *
	 * Based on
	 * https://github.com/CartoDB/cartodb/wiki/BaseMaps-available
	 *
	 * all types allows 1x/2x
	 *
	 * This maps are references for low zoom values (< ~10 zoom) higher values are scaled.
	 *
	 */
	
	public class CartoDBProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_DARK:String = "base-dark";
		public static const MAPTYPE_LIGHT:String = "base-light";
		public static const MAPTYPE_LIGHT_NOLABELS:String = "base-light-nolabels";
		public static const MAPTYPE_FLATBLUE:String = "base-flatblue";
		public static const MAPTYPE_ANTIQUE:String = "base-antique";
		public static const MAPTYPE_MIDNIGHT:String = "base-midnight";
		public static const MAPTYPE_ECO:String = "base-eco";
		
		private static const TEMPLATE_URL:String = "https://cartocdn_${s}.global.ssl.fastly.net/${type}/${z}/${x}/${y}${retina}.png";
		
		public function CartoDBProvider(mapType:String = MAPTYPE_LIGHT, textureScale:Number = 1)
		{
			super();
			maxZoomLevel = 17;
			_subdomains = ['a', 'b', 'c'];
			this.mapType = mapType;
			this.textureScale = textureScale;
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
		
		public function set textureScale(value:Number):void
		{
			if (!value) value = 1;
			value = MathUtil.clamp(Math.round(value), 1, 2);
			_textureScale = value;
		}
		
		override public function resolveFilepath(url:String):String
		{
			return providerId + "/" + trimStart(url, ".net/");
		}
	}
}
