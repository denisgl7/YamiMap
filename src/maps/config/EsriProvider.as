// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config
{
	import roipeker.utils.StringUtils;
	
	/**
	 * Based on:
	 * https://mc.bbbike.org/mc/
	 *
	 * todo: Maybe implement mapbox for retina support?
	 * https://www.mapbox.com/esriconnect/
	 *
	 */
	
	public class EsriProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_STREET_MAP:String = "World_Street_Map";
		public static const MAPTYPE_BOUNDRIES_PLACES:String = "Reference/World_Boundaries_and_Places";
		public static const MAPTYPE_GRAY:String = "Canvas/World_Light_Gray_Base";
		public static const MAPTYPE_NATGEO:String = "NatGeo_World_Map";
		public static const MAPTYPE_OCEAN:String = "Ocean/World_Ocean_Base";
		public static const MAPTYPE_PHYISICAL:String = "World_Physical_Map";
		public static const MAPTYPE_REFERENCE_OVERLAY:String = "Reference/World_Reference_Overlay";
		public static const MAPTYPE_SATELLITE:String = "World_Imagery";
		public static const MAPTYPE_SHADED_RELIEF:String = "World_Shaded_Relief";
		public static const MAPTYPE_TERRAIN:String = "World_Terrain_Base"; // max zoom = 10
		public static const MAPTYPE_TOPO_MAP:String = "World_Topo_Map";
		public static const MAPTYPE_TRANSPORTATION:String = "Reference/World_Transportation";
		
		private static const TEMPLATE_URL:String = "https://${s}.arcgisonline.com/ArcGIS/rest/services/${type}/MapServer/tile/${z}/${y}/${x}.jpg";
		
		public function EsriProvider(mapType:String = MAPTYPE_STREET_MAP)
		{
			super();
			//        trace('provider id:', providerId );
			minZoomLevel = 0;
			maxZoomLevel = 18;
			_subdomains = ["server", "services"];
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
		}
		
	}
}
