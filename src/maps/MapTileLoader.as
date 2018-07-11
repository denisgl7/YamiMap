// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package maps
{
	import com.greensock.TweenLite;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import maps.config.AbsLayerProvider;
	
	import roipeker.utils.Pooler;
	
	import starling.events.EventDispatcher;
	import starling.textures.Texture;
	import starling.utils.SystemUtil;
	
	public class MapTileLoader extends EventDispatcher
	{
		
		public static const ERROR:String = 'error';
		public static const PROGRESS:String = 'progress';
		public static const COMPLETE:String = 'complete';
		public static var cacheDir:File;
		public static var verbose:Boolean = false;
		// change this (in seconds) to start the cleanup timer the next time you load.
		public static var cleanupUnusedCacheInterval:Number = 0;
		private static var _pool:Pooler = new Pooler(MapTileLoader);
		private static var loaderContext:LoaderContext;
		private static var _pendingDisposeTextureCacheByUrl:Object = {};
		private static var _textureCacheByUrl:Object = {};
		private static var _instanceByUrl:Object = {};
		private static var _runningRecurrentCleanup:Boolean = false;
		private static var TMP_FILE:File = new File();
		
		public static function get():MapTileLoader
		{
			return _pool.get() as MapTileLoader;
		}
		
		public static function requestTile(url:String, provider:AbsLayerProvider, completeHandler:Function, errorHandler:Function = null):MapTileLoader
		{
			var loader:MapTileLoader = MapTileLoader.get();
			loader.provider = provider;
			loader.addEventListener(MapTileLoader.COMPLETE, completeHandler);
			if (errorHandler)
			{
				loader.addEventListener(MapTileLoader.ERROR, errorHandler);
			}
			//        loader.useMemCache = useCache;
			// how many times used ?
			loader.url = url;
			loader.load();
			return loader;
		}
		
		// delayForNextSwipe pass <=0 to call it once.
		public static function cleanUpUnusedMemCache():void
		{
			trace('MapTileLoader cleanup time...');
			var key:String;
			var count:int = 0;
			for (key in _pendingDisposeTextureCacheByUrl)
			{
				if (clearCachedTexture(key)) ++count;
			}
			trace('MapTileLoader ' + count + ' textures removed from memory');
			_runningRecurrentCleanup = cleanupUnusedCacheInterval > 2;
			if (_runningRecurrentCleanup)
			{
				TweenLite.delayedCall(cleanupUnusedCacheInterval, MapTileLoader.cleanUpUnusedMemCache);
			}
		}
		
		public static function isLoading(url:String):MapTileLoader
		{
			return _instanceByUrl[url] as MapTileLoader;
		}
		
		public static function clearAllCache():void
		{
			var d:Object = _textureCacheByUrl;
			for (var key:String in d)
			{
				if (d[key])
				{
					// todo: deal with the Image invalidation first?
					Texture(d[key]).dispose();
				}
				delete d[key];
			}
			_textureCacheByUrl = {}
		}
		
		public static function clearCachedTexture(url:String):Boolean
		{
			var exists:Boolean = false;
			if (_textureCacheByUrl[url])
			{
				Texture(_textureCacheByUrl[url]).dispose();
				exists = true;
			}
			delete _textureCacheByUrl[url];
			delete _pendingDisposeTextureCacheByUrl[url];
			return exists;
		}
		
		public static function isTextureExistent(url:String, provider:AbsLayerProvider):Boolean
		{
			if (_textureCacheByUrl[url])
			{
				return true;
			} else
			{
				if (!cacheDir) initCacheDir();
				TMP_FILE.url = cacheDir.url + "/" + provider.resolveFilepath(url);
				return TMP_FILE.exists;
			}
		}
		
		//    private var _offlineMode:Boolean = true;
		
		public static function getCachedTexture(url:String):Texture
		{
			return _textureCacheByUrl[url];
		}
		
		public static function addCachedTexture(url:String, texture:Texture):void
		{
			if (_textureCacheByUrl[url])
			{
				trace("MapTileLoader.addCachedTexture() " + url + " already exists");
				// texture already in exists
				Texture(_textureCacheByUrl[url]).dispose();
			}
			_textureCacheByUrl[url] = texture;
			delete _pendingDisposeTextureCacheByUrl[url];
		}
		
		// resolution for tiles.
		//    public var textureScale:Number = 1;
		// use Context3DTextureFormat.BGR_PACKED for regular maps
		//    public var textureFormat:String = "bgra";
		
		//    public var useMemCache:Boolean = false;
		
		public static function addPendingDisposal(url:String):void
		{
			_pendingDisposeTextureCacheByUrl[url] = true;
		}
		
		// to download and load tiles.
		//    public var useFileCache:Boolean = false;
		
		// todo implement some logic to parse the url.
		//    public var fileCacheUrl:String;
		// todo: indicates how many textures can be cached.
		//    public static var maxMemCacheTextures:int = 0;
		
		public static function getInstanceByUrl(url:String):MapTileLoader
		{
			return _instanceByUrl[url] as MapTileLoader;
		}
		
		private static function initCacheDir():void
		{
			cacheDir = SystemUtil.isDesktop ? File.desktopDirectory : File.cacheDirectory;
			cacheDir = cacheDir.resolvePath('mapcache');
		}
		
		public function MapTileLoader()
		{
		}
		
		// use the provider to resolve filepaths.
		public var provider:AbsLayerProvider;
		private var _bytesLoaded:Number = 0;
		private var _bytesTotal:Number = 0;
		private var _percent:Number = 0;
		private var _urlloader:URLLoader;
		private var _loader:Loader;
		private var _request:URLRequest;
		private var _isUrlLoaderOpen:Boolean;
		private var _isLoaderOpen:Boolean;
		private var _file:File = new File();
		
		private var _url:String;
		
		public function get url():String
		{
			return _url;
		}
		
		public function set url(value:String):void
		{
			if (_url == value) return;
			_url = value;
			if (_instanceByUrl[_url])
			{
				error("another instance reference with the same url already exists " + _url);
				delete _instanceByUrl[_url];
			}
			_instanceByUrl[_url] = this;
		}
		
		private var _isLoading:Boolean;
		
		public function get isLoading():Boolean
		{
			return _isLoading;
		}
		
		private var _texture:Texture;
		
		public function get texture():Texture
		{
			return _texture;
		}
		
		// clean up everything in mem cache that's not being used.
		
		// tells if the texture is taken from the cache.
		private var _usingMemCache:Boolean = false;
		
		public function get usingMemCache():Boolean
		{
			return _usingMemCache;
		}
		
		private var _loadingFromDisk:Boolean;
		
		public function get loadingFromDisk():Boolean
		{
			return _loadingFromDisk;
		}
		
		public function returnPool():void
		{
			if (_pool.owns(this))
			{
				_pool.put(this);
			}
			reset();
		}
		
		public function reset():void
		{
			_loadingFromDisk = false;
			if (_urlloader)
			{
				cancel();
				addListenersUrlLoader(false);
			}
			if (_loader)
			{
				addListenersLoader(false);
			}
			delete _instanceByUrl[_url];
			_usingMemCache = false;
			removeEventListeners(ERROR);
			removeEventListeners(COMPLETE);
			removeEventListeners(PROGRESS);
			_url = null;
			provider = null;
			_isLoading = false;
			_bytesLoaded = _bytesTotal = _percent = 0;
			_texture = null;
		}
		
		public function cancel():void
		{
			if (_isUrlLoaderOpen)
			{
				try
				{
					_urlloader.close();
				} catch (e:Error)
				{
					error("Error canceling download " + e);
				}
				_isUrlLoaderOpen = false;
			}
			if (_isLoaderOpen)
			{
				try
				{
					_loader.close();
				} catch (e:Error)
				{
					error("Error canceling loader " + e + "url=" + _url);
				}
				_isLoaderOpen = false;
			}
			if (_isLoading || _texture)
			{
				_loader.unload();
			}
		}
		
		public function load():void
		{
			if (!_url)
			{
				error("url can't be undefined");
				return;
			}
			
			if (!_urlloader)
			{
				init();
			}
			
			if (_isLoading)
			{
				trace('error jere!', _url);
				_isLoading = false;
				// this is a weird scenario... cancel and reload.
				cancel();
				load();
				return;
			}
			
			delete _pendingDisposeTextureCacheByUrl[_url];
			
			if (cleanupUnusedCacheInterval > 2 && !_runningRecurrentCleanup)
			{
				cleanUpUnusedMemCache();
			}
			
			_isLoaderOpen = false;
			
			if (provider.useMemCache && _textureCacheByUrl[_url])
			{
				// already in memory.
				_texture = _textureCacheByUrl[_url] as Texture;
				log("::load() using cached texture " + _url);
				loaderCompleteHandler(null);
				return;
			}
			
			// update local path and see if it's in cache.
			if (provider.useFileCache)
			{
				updateCacheImageRef();
				if (_file.exists)
				{
					// load local file instead.
					loadFromDisk();
					return;
				}
			}
			
			addListenersUrlLoader(true);
			_isLoading = true;
			_isUrlLoaderOpen = true;
			_request.url = _url;
			_urlloader.load(_request);
		}
		
		private function init():void
		{
			if (!cacheDir)
			{
				initCacheDir();
			}
			_isLoading = false;
			_loader = new Loader();
			_urlloader = new URLLoader();
			_urlloader.dataFormat = URLLoaderDataFormat.BINARY;
			_request = new URLRequest();
			if (!loaderContext)
			{
				loaderContext = new LoaderContext(false);
				loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			}
		}
		
		private function loadFromDisk():void
		{
			_loadingFromDisk = true;
			log('loading from disk ' + _file.url);
			addListenersLoader(true);
			//        _isLoading = true ;
			_isLoaderOpen = true;
			_isUrlLoaderOpen = false;
			_request.url = _file.url;
			_loader.load(_request, loaderContext);
		}
		
		private function saveBytes(bytes:ByteArray):void
		{
			if (_file.exists) return;
			trace('saving bytes:', _file.url, bytes.length, _file.exists);
			//        bytes.position = 0;
			var filestream:FileStream = new FileStream();
			filestream.open(_file, FileMode.WRITE);
			filestream.writeBytes(bytes);
			filestream.close();
			filestream = null;
		}
		
		private function addListenersLoader(flag:Boolean):void
		{
			var method:String = flag ? "addEventListener" : "removeEventListener";
			_loader.contentLoaderInfo[method](Event.COMPLETE, loaderCompleteHandler);
			_loader.contentLoaderInfo[method](IOErrorEvent.IO_ERROR, ioErrorHandler);
			_loader.contentLoaderInfo[method](SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}
		
		private function addListenersUrlLoader(flag:Boolean):void
		{
			var method:String = flag ? "addEventListener" : "removeEventListener";
			_urlloader[method](Event.COMPLETE, urlLoaderCompleteHandler);
			_urlloader[method](IOErrorEvent.IO_ERROR, ioErrorHandler);
			_urlloader[method](SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			_urlloader[method](ProgressEvent.PROGRESS, progressHandler);
		}
		
		private function updateCacheImageRef():void
		{
			//        _file.url = cacheDir.url + "/" + providerDir + "/" + MapUtils.getFilepathFromUrl(_url);
			_file.url = cacheDir.url + "/" + provider.resolveFilepath(_url);
		}
		
		private function error(...args):void
		{
			trace('[ MapTileLoader ] ERROR: ' + args.join(" "));
		}
		
		private function log(...args):void
		{
			if (verbose)
				trace('[ MapTileLoader ] ' + args.join(" "));
		}
		
		private function progressHandler(e:ProgressEvent):void
		{
			_bytesLoaded = e.bytesLoaded;
			_bytesTotal = e.bytesTotal;
			_percent = _bytesLoaded / _bytesTotal;
			dispatchEventWith(MapTileLoader.PROGRESS, false, {percent: _percent});
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):void
		{
			error(e);
			dispatchEventWith(ERROR, false, e);
			returnPool();
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void
		{
			error(e);
			dispatchEventWith(ERROR, false, e);
			returnPool();
		}
		
		private function urlLoaderCompleteHandler(e:Event):void
		{
			// get bytes.
			var bytes:ByteArray = _urlloader.data as ByteArray;
			_urlloader.data = null;
			// todo: save for cache?
			if (provider.useFileCache && bytes.length > 0)
			{
				saveBytes(bytes);
			}
			log("::urlLoaderCompleteHandler() " + _url + " ... bytes len:" + bytes.length);
			addListenersUrlLoader(false);
			_isUrlLoaderOpen = false;
			
			if (bytes.length > 0)
			{
				_isLoaderOpen = false;
				addListenersLoader(true);
				_loader.loadBytes(bytes, loaderContext);
			} else
			{
				// todo: save empty texture?
				reset();
				//            loaderCompleteHandler(null);
			}
		}
		
		private function loaderCompleteHandler(event:Event):void
		{
			_usingMemCache = event == null;
			// check if it comes from cache.
			if (event)
			{
				_texture = Texture.fromBitmap(_loader.content as Bitmap, false, false, provider.textureScale, provider.textureFormat);
			} else
			{
				// get from cache.
				_texture = _textureCacheByUrl[_url];
			}
			_isUrlLoaderOpen = false;
			_isLoaderOpen = false;
			_isLoading = false;
			
			if (!_texture)
			{
				error('::loaderCompleteHandler() invalid pointer to texture: ' + _url);
				reset();
				return;
			}
			
			if (provider.useMemCache)
			{
				_textureCacheByUrl[_url] = _texture;
			}
			log("::loaderCompleteHandler() " + _url);
			dispatchEventWith(COMPLETE, false, {texture: _texture});
			returnPool();
		}
		
	}
}
