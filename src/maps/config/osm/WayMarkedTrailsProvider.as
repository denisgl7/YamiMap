// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config.osm
{
	import flash.display3D.Context3DTextureFormat;
	
	import maps.config.*;
	
	import roipeker.utils.StringUtils;
	
	/**
	 * Based on
	 * https://wiki.openstreetmap.org/wiki/Tile_servers
	 * https://waymarkedtrails.org/
	 *
	 * no textureScale support.
	 */
	
	public class WayMarkedTrailsProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_MTB:String = "mtb";
		public static const MAPTYPE_CYCLING:String = "cycling";
		public static const MAPTYPE_HIKING:String = "hiking";
		public static const MAPTYPE_SKATING:String = "skating";
		public static const MAPTYPE_HORSE_RIDING:String = "riding";
		public static const MAPTYPE_WINTER_SPORT_SLOPES:String = "slopes";
		
		public static const MAPTYPE_HILLSHADING:String = "hillshading"; // used as an overlay or OSM.
		
		private static const TEMPLATE_URL:String = "https://tile.waymarkedtrails.org/${type}/${z}/${x}/${y}.png";
		
		public function WayMarkedTrailsProvider(mapType:String = MAPTYPE_MTB)
		{
			super();
			_subdomains = null;
			//        maxZoomLevel = 14 ;
			this.mapType = mapType;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(TEMPLATE_URL, {
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
	}
}
