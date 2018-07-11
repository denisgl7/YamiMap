package
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	
	import starling.core.Starling;
	import starling.utils.SystemUtil;
	
	//[SWF(width="960",height="640",frameRate="60",backgroundColor="#4a4137")]
	public class Main extends Sprite
	{
		
		private var _starling:Starling;
		
		public function Main()
		{
			super();
			if (this.stage)
			{
				this.stage.scaleMode = StageScaleMode.NO_SCALE;
				this.stage.align = StageAlign.TOP_LEFT;
			}
			
			this.mouseEnabled = this.mouseChildren = false;
			this.loaderInfo.addEventListener(Event.COMPLETE, loaderInfo_completeHandler)
		}
		
		private function loaderInfo_completeHandler(e:Event):void
		{
			Starling.multitouchEnabled = true;
			
			this._starling = new Starling(TestMap, this.stage, null, null, Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
			this._starling.supportHighResolutions = true;
			this._starling.skipUnchangedFrames = true;
			this._starling.simulateMultitouch = true;
			this._starling.antiAliasing = 4;
			this._starling.start();
			if (!SystemUtil.isDesktop)
			{
				NativeApplication.nativeApplication.addEventListener(
						Event.ACTIVATE, function (e:*):void
						{
							_starling.start();
						});
				NativeApplication.nativeApplication.addEventListener(
						Event.DEACTIVATE, function (e:*):void
						{
							_starling.stop(true);
						});
			}
		}
	}
}
