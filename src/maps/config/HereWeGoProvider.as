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
	 * Get apikey
	 * https://developer.here.com/plans?create=Public_Free_Plan_Monthly&keepState=true&step=account
	 *
	 * TODO: IMPLEMENTED based on https://developer.here.com/documentation/map-tile/
	 */
	
	public class HereWeGoProvider extends AbsLayerProvider
	{
		
		public static var appId:String;
		public static var appCode:String;
		
		public function HereWeGoProvider()
		{
			super();
			this.mapType = mapType;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			return StringUtils.formatKeys("", {
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
