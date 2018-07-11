/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/28/17.
 *
 */
package roipeker.starling.ui {
import starling.events.Event;

public class UIDef {

	public static const VERTICAL:String = "vertical";
	public static const HORIZONTAL:String = "horizontal";

	public static const OPEN:String = "open";
	public static const OPENED:String = "opened";
	public static const CLOSE:String = "close";
	public static const CLOSED:String = "closed";

	// custom HitButton events.
	public static const PRESS:String = "press";
	public static const RELEASE:String = "release";
	public static const TAP:String = Event.TRIGGERED ;
	public static const ALL_BUTTON_EVENTS: Array = [PRESS, RELEASE, TAP ];

	public function UIDef() {
	}
}
}
