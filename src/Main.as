package
{
	import feathers.utils.ScreenDensityScaleFactorManager;
	
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.filesystem.File;
	
	import starling.assets.AssetManager;
	import starling.core.Starling;
	import starling.events.Event;
	import starling.extension.CachingDataLoader;
	import starling.utils.SystemUtil;
	
	//[SWF(width="960",height="640",frameRate="60",backgroundColor="#4a4137")]
	public class Main extends Sprite
	{
		
		private var _starling:Starling;
		private var _scaler:ScreenDensityScaleFactorManager;
		
		public function Main()
		{
			super();
			if (this.stage)
			{
				this.stage.scaleMode = StageScaleMode.NO_SCALE;
				this.stage.align = StageAlign.TOP_LEFT;
			}
			
			this.mouseEnabled = this.mouseChildren = false;
			this.loaderInfo.addEventListener(flash.events.Event.COMPLETE, loaderInfo_completeHandler)
		}
		
		private function loaderInfo_completeHandler(e:flash.events.Event):void
		{
			Starling.multitouchEnabled = true;
			
			this._starling = new Starling(YamiMap, this.stage, null, null, Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
			this._starling.supportHighResolutions = true;
			this._starling.skipUnchangedFrames = true;
			this._starling.simulateMultitouch = true;
			this._starling.antiAliasing = 4;
			this._starling.addEventListener(starling.events.Event.ROOT_CREATED, function ():void
			{
				loadAssets();
			});
			//this._starling.showStats = true;
			this._starling.start();
			this._scaler = new ScreenDensityScaleFactorManager(this._starling);
			if (!SystemUtil.isDesktop)
			{
				NativeApplication.nativeApplication.addEventListener(
						flash.events.Event.ACTIVATE, function (e:*):void
						{
							_starling.start();
						});
				NativeApplication.nativeApplication.addEventListener(
						flash.events.Event.DEACTIVATE, function (e:*):void
						{
							_starling.stop(true);
						});
			}
		}
		
		private var assets:AssetManager;
		
		private function loadAssets():void
		{
			var appDir:File = File.applicationDirectory;
			assets = new AssetManager();
			assets.verbose = false;
			assets.dataLoader = new CachingDataLoader('starling_cache');
			assets.enqueue(appDir.resolvePath("assets"));
			assets.textureOptions.scale = 2;
			assets.enqueue(appDir.resolvePath("images"));
			assets.textureOptions.scale = _starling.contentScaleFactor;
			assets.enqueue(appDir.resolvePath("font"));
			assets.loadQueue(startGame);
			
		}
		
		private function startGame():void
		{
			var game:YamiMap = _starling.root as YamiMap;
			game.start(assets);
			//setTimeout(removeElements, 150); // delay to make 100% sure there's no flickering.
		}
	}
}
