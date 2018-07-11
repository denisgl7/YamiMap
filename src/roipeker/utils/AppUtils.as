/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/20/17.
 *
 */
package roipeker.utils
{
	import starling.display.Stage;
	
	public class AppUtils
	{
		public function AppUtils()
		{
		}
		
		public static function generateGUID():String
		{
			// http://en.wikipedia.org/wiki/Globally_unique_identifier
			var i:int, len:int;
			var nums:Vector.<int> = new <int>[1, 2];
			for (i = 0; i < 10; i++) nums.push(Math.round(Math.random() * 255));
			
			var strs:Vector.<String> = new Vector.<String>();
			for (i = 0, len = nums.length; i < len; i++)
			{
				strs.push(("00" + nums[i].toString(16)).substr(-2, 2));
			}
			
			var now:Date = new Date();
			var secs:String = ("0000" + now.getMilliseconds().toString(16)).substr(-4, 4);
			// 4-2-2-6
			return strs[0] + strs[1] + strs[2] + strs[3] + "-" + secs + "-" + strs[4] + strs[5] + "-" + strs[6] + strs[7] + strs[8] + strs[9] + strs[10] + strs[11];
		}
		
		public static function generateRandomString(strlen:Number):String{
			var chars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
			var num_chars:Number = chars.length - 1;
			var randomChar:String = "";
			
			for (var i:Number = 0; i < strlen; i++){
				randomChar += chars.charAt(Math.floor(Math.random() * num_chars));
			}
			return randomChar;
		}
		
	}
}
