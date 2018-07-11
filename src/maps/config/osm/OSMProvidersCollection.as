// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 28/01/2018.
//
// =================================================================================================

package maps.config.osm
{
	import maps.MapUtils;
	import maps.config.*;
	
	import roipeker.utils.StringUtils;
	
	/**
	 * This is a providers collection class of all maps built with OSM, that doesn't make use of most common code in AbsLayerProvider.
	 * All maps are 1x, there's no validation for templateUrl, nor automatic textureFormat, nor maxZoomLevel
	 *
	 * All providers were collected from
	 * https://mc.bbbike.org/mc/
	 *
	 */
	
	public class OSMProvidersCollection extends AbsLayerProvider
	{
		
		public static const PROVIDER_LIGHTS:String = "http://korona.geog.uni-heidelberg.de:8005/tms_lt.ashx?x=${x}&y=${y}&z=${z}";
		public static const PROVIDER_MAPNIK_DE:String = "https://${s}.tile.openstreetmap.de/tiles/osmde/${z}/${x}/${y}.png";
		public static const PROVIDER_MAPNIK_BW:String = "https://tiles.wmflabs.org/bw-mapnik/${z}/${x}/${y}.png";
		public static const PROVIDER_OPEN_TOPO:String = "https://${s}.tile.opentopomap.org/${z}/${x}/${y}.png";
		public static const PROVIDER_OPEN_PUBLIC_TRANSPORT_L:String = "http://www.openptmap.org/tiles/${z}/${x}/${y}.png";
		public static const PROVIDER_OPEN_PUBLIC_TRANSPORT:String = "http://tile.memomaps.de/tilegen/${z}/${x}/${y}.png";
		public static const PROVIDER_OSM_ROADS:String = "http://korona.geog.uni-heidelberg.de/tiles/roads/?x=${x}&y=${y}&z=${z}";
		public static const PROVIDER_OSM_ROADS_GREYSCALE:String = "http://korona.geog.uni-heidelberg.de/tiles/roadsg/?x=${x}&y=${y}&z=${z}";
		public static const PROVIDER_HYDDA_BASE:String = "http://${s}.tile.openstreetmap.se/hydda/base/${z}/${x}/${y}.png";
		public static const PROVIDER_HYDDA_FULL:String = "http://${s}.tile.openstreetmap.se/hydda/full/${z}/${x}/${y}.png";
		public static const PROVIDER_HYDDA_ROADSLABELS:String = "http://${s}.tile.openstreetmap.se/hydda/roads_and_labels/${z}/${x}/${y}.png";
		public static const PROVIDER_OSM_SE_STANDARD:String = "http://${s}.tile.openstreetmap.se/osm/${z}/${x}/${y}.png";
		public static const PROVIDER_OSM_SEMITRANSPARENT:String = "http://korona.geog.uni-heidelberg.de/tiles/hybrid/?x=${x}&y=${y}&z=${z}";
		public static const PROVIDER_OSM_NOLABELS:String = "https://tiles.wmflabs.org/osm-no-labels/${z}/${x}/${y}.png";
		public static const PROVIDER_HIKEBIKE:String = "https://tiles.wmflabs.org/hikebike/${z}/${x}/${y}.png";
		public static const PROVIDER_OSMFR:String = "https://${s}.tile.openstreetmap.fr/osmfr/${z}/${x}/${y}.png";
		public static const PROVIDER_OSMFR_HOT:String = "https://${s}.tile.openstreetmap.fr/hot/${z}/${x}/${y}.png";
		public static const PROVIDER_OSMFR_OPENRIVERBOATMAP:String = "https://${s}.tile.openstreetmap.fr/openriverboatmap/${z}/${x}/${y}.png";
		public static const PROVIDER_OSM_ADMIN_BOUNDRIES:String = "http://korona.geog.uni-heidelberg.de/tiles/adminb/?x=${x}&y=${y}&z=${z}";
		public static const PROVIDER_OSM_GPS:String = "https://${s}.gps-tile.openstreetmap.org/lines/${z}/${x}/${y}.png";
		public static const PROVIDER_OSM:String = "https://${s}.tile.openstreetmap.org/${z}/${x}/${y}.png";
		
		public static const PROVIDER_ASTERH:String = "http://korona.geog.uni-heidelberg.de/tiles/asterh/?x=${x}&y=${y}&z=${z}";
		
		public function OSMProvidersCollection(MAP_TEMPLATE:String = PROVIDER_OSM)
		{
			super("osm-collection");
			_subdomains = ['a', 'b', 'c'];
			_textureScale = 1;
			templateUrl = MAP_TEMPLATE;
		}
		
		private var _templateUrl:String;
		
		public function get templateUrl():String
		{
			return _templateUrl;
		}
		
		public function set templateUrl(value:String):void
		{
			_templateUrl = value;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(_templateUrl, {
				s: nextSubdomain,
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override public function resolveFilepath(url:String):String
		{
			//        url = super.resolveFilepath(url);
			
			// trying to normalize the generic urls as filepaths...
			url = trimStart(url, "://");
			var baseUrl:String = trimStart(trimEnd(trimEnd(url, ':'), '/'), '.');
			// remove the first subdomain.
			var rest:String = trimStart(url, '/');
			// if has params...
			var params:String = "";
			if (rest.indexOf("?") > -1)
			{
				rest = trimEnd(rest, "?");
				// split the params....
				params = MapUtils.getFilepathFromUrlParams(url);
			}
			return providerId + "/" + baseUrl + "/" + rest + "/" + params;
		}
	}
}
