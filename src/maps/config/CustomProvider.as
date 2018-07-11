// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config
{
	import roipeker.utils.StringUtils;
	
	/**
	 * Requires a template url with x, y, zoom
	 * enclose replacement params in ${}
	 *
	 * http://provider.com/${zoom}/${x}/${y}
	 *
	 */
	public class CustomProvider extends AbsLayerProvider
	{
		
		private var _templateUrl:String;
		
		public function CustomProvider(baseUrl:String)
		{
			_templateUrl = baseUrl;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys(_templateUrl, {
				x: x,
				y: y,
				z: zoom
			});
		}
		
	}
}
