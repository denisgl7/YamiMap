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
	
	import starling.utils.MathUtil;
	
	/**
	 * Based on
	 * https://wiki.openstreetmap.org/wiki/Tile_servers
	 * http://maps.stamen.com/
	 *
	 * no textureScale support for watercolor
	 */
	
	public class StamenProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_TONER:String = "toner";
		public static const MAPTYPE_TERRAIN:String = "terrain"; // supports up to zoom 14 in 1x, and zoom 10 in 2x.
		public static const MAPTYPE_WATERCOLOR:String = "watercolor"; // don't support retina.
		
		private static const TEMPLATE_URL:String = "http://${s}.tile.stamen.com/${type}/${z}/${x}/${y}${scale}.png";
		
		public function StamenProvider(mapType:String = MAPTYPE_TERRAIN, textureScale:Number = 1)
		{
			_subdomains = ['a', 'b', 'c'];
			//        maxZoomLevel = 14 ;
			this.mapType = mapType;
			this.textureScale = textureScale;
		}
		
		public function set textureScale(value:Number):void
		{
			if (!value) value = 0;
			_textureScale = MathUtil.clamp(Math.ceil(value), 1, 2);
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			var scale:String = "@" + _textureScale + "x";
			if (_mapType == MAPTYPE_WATERCOLOR || _textureScale == 1)
			{
				scale = "";
			}
			return StringUtils.formatKeys(TEMPLATE_URL, {
				scale: scale,
				type: _mapType,
				s: nextSubdomain,
				x: x,
				y: y,
				z: zoom
			});
		}
		
		override protected function adjustTextureFormat():void
		{
			if (_mapType == MAPTYPE_TONER)
			{
				textureFormat = Context3DTextureFormat.BGRA_PACKED;
			} else
			{
				textureFormat = Context3DTextureFormat.BGRA;
			}
		}
	}
}
