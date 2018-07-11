// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 28/01/2018.
//
// =================================================================================================

package maps.config.osm
{
	import flash.display3D.Context3DTextureFormat;
	
	import maps.config.*;
	
	import roipeker.utils.StringUtils;
	
	/**
	 * Based on
	 * https://mc.bbbike.org
	 * Most bikes routes based in Germany.
	 *
	 * url sample:
	 * https://b.tile.bbbike.org/osm/mapnik/9/278/169.png
	 */
	public class BbbikeProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_MAPNIK:String = "mapnik";
		public static const MAPTYPE_SMOOTHNESS:String = "bbbike-smoothness";
		public static const MAPTYPE_GREEN:String = "bbbike-green";
		public static const MAPTYPE_BBBIKE:String = "bbbike";
		public static const MAPTYPE_CYCLEROUTES:String = "bbbike-cycle-routes";
		public static const MAPTYPE_CYCLEWAY:String = "bbbike-cycleway";
		public static const MAPTYPE_HANDICAP:String = "bbbike-handicap";
		public static const MAPTYPE_UNLIT:String = "bbbike-unlit";
		
		private static const TEMPLATE_URL:String = "https://${s}.tile.bbbike.org/osm/${type}/${z}/${x}/${y}.png";
		
		public function BbbikeProvider(mapType:String = MAPTYPE_MAPNIK)
		{
			super();
			maxZoomLevel = 18;
			_subdomains = ['a', 'b', 'c', 'd'];
			this.mapType = mapType;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(TEMPLATE_URL, {
				s: nextSubdomain,
				type: _mapType,
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override protected function adjustTextureFormat():void
		{
			textureFormat = Context3DTextureFormat.BGRA_PACKED;
		}
		
		override public function resolveFilepath(url:String):String
		{
			return providerId + "/" + trimStart(url, "/osm/");
		}
	}
}
