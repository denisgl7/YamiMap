// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config
{
	import roipeker.utils.StringUtils;
	
	/**
	 * Based on
	 * https://mc.bbbike.org/mc/?lon=28.981962&lat=41.007284&zoom=15&num=1&mt0=mapnik&mt1=google-map&mt2=hike_bike&mt3=bbbike-bbbike&mt4=esri-topo&mt5=mapquest-map
	 *
	 */
	public class iPhotoProvider extends AbsLayerProvider
	{
		
		private static const TEMPLATE_URL:String = "http://gsp2.apple.com/tile?api=1&style=slideshow&layers=default&lang=${lang}&z=${z}&x=${x}&y=${y}&v=9";
		// TODO: provide an Enum of locale?
		public var language:String;
		
		public function iPhotoProvider()
		{
			super();
			_urlParamsToFolderSort = ['lang', 'z', 'x', 'y'];
			//         minZoomLevel=2;
			maxZoomLevel = 14;
			language = "en_US"; // de_DE, es_ES
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(TEMPLATE_URL, {
				lang: language,
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override public function resolveFilepath(url:String):String
		{
			return resolveFilepathFromParamsOnly(url, "/tile?");
		}
	}
}
