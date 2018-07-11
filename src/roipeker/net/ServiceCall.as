/**
 * Code by Rodrigo López Peker on 2/11/16 10:46 AM.
 *
 */
package roipeker.net {

//import blnk.air.FileUtils;
import roipeker.callbacks.Callback;
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
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.utils.ByteArray;
import flash.utils.getTimer;


/**
 * Class to deal with any cURL request :)
 * Sample:

 ServiceCall.call( "http://www.google.com", null, {method:"GET", verbose:true});
 //ServiceCall.call( "http://www.google.com", ServiceCall.onSuccessDebugCallback, {method:"GET", verbose:true});
 */
public class ServiceCall {

	private static var _pool:Pooler;

	/**
	 * Used to get a ServiceCall instance from the pool
	 * @return
	 */
	public static function get():ServiceCall {
		if ( !_pool ) _pool = Pooler.build( ServiceCall, null, null, "dispose" );
		var call:ServiceCall = _pool.get() as ServiceCall;
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
		// clear the queue.
		delete _currentRequestsMap[_request.url];
//		setSignal( null, null, null );
		_status = {target: this};
		_cleaned = true;
		if( _onStatus ) _onStatus.removeAll();
		userData = null;
		if ( _requesting ) {
			// try catch() if there's no current request, but impossible cause this class
			// deals with that, and is not exposed
			_loader.close();
		}
		uid = -1;
		_requesting = false;
		_request.contentType = null;
		_request.method = URLRequestMethod.GET;
		_request.data = null;
		_request.requestHeaders = [];
		_loader.dataFormat = URLLoaderDataFormat.TEXT;

		debugFile = null;
		statusHeaders = null;
		statusCode = 0;
		statusRedirected = false;
		statusUrl = null;
		verbose = false;
		userData = null;
	}

	public function dispose():void {
		if ( !_cleaned ) {
			reset();
		}
		if ( !_loader ) return;
		_loader.removeEventListener( Event.COMPLETE, handleLoaderComplete );
		_loader.removeEventListener( IOErrorEvent.IO_ERROR, handleLoaderError );
		_loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, handleLoaderError );
		_loader.removeEventListener( HTTPStatusEvent.HTTP_RESPONSE_STATUS, handleLoaderResponseStatus );
		_loader.removeEventListener( ProgressEvent.PROGRESS, handleLoaderProgress );
		_loader = null;
		_request = null;
	}

	public static const PROGRESS:String = "downloadProgress";
	public static const COMPLETE:String = "complete";
	public static const CANCEL:String = "cancel";
	public static const ERROR:String = "error";
	public static const STATUS:String = "status";

	public static const GET:String = "GET";
	public static const POST:String = "POST";
	public static const UPDATE:String = "UPDATE";
	public static const PUT:String = "PUT";
	public static const DELETE:String = "DELETE";
	public static const DEL:String = "DEL";

	private var _onStatus:Callback;

	// every code > ::failureMinimumStatusCode is considered as failure.
	public static var failureMinimumStatusCode:int = 400;

	private static var _failure:Callback;

	// cleaned define the state of the ServiceCall instance, if its "clean" means it's reset() to the default state, and can be used with
	// the default setup.
	private var _cleaned:Boolean;
	private var _request:URLRequest;
	private var _loader:URLLoader;

	private var _requesting:Boolean;

	public static var verbose:Boolean = false;

	// for this specific instance, default to false.
	public var verbose:Boolean;

	// stores any information here.
	public var userData:Object;

	// unique id for this call.
	public var uid:uint;

	// to debugHitQuad the text output to a File on the system :)
	public var debugFile:File;


	// to track time spent on request.
	private var _deltaTime:uint;

	// signal object used as Event data.
	// target: this object
	// type: event type (CANCEL,ERROR,STATUS,COMPLETE,PROGRESS)
	// data: data per event type ( _loader.data, error text, status code (int) )
	// event: the native event dispatched by the URLLoader
	private var _status:Object;

	// StatusEvent response headers and other info.
	public var statusHeaders:Array;
	public var statusCode:uint;
	public var statusUrl:String;
	public var statusRedirected:Boolean;

	private static var uniqueId:int = 1;

	// stores the URL as reference for requests (if we wanna avoid calling the same URL while is being processed).
	private static var _currentRequestsMap:Object = {};

	/**
	 * Constructor.
	 */
	public function ServiceCall() {
		_cleaned = true;
		_status = {target: this};
		_request = new URLRequest();
		_loader = new URLLoader();
	}

	public function setup( url:String, method:String = "GET", contentType:String = "" ):void {
		// lazy initialization (required after calling dispose()).
		if ( !_loader ) {
			_loader = new URLLoader();
			_request = new URLRequest();
		}

		uid = ++uniqueId;

		// if required we can set contentType=NULL to send empty ones, default to applicaton/json.
		if ( contentType == "" ) {
			contentType = "application/json";
		}
		method = validateURLRequestMethod( method );
		_cleaned = false;
		_request.url = url;
		_request.contentType = contentType;
		_request.method = method;
		_request.useCache = true;
		// add loader listeners if needed.
		if ( !_loader.hasEventListener( Event.COMPLETE ) ) {
			_loader.addEventListener( Event.COMPLETE, handleLoaderComplete );
			_loader.addEventListener( IOErrorEvent.IO_ERROR, handleLoaderError );
			_loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, handleLoaderError );
			_loader.addEventListener( HTTPStatusEvent.HTTP_RESPONSE_STATUS, handleLoaderResponseStatus );
			_loader.addEventListener( ProgressEvent.PROGRESS, handleLoaderProgress );
		}
	}

	public function load():void {
		_deltaTime = getTimer();
		_requesting = true;
		log( "\n\tload = {1}\n\theaders = {1}",_request.url, JSON.stringify( request.requestHeaders ) );
		_loader.load( _request );
	}

	public function cancel( dispatch:Boolean = true ):void {
		if ( dispatch ) {
			setSignal( CANCEL );
			if ( _onStatus ) _onStatus.dispatch( _status );
		}
		reset();
	}


	//===================================================================================================================================================
	//
	//      ------  EVENTS
	//
	//==================================================================================================================================================

	private function handleLoaderComplete( event:Event ):void {
		// we may need the result as BYTES, as it happens with some website that are not properly encoded in other charsets!
		var result:* = _loader.data;
		if( !_onStatus || ( _onStatus && !_onStatus.has(onSuccessDebugCallback))){
			log( "{0}time = {1}{0}url = {2} [{3}]{0}data = {4}",
					"\n\t",
					currentRequestTimeText,
					request.url,
					request.method,
					result );
		}

		_requesting = false;
		if ( debugFile ) {
			writeDebugFile( debugFile, result );
		}
		dispatchSignal( COMPLETE, result, event );
		reset();
	}

	// Download processed.
	private function handleLoaderProgress( event:ProgressEvent ):void {
		// TODO: maybe we wanna avoid this one?
		dispatchSignal( PROGRESS, {bytes: event.bytesLoaded, percentage: event.bytesLoaded / event.bytesTotal}, event );
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
		reset();
	}

	private function handleLoaderResponseStatus( event:HTTPStatusEvent ):void {
		statusHeaders = event.responseHeaders;
		statusCode = event.status;
		statusUrl = event.responseURL;
		statusRedirected = event.redirected;

		dispatchSignal( STATUS, statusCode, event );

		if ( verbose ) {
//			log( "\n\tload = {0}\n\theaders = {1}", _request.url, JSON.stringify( request.requestHeaders ) );
			log( ":: httpStatus(){0}time = {1}{0}statusCode = {2}{0}url = {3}{0}headers = {4}", "\n\t", currentRequestTimeText, statusCode, event.responseURL, JSON.stringify( event.responseHeaders ) );
		}

		// we dont wanna reset() by default, cause usually we get an error description.
		if ( statusCode >= failureMinimumStatusCode ) {
			if ( _failure ) _failure.dispatch( event );
			// optionally reset?
		}
	}


	//===================================================================================================================================================
	//
	//      ------  ACCESSORS
	//
	//===================================================================================================================================================
	public function get request():URLRequest {
		return _request;
	}

	// I don't wanna expose this one, but MAYBE can be useful.
	public function get loader():URLLoader {
		return _loader;
	}

	public function get currentRequestTime():uint {
		return getTimer() - _deltaTime;
	}

	public function get currentRequestTimeText():String {
		var responseTime:Number = ( getTimer() - _deltaTime ) / 1000;
		return responseTime + "s";
	}

	//===================================================================================================================================================
	//
	//      ------  app.utils
	//
	//===================================================================================================================================================

	private function setSignal( type:String, data:* = null, event:* = null ):void {
		_status.type = type;
		_status.isCancel = type == CANCEL;
		_status.isProgress = type == PROGRESS;
		_status.isComplete = type == COMPLETE;
		_status.isStatus = type == STATUS;
		_status.isError = type == ERROR;
		_status.data = data;
		_status.event = event;
	}

	public function dispatchSignal( type:String, data:*, event:* ):void {
		setSignal( type, data, event );
		if ( _onStatus ) _onStatus.dispatch( _status );
	}

	/**
	 * useful to search for a status header.
	 * @param name
	 * @param headers
	 * @return
	 */
	public function getStatusHeaderValue( name:String, headers:Array = null ):String {
		if ( !headers ) headers = statusHeaders;
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
		trace( "[ ServiceCall ] " + msg );
	}

	private function log_error( ...args ):void {
		var msg:String = args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ ServiceCall ] ERROR=" + msg );
		// call error!
	}

	//===================================================================================================================================================
	//
	//      ------  STATIC functions
	//
	//===================================================================================================================================================

	/**
	 * Used as shortcut to make a call.
	 * @param url
	 * @param statusCallback
	 * @param props
	 * @return
	 */
	public static function call( url:String, statusCallback:Function, props:Object = null ):ServiceCall {
		var scall:ServiceCall = setup( url, statusCallback, props );
		scall.load();
		return scall;
	}

	public static function setup( url:String, statusCallback:Function, props:Object = null ):ServiceCall {
		if ( !props ) props = {method: GET};

		var scall:ServiceCall = ServiceCall.get();
		scall.setup( url, props.method || GET );

		_currentRequestsMap[url] = scall;
		if ( props.hasOwnProperty( "data" ) ) {
			scall._request.data = props.data;
		}
		if ( props.debugFile && props.debugFile is File ) {
			scall.debugFile = props.debugFile;
		}

		if ( props.hasOwnProperty( "contentType" ) ) {
			scall._request.contentType = props.contentType;
		}
		if ( props.hasOwnProperty( "dataFormat" ) ) {
			scall._loader.dataFormat = props.dataFormat;
		}
		if ( props.hasOwnProperty( "headers" ) ) {
			if ( props.headers is URLRequestHeader ) {
				scall._request.requestHeaders.push( props.headers );
			} else if ( props.headers is Array ) {
				scall._request.requestHeaders = scall._request.requestHeaders.concat( props.headers );
			}
		}
		if ( props.hasOwnProperty( "userData" ) ) {
			scall.userData = props.userData;
		}

		scall.verbose = props.hasOwnProperty( "verbose" ) ? props.verbose : ServiceCall.verbose;

		if ( statusCallback ) {
			scall.onStatus.add( statusCallback );
		}
		return scall;
	}


	public static function validateURLRequestMethod( m:String ):String {
		if ( !m ) return GET;
		m = m.toUpperCase();
		return [GET, PUT, POST, DELETE, DEL, UPDATE].indexOf( m ) > -1 ? m : GET;
	}

	/**
	 * Useful for debugging.
	 * @param status
	 */
	public static function onSuccessDebugCallback( status:Object ):void {
		if ( status.isComplete ) {
			var o:ServiceCall = status.target as ServiceCall;
			o.log( "{0}time = {1}{0}url = {2} [{3}]{0}data = {4}",
					"\n\t",
					o.currentRequestTimeText,
					o.request.url,
					o.request.method,
					status.data );
		}
	}

	private static var _ba:ByteArray;
	// awesome utility to output the result directly to the filesystem.
	// useful when the output is too long for the console.
	private static function writeDebugFile( file:File, text:String ):void {
		if ( !file ) {
			trace( "[ ServiceCall ] ERROR ::writeDebugFile() $file is required" );
			return;
		}
		if ( !_ba ) {
			_ba = new ByteArray();
		} else {
			_ba.clear();
		}
		_ba.writeUTFBytes( text );
		var fs:FileStream = new FileStream();
		fs.open( file, FileMode.WRITE );
		fs.writeBytes( _ba );
		fs.close();
		fs = null;
	}

	/**
	 * Checks if another request to the same URL is currently being processed
	 * @param    url
	 * @return    Boolean if the request is being processed
	 */
	public static function isRequesting( url:String ):Boolean {
		return _currentRequestsMap[url] != null;
	}

	/**
	 * Gets the current ServiceCall instance running for a specified url (if any)
	 * @param    url
	 * @return    ServiceCall instance for that specific url
	 */
	public static function getRequestingCallByUrl( url:String ):ServiceCall {
		return _currentRequestsMap[url] as ServiceCall;
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
