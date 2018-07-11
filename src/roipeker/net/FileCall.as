/**
 * Code by Rodrigo López Peker on 2/16/16 10:43 PM.
 *
 */
package roipeker.net {

import roipeker.callbacks.Callback;
import roipeker.io.SOMan;
import roipeker.utils.FileUtils;
import roipeker.utils.Pooler;
import roipeker.utils.StringUtils;
import roipeker.utils.URIUtils;

import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.net.URLStream;
import flash.utils.ByteArray;
import flash.utils.getTimer;

/**
 * Utility File class to download any file and write on disk
 *
 * Sample:
 *

 var imageUrl:String = "https://upload.wikimedia.org/wikipedia/commons/d/dd/Big_%26_Small_Pumkins.JPG" ;
 FileCall.call( imageUrl, File.desktopDirectory.resolvePath( "down" ), onFileStatus, {
			verbose: true,
			allowResume: true
		});

 */
public class FileCall {

//	private static var _pool:LoanShark = new LoanShark( FileCall, false, 3, 0, null, "", "dispose" );
	private static var _pool:Pooler;

	public static function get():FileCall {
		if ( !_pool ) _pool = new Pooler( FileCall, 0, 0, null, null, 'dispose' );
		var call:FileCall = _pool.get() as FileCall;
		if ( !call._cleaned ) {
			call.reset();
		}
		call.verbose = ServiceCall.verbose;
		return call;
	}

	public function reset():void {
		if ( _pool && _pool.owns( this ) ) {
			_pool.put( this );
		}
		writeFileOnComplete = false;
		_pausedUrl = null;
		addEvents( false );
		setSignal( null, null, null );
		_cleaned = true;
		if ( _onStatus ) _onStatus.removeAll();
		userData = null;
		if ( _requesting ) {
			// try catch() if there's no current request, but impossible cause this class
			// deals with that, and is not exposed
			_loader.close();
		}
		_deltaTime = 0;
		allowResume = false;
		_requesting = false;
		_request.contentType = null;
		_request.method = URLRequestMethod.GET;
		_request.data = null;
		_request.requestHeaders = [];

		statusHeaders = null;
		statusCode = 0;
		statusRedirected = false;
		statusUrl = null;
		verbose = false;
		userData = null;
		_cleaned = true;
		_override = true;
		_deleteTmpFileOnCancelError = true;
		tmpFile = null;
		file = null;
		_bytesLoaded = _bytesPreloaded = _percent = _percentTotal = _bytesTotal = 0;
	}

	public static var defaultDownloadDir:File;
	public static var defaultTmpDir:File;

	public static const PROGRESS:String = "downloadProgress";
	public static const COMPLETE:String = "complete";
	public static const CANCEL:String = "cancel";
	public static const ERROR:String = "error";
	public static const STATUS:String = "status";

	public static var verbose:Boolean = false;
	public static var cacheMap:Object;
	private static var _cacheId:String = "fcall_cache";


	private var _onStatus:Callback;
	// todo: implement global failure notification.
	private static var _failure:Callback;

	private static var headerCache:URLRequestHeader;

	// callbacks for storing cache information... can be Cache or SOMan functions.
	public static var cache_set:Function;
	public static var cache_get:Function;


	// cleaned define the state of the SCall instance, if its "clean" means it's reset() to the default state, and can be used with
	// the default setup.
	private var _cleaned:Boolean;
	private var _request:URLRequest;
	private var _loader:URLStream;
	private var _requesting:Boolean;
	private var _override:Boolean;

	public var allowResume:Boolean;

	// for this specific instance, default to false.
	public var verbose:Boolean;

	// stores any information here.
	public var userData:Object;

	// global failure notification
	private var _deleteTmpFileOnCancelError:Boolean;
	private var _status:Object;

	private var _ba:ByteArray;
	private var _fileStream:FileStream;
	private var _percent:Number;

	// temporal file to write.
	public var tmpFile:File;

	// final/target file on disk
	public var file:File;

	public var statusHeaders:Array;
	public var statusCode:int;
	public var statusUrl:String;
	public var statusRedirected:Boolean;

	// only useful for windows.
	public var writeFileOnComplete:Boolean = false;

	private var _deltaTime:int;

	private var _percentTotal:Number;
	private var _bytesTotal:int;
	private var _bytesLoaded:uint;
	private var _bytesPreloaded:uint;
	private var _contentLength:int;

	/**
	 * Constructor.
	 */
	public function FileCall():void {
		if ( !headerCache ) {
			headerCache = new URLRequestHeader( "Range", "bytes=X-" );
		}

		if ( !cache_get ) {
			cache_set = SOMan.instance.set;
			cache_get = SOMan.instance.get;
		}

		initCache();

		_bytesTotal = -1;
		_cleaned = true;
		_override = true;
		_deleteTmpFileOnCancelError = true;
		_status = {target: this};
		_request = new URLRequest();
		if ( !defaultTmpDir ) {
			defaultTmpDir = File.desktopDirectory.resolvePath( "fcall_tmp" );
		}
		if ( !defaultDownloadDir ) {
			defaultDownloadDir = File.desktopDirectory.resolvePath( "fcall_complete" );
		}
	}

	public function setup( url:String, fileOrDir:File ):void {

		if ( !_ba ) _ba = new ByteArray();
		if ( !_loader ) _loader = new URLStream();
		if ( !_fileStream ) _fileStream = new FileStream();

		// lazy initialization (required after calling dispose()).
		if ( !_loader ) {
			_loader = new URLStream();
			_request = new URLRequest();
		}

		addEvents( true );
		_percent = 0;
		_cleaned = false;
		_request.method = "GET";
		_request.url = url;
		setFile( fileOrDir );
	}

	public function load():void {
		_bytesTotal = _bytesPreloaded = _bytesLoaded = 0;
		if ( _override ) {
			FileUtils.deleteFile( file );
		} else if ( file.exists ) {
			log_error( "file " + file.url + " already exists" );
			cancel();
			return;
		}
		var cachedUrl:String = getCache();
		if ( allowResume ) {
			// save path between remote URL, and tmpFile.
			if ( !cachedUrl ) {
				saveCache();
			} else {
				// change tmp path.
				tmpFile.url = cachedUrl;
				if ( tmpFile.exists ) {
					var bytes:uint = tmpFile.size;// cached.numBytes ;
					log( "::load() cached to file:", cachedUrl, "bytes:", bytes );
					headerCache.value = "bytes=" + bytes + "-";
					_bytesPreloaded = _bytesLoaded = bytes;
					_request.requestHeaders.push( headerCache );
				}
			}
		} else {
			// remove cache and tmpFile.
			if ( cachedUrl ) {
				tmpFile.url = cachedUrl;
				removeFromCache();
			}
			FileUtils.deleteFile( tmpFile );
		}
		_deltaTime = getTimer();
		_requesting = true;

		if ( verbose ) {
			var _l:String = "::load() " + _request.url + "\nto=" + file.nativePath + "\ntmp=" + tmpFile.nativePath;
			_l += "\nusing cache=" + allowResume;
			if ( allowResume && tmpFile.exists ) {
				_l += " - cached bytes=" + getFilesize( tmpFile );
			}
			log( _l );
		}

		_loader.load( _request );
	}

	private function setFile( fileOrDir:File ):void {
		// define tmpFile and file.
		var tmp_filename:String = urlFilename;
		var filename:String;
		if ( fileOrDir ) {
			if ( fileOrDir.isDirectory || fileOrDir.extension == null ) {
				filename = tmp_filename;
				file = fileOrDir.resolvePath( filename );
			} else {
				filename = fileOrDir.name;
				file = fileOrDir;
			}
			tmpFile = defaultTmpDir.resolvePath( filename );
		} else {
			filename = tmp_filename;
			tmpFile = defaultTmpDir.resolvePath( filename );
			file = defaultDownloadDir.resolvePath( filename );
		}
	}

	public function cancel( dispatch:Boolean = true ):void {
		if ( !_requesting && _percent == 1 ) {
			return;
		}
		if ( _deleteTmpFileOnCancelError ) {
			FileUtils.deleteFile( tmpFile );
		}
		if ( dispatch ) {
			setSignal( CANCEL );
			if ( _onStatus ) _onStatus.dispatch( _status );
		}
		reset();
	}

	private function handleLoaderComplete( event:Event ):void {
		writeToDisk();
		if ( tmpFile.exists ) {
			tmpFile.moveTo( file, true );
		}
//		log( "::handleLoaderComplete(){0}path = {1}{0}size={2}", file.nativePath + " - size=" + getFilesize( file ) );
		log( "::handleLoaderComplete(){0}path = {1}{0}size={2}", "\n\t", file.nativePath, getFilesize( file ) );
		_requesting = false;
		_percent = 1;
		dispatchSignal( COMPLETE, file, event );
		removeFromCache();
		reset();
	}

	private function handleLoaderStatus( event:HTTPStatusEvent ):void {
		statusHeaders = event.responseHeaders;
		statusCode = event.status;
		statusUrl = event.responseURL;
		statusRedirected = event.redirected;

		var contentLength:String = getStatusHeaderValue( "Content-Length", statusHeaders );
		if ( contentLength ) {
			_contentLength = int( contentLength );
		} else {
			_contentLength = 0;
		}

		dispatchSignal( STATUS, statusCode, event );

		// TODO CRITICAL: validate content-type header cause sometimes it returns html text instead of the actual file!!!!
		if ( verbose ) {
			log( "::httpStatus(){0}statusCode = {1}{0}url = {2}{0}contentLength = {3}{0}headers = {4}",
					"\n\t",
					statusCode,
					event.responseURL,
					readeableSize( _contentLength ),
					JSON.stringify( event.responseHeaders ) );
		}
	}


	private var saveSize:Number = 1048576;

	private function handleLoaderProgress( event:ProgressEvent ):void {
		if ( !writeFileOnComplete || _loader.bytesAvailable > saveSize ) {
			_bytesPreloaded = _loader.bytesAvailable;
			writeToDisk();
		} else {
			_bytesLoaded = _bytesPreloaded + _loader.bytesAvailable;
		}
		_bytesTotal = event.bytesTotal;
		_percent = event.bytesLoaded / _bytesTotal;
		if ( _bytesPreloaded > 0 ) {
			_percentTotal = _bytesLoaded / ( event.bytesTotal + _bytesPreloaded );
		} else {
			_percentTotal = _percent;
		}
		if ( verbose ) {


			log( "::downloadProgress(){0}filename = {1}{0}downloaded = {2} % ( {3}% ){0}bytesLoaded = {4}",
					"\n\t",
					file.name,
					( _percent * 100 ).toFixed( 2 ),
					( _percentTotal * 100 ).toFixed( 2 ),
					_bytesLoaded );
			/*var _l:String = "::progress() " + file.name + ' %' + ( _percent * 100 ).toFixed( 2 );
			 if ( _bytesPreloaded > 0 ) {
			 _l += ' - total %' + ( _percentTotal * 100 ).toFixed( 2 );
			 }
			 //			_l += ' size=' + readSize( tmpFile );
			 _l += ' size=' + readeableSize( _bytesLoaded );
			 log( _l );*/
		}
		dispatchSignal( PROGRESS, _percent, event );
	}

	private function handleLoaderError( event:Event ):void { // IOErrorEvent, SecurityErrorEvent
		var msg:String;
		if ( event.hasOwnProperty( "errorID" ) ) {
			msg = event["errorID"] + " ";
		}
		if ( event.hasOwnProperty( "text" ) ) {
			msg += event["text"];
		}
		if ( !msg ) {
			msg = event.toString();
		}
		log_error( msg );
		dispatchSignal( ERROR, msg, event );
		// evaluate error action.
		if ( _deleteTmpFileOnCancelError ) {
			FileUtils.deleteFile( tmpFile );
		}

		reset();
	}


	private var _pausedUrl:String;

	public function pause():void {
		if ( _pausedUrl ) return;
		// save url and state.
		if ( !_requesting && _percent == 1 ) return;
		_pausedUrl = _request.url;
		_loader.close();
		_requesting = false;
	}

	public function resume():void {
		if ( !_pausedUrl ) return;
		if ( _pausedUrl && !_requesting ) {
			var bytes:uint = tmpFile.size;// cached.numBytes ;
			log( "::load() cached to file:", _pausedUrl, "bytes:", bytes );
			headerCache.value = "bytes=" + bytes + "-";
			_bytesPreloaded = _bytesLoaded = bytes;
			_request.requestHeaders.length = 0;
			_request.requestHeaders.push( headerCache );
			_deltaTime = getTimer();
			_requesting = true;
			_loader.load( _request );
		}
		_pausedUrl = null;
	}

	public function get isPaused():Boolean {
		return !_requesting && _pausedUrl != null;
	}

	//===================================================================================================================================================
	//
	//      ------  io stuffs
	//
	//===================================================================================================================================================

	private function writeToDisk():void {
		if ( _loader.bytesAvailable == 0 )
			return;

		_bytesLoaded += _loader.bytesAvailable;
		_ba.clear();
		_loader.readBytes( _ba );
		_fileStream.open( tmpFile, FileMode.APPEND );
		_fileStream.writeBytes( _ba );
		_fileStream.close();
	}

	//===================================================================================================================================================
	//
	//      ------  app.utils
	//
	//===================================================================================================================================================

	private function get urlFilename():String {
		// Safe filename... remove url chars, etc.
		return FileUtils.getFilename( _request.url );
	}

	private function addEvents( flag:Boolean ):void {
		if ( _loader.hasEventListener( Event.COMPLETE ) == flag ) return;
		var method:String = flag ? "addEventListener" : "removeEventListener";
		_loader[method]( IOErrorEvent.IO_ERROR, handleLoaderError );
		_loader[method]( SecurityErrorEvent.SECURITY_ERROR, handleLoaderError );
		_loader[method]( ProgressEvent.PROGRESS, handleLoaderProgress );
		_loader[method]( HTTPStatusEvent.HTTP_RESPONSE_STATUS, handleLoaderStatus );
		_loader[method]( Event.COMPLETE, handleLoaderComplete );
	}


	private function setSignal( type:String, data:* = null, event:* = null ):void {
		_status.type = type;
		_status.isCancel = type == CANCEL;
		_status.isProgress = type == PROGRESS;
		_status.isComplete = type == COMPLETE;
		_status.isError = type == ERROR;
		_status.isStatus = type == STATUS;
		_status.data = data;
		_status.event = event;
	}

	public function dispatchSignal( type:String, data:*, event:* ):void {
		setSignal( type, data, event );
		if ( _onStatus ) _onStatus.dispatch( _status );
	}

	public function getStatusHeaderValue( name:String, headers:Array = null ):String {
		if ( !headers ) {
			headers = statusHeaders;
			if ( !headers ) return null;
		}
		var header:URLRequestHeader = URIUtils.getResponseHeaderByName( name, headers );
		if ( !header ) return null;
		return header.value;
	}

	//============================
	// LOGS --
	//============================

	private function log( ...args ):void {
		if ( !verbose ) return;
		var msg:String = args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ FileCall ] " + msg );
	}

	private function log_error( ...args ):void {
		var msg:String = args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ FileCall ] ERROR=" + msg );
		// call error!
	}

	//===================================================================================================================================================
	//
	//      ------  Access status headers utility
	//
	//===================================================================================================================================================
	public function get headerContentType():String {
		return getStatusHeaderValue( "Content-Type" );
	}

	public function get headerDate():String {
		return getStatusHeaderValue( "Date" );
	}

	public function get headerServer():String {
		return getStatusHeaderValue( "Server" );
	}

	public function get headerAcceptEncoding():String {
		return getStatusHeaderValue( "Accept-Encoding" );
	}

	public function get headerContentEncoding():String {
		return getStatusHeaderValue( "Content-Encoding" );
	}

	public function get headerContentLength():String {
		return getStatusHeaderValue( "Content-Length" );
	}

	public function getStatusHeaderContentType( headers:Array = null ):String {
		return getStatusHeaderValue( "Content-Type", headers );
	}


	//===================================================================================================================================================
	//
	//      ------  cache
	//
	//===================================================================================================================================================
	private function initCache():void {
		if ( !cacheMap && cache_get ) {
			cacheMap = cache_get( _cacheId );
			if ( !cacheMap ) {
				cacheMap = {};
				if ( cache_set != null )
					cache_set( _cacheId, cacheMap );
			}
		} else {
			if ( !cache_get ) {
				log_error( "Define a ::cache_get callback." );
			}
		}
	}

	public function removeFromCache():void {
		var url:String = _request.url;
		if ( cacheMap[url] ) {
			delete cacheMap[url];
			if ( cache_set != null )
				cache_set( _cacheId, cacheMap );
		}
	}

	private function getCache():String {
		return cacheMap[_request.url];
	}

	public function saveCache():void {
		cacheMap[_request.url] = tmpFile.url;
		cache_set( _cacheId, cacheMap );
	}

	public static function clearCache():void {
		cache_set( _cacheId, null );
	}

	//===================================================================================================================================================
	//
	//      ------  static
	//
	//===================================================================================================================================================
	public static function call( url:String, fileOrDir:File, statusCallback:Function, props:Object = null ):FileCall {
		var fcall:FileCall = setup( url, fileOrDir, statusCallback, props );
		fcall.load();
		return fcall;
	}

	public static function setup( url:String, fileOrDir:File, statusCallback:Function, props:Object = null ):FileCall {
		if ( !props )
			props = {method: "GET"};

		var fcall:FileCall = FileCall.get();
		fcall.setup( url, fileOrDir );
		fcall._request.cacheResponse = props.cacheResponse;
		fcall._request.useCache = props.useCache;
		if ( props.hasOwnProperty( "data" ) ) {
			fcall._request.data = props.data;
		}
		if ( props.hasOwnProperty( "contentType" ) ) {
			fcall._request.contentType = props.contentType;
		}
		if ( props.hasOwnProperty( "writeFileOnComplete" ) ) {
			fcall.writeFileOnComplete = props.writeFileOnComplete;
		}
		fcall._deleteTmpFileOnCancelError = props.deleteOnError;

		if ( props.hasOwnProperty( "allowResume" ) ) {
			fcall.allowResume = props.allowResume;
		}

		if ( props.hasOwnProperty( "headers" ) ) {
			if ( props.headers is URLRequestHeader ) {
				fcall._request.requestHeaders.push( props.headers );
			} else if ( props.headers is Array ) {
				fcall._request.requestHeaders = fcall._request.requestHeaders.concat( props.headers );
			}
		}

		if ( props.hasOwnProperty( "userData" ) ) {
			fcall.userData = props.userData;
		}

		fcall.verbose = props.hasOwnProperty( "verbose" ) ? props.verbose : FileCall.verbose;

		if ( statusCallback ) {
			fcall.onStatus.add( statusCallback );
		}
		return fcall;
	}

	public static function getFilesize( file:File ):String {
		if ( !file || !file.exists ) return "0 bytes";
		return FileUtils.redeableBytes( file.size )
	}

	public static function readeableSize( size:Number ):String {
		if ( isNaN( size ) || size <= 0 ) return "0 bytes";
		return FileUtils.redeableBytes( size )
	}

	public function get request():URLRequest {
		return _request;
	}

	public function get loader():URLStream {
		return _loader;
	}

	public function get percent():Number {
		return _percent;
	}

	public function get isDownloading():Boolean {
		return _status && _status.type == PROGRESS || _status.type == STATUS;
	}

	public function get redeableBytesLoaded():String {
		return FileUtils.redeableBytes( _bytesLoaded );
	}

	public function get redeableBytesTotal():String {
		return FileUtils.redeableBytes( _bytesTotal );
	}

	public function get contentLength():int {
		return _contentLength;
	}

	public function get bytesPreloaded():uint {
		return _bytesPreloaded;
	}

	public function get bytesLoaded():uint {
		return _bytesLoaded;
	}

	public function get bytesTotal():int {
		return _bytesTotal;
	}

	public function get onStatus():Callback {
		if ( !_onStatus ) _onStatus = new Callback( true );
		return _onStatus;
	}

	public static function get failure():Callback {
		if ( !_failure ) _failure = new Callback();
		return _failure;
	}
}
}
