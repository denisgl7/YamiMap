// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config
{
	import flash.display3D.Context3DTextureFormat;
	import flash.net.URLVariables;
	
	import roipeker.utils.StringUtils;
	
	import starling.utils.MathUtil;
	
	/**
	 * This tile access appears to be illegal.
	 * You should get an API key.
	 */
	public class GoogleMapsProvider extends AbsLayerProvider
	{
		
		public static const MAPTYPE_ROAD_ONLY:String = 'h';
		public static const MAPTYPE_ROADMAP:String = 'm'; // "r" does the same?
		public static const MAPTYPE_TERRAIN:String = 'p';
		public static const MAPTYPE_TERRAIN_ONLY:String = 't';
		public static const MAPTYPE_SATELLITE_ONLY:String = 's';
		public static const MAPTYPE_HYBRID:String = 'y';
		
		private static const TEMPLATE_URL:String = "https://${s}.google.com/vt/?hl=${lang}&lyrs=${layers}&x=${x}&y=${y}&z=${z}&scale=${scale}";
		
		// TODO: provide an Enum of locale?
		public var language:String;
		
		public function GoogleMapsProvider(mapType:String = MAPTYPE_ROADMAP, textureScale:Number = 1, language:String = "en-US")
		{
			super();
			_urlParamsToFolderSort = ['hl', 'scale', 'lyrs', 'z', 'x', 'y'];
			maxZoomLevel = 22;
			this.language = language;
			_subdomains = ["mt1", "mt2", "mt3"];
			this.mapType = mapType;
			this.textureScale = textureScale;
		}
		
		override public function resolveUrl(x:uint, y:uint, zoom:Number):String
		{
			if (zoom > maxZoomLevel) zoom = maxZoomLevel;
			return StringUtils.formatKeys(TEMPLATE_URL, {
				s: nextSubdomain,
				layers: mapType,
				lang: language,
				x: x,
				y: y,
				z: zoom,
				scale: _textureScale
			});
		}
		
		/*    h = roads only
			m = standard roadmap
			p = terrain
			r = somehow altered roadmap
			s = satellite only
			t = terrain only
			y = hybrid*/
		
		/*override public function set mapType(value:String):void {
			super.mapType = value;
			textureFormat = _mapType.indexOf('s') > -1 || _mapType.indexOf('y') > -1 ? "bgra" : "bgrPacked565";
		}*/
		
		public function set textureScale(value:Number):void
		{
			if (!value) value = 0;
			_textureScale = MathUtil.clamp(value, .125, 4);
		}
		
		override protected function adjustTextureFormat():void
		{
			if (_mapType.indexOf(MAPTYPE_SATELLITE_ONLY) > -1 || _mapType.indexOf(MAPTYPE_HYBRID) > -1)
			{
				textureFormat = Context3DTextureFormat.BGRA;
			} else
			{
				textureFormat = Context3DTextureFormat.BGRA_PACKED;
			}
		}
		
		override public function resolveFilepath(url:String):String
		{
			// automatically resolve url path with parameters (will start with googlemaps/vt/) though.
			//        return super.resolveFilepath(url);
			
			// common resolver for url parameters > filepath.
			//        return resolveFilepathFromParamsOnly( url, "vt/?" );
			
			// or make a custom resolver.
			var resultPath:String = providerId + "/";
			var urlvars:URLVariables = new URLVariables(trimStart(url, "vt/?"));
			var keys:Array = _urlParamsToFolderSort;
			var len:int = keys.length;
			for (var i:int = 0; i < len; i++)
			{
				resultPath += urlvars[keys[i]];
				if (i < len - 1)
				{
					resultPath += "/";
				}
			}
			urlvars = null;
			return resultPath;
		}
		
	}
}
