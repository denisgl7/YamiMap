// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 23/01/2018.
//
// =================================================================================================

package maps
{
	import starling.display.DisplayObject;
	
	public class MapCircOverlay extends MapMarker
	{
		public function MapCircOverlay(id:String, displayObject:DisplayObject, data:Object)
		{
			super(id, displayObject, data);
		}
		public var size:Number;
		
	}
}
