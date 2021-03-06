// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 23/01/2018.
//
// =================================================================================================

package maps
{
	import starling.display.DisplayObject;
	
	public class MapMarker
	{
		private var _id:String;
		private var _data:Object;
		private var _displayObject:DisplayObject;
		private var _initialScale:Number;
		
		public function MapMarker(id:String, displayObject:DisplayObject, data:Object)
		{
			this._id = id;
			this._displayObject = displayObject;
			this._data = data;
		}
		
		public function get id():String
		{
			return _id;
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function get displayObject():DisplayObject
		{
			return _displayObject;
		}
		
		/* DELEGATE starling.display.DisplayObject */
		
		public function get x():Number
		{
			return displayObject.x;
		}
		
		public function set x(value:Number):void
		{
			displayObject.x = value;
		}
		
		public function get y():Number
		{
			return displayObject.y;
		}
		
		public function set y(value:Number):void
		{
			displayObject.y = value;
		}
		
	}
}
