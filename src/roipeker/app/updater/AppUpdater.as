/**
 *
 * Created by Rodrigo Lopez [blnk™] on 1/11/17.
 *
 */
package roipeker.app.updater {
import roipeker.callbacks.Callback;
import roipeker.helpers.AppHelper;
import roipeker.net.FileCall;
import roipeker.net.ServiceCall;
import roipeker.utils.FileUtils;
import roipeker.utils.StringUtils;

import com.greensock.TweenLite;

import flash.filesystem.File;

import starling.utils.StringUtil;

public class AppUpdater {

	public static const STATE_NOT_INITED:String = "notInitialized";
	public static const STATE_COMPLETE:String = "complete";
	public static const STATE_REQUESTING_JSON:String = "requestingJson";
	public static const STATE_DOWNLOADING:String = "download";
	public static const STATE_ERROR:String = "error";
	public static const STATE_UPDATE_STATUS:String = "updateStatus"; //(availalbe) or not
	public static const STATE_ALREADY_DOWNLOADED:String = "alreadyDownlaoded";

	public static const STATE_IDLE:String = "idle";

	public static const DOWNLOAD_START:String = "downloadStart";
	public static const DOWNLOAD_PROGRESS:String = "downloadProgress";
	public static const DOWNLOAD_COMPLETE:String = "downloadComplete";
	public static const DOWNLOAD_ERROR:String = "downloadError";

	private static var _instance:AppUpdater;

	public static function get instance():AppUpdater {
		if ( !_instance ) _instance = new AppUpdater();
		return _instance;
	}

	public var updaterURL:String ;
	public var downloadFolder:File ;

	// Check for updates each 5 mins by default.
	public var checkInterval:int = 300 ;

	public var onUpdateStatus:Callback;
	public var onDownloadStatus:Callback;

	private var _updateState:String; // -1=non initialized,0=requesting xml, 1=download, 2=complete, 3=error.
	public var verbose:Boolean = true;
	private var _osKey:String;

	public var downloadURL:String;
	public var versionURL:String;
	public var commentsURL:String;
	public var hasUpdate:Boolean;

	public var autoUpdate:Boolean = false;
	public var requestingVersion:Boolean;
	public var downloadingBuild:Boolean;

	private var _installerFile:File;
	private var _downloadInfo:Object = {};
	public static var verbose:Boolean;
	private var _fc:FileCall;

	public function AppUpdater() {
		onUpdateStatus = new Callback();
		onDownloadStatus = new Callback();
		if ( AppHelper.isWin ) _osKey = "win";
		else if ( AppHelper.isMac ) _osKey = "osx";
		else if ( AppHelper.isIOS ) _osKey = "ios";
	}

	public function checkForkUpdates():void {
		if ( hasUpdate ) return;
		if( !updaterURL ){
			throw new Error("updateUrl must be defined.");
		}
		requestingVersion = true;
		log( "requesting update json" );
		setState( STATE_REQUESTING_JSON );
		ServiceCall.call( updaterURL, onUpdaterResult );
	}

	private function setState( state:String ):void {
		_updateState = state;
		onUpdateStatus.dispatch( state );
	}

	private function onUpdaterResult( info:Object ):void {
		if ( info.isComplete ) {
			requestingVersion = false;
//			log( 'update json result=' + info.data );
			var json:Object = JSON.parse( info.data );
			if ( !json[_osKey] ) {
				error( "onUpdaterResult() OS key inexistent = " + _osKey );
				return;
			}
			downloadURL = json[_osKey].url;
			versionURL = json[_osKey].build;
			commentsURL = json[_osKey].comments;
			log( "downloadUrl = {0}\n\tversionUrl = {1}", downloadURL, versionURL );
			// validate if we have the same version.
			if ( AppHelper.appVersion == versionURL ) {
				upToDate();
			} else {
				// compare values.
				var localVersion:Number = getBuildValue( AppHelper.appVersion );
				var remoteVersion:Number = getBuildValue( versionURL );
				if ( isNaN( localVersion ) || isNaN( remoteVersion ) ) {
					error( "Wrong values for updater.json, needs to follow format: xx.xx.xx" );
					localVersion = 1; // force OLDER version.
					remoteVersion = 0;
				}
				hasUpdate = remoteVersion > localVersion;
				log( "build version local = {0}\n\tremote = {1}\n\thas updates ={2} ", localVersion, remoteVersion, hasUpdate );
				// TODO: validate if update build already exists ?
			}
			// if it was just updated... remove the installers folder.
			if ( !hasUpdate ) {
//				trace("delete download folder:", downloadFolder.nativePath );
//				FileUtils.deleteDirContents( downloadFolder );
			}
			setState( STATE_UPDATE_STATUS );
			if ( autoUpdate ) {
				download();
			}
		} else if ( info.isError ) {
			error( info.data );
			setState( STATE_ERROR );
			// retry?
		}
	}

	private function upToDate():void {
		log( "all up to date." );
		hasUpdate = false;
	}

	public var runningMonitor:Boolean = false;

	public function startMonitor():void {
		runningMonitor = true;
		onCheckInterval();
	}

	public function stopMonitor():void {
		runningMonitor = false;
		TweenLite.killDelayedCallsTo( onCheckInterval );
	}

	private function onCheckInterval():void {
		if ( !hasUpdate ) {
			// waiting for confirmation.
			checkForkUpdates();
		}
		TweenLite.delayedCall( checkInterval, onCheckInterval );
	}


	public function download():void {
		// check if file is download already.
		var buildFilename:String = FileUtils.getFilename( downloadURL );
		if( !downloadFolder ){
			downloadFolder = File.applicationStorageDirectory.resolvePath( "builds" );
		}
		_installerFile = downloadFolder.resolvePath( buildFilename );
		log( "installer file = ", _installerFile.nativePath );
		if ( _installerFile.exists ) {
			log( "Build already downloaded" );
			setState( STATE_ALREADY_DOWNLOADED );
//			onUpdateStatus.dispatch( "alreadyDownloaded" );
			return;
		}
		downloadingBuild = true;
		log( "download() urlpath = '{0}'\n\tfilename = '{1}'", downloadURL, buildFilename );
		setState( STATE_DOWNLOADING );
//		_updateState = _statusInfo.status = DOWNLOAD_START;
//		onDownloadStatus.dispatch( _statusInfo );

		// return to pool
		if ( _fc ) {
			_fc.reset();
			_fc = null
		}
		_fc = FileCall.call( downloadURL, downloadFolder, handleDownloadStatus, {
			allowResume: false,
			writeFileOnComplete: true
		} );
		_fc.verbose = true;
		downloadStatus( DOWNLOAD_START, 0 );
	}

	private function downloadStatus( status:String, percent:Number ):void {
		if ( !status == DOWNLOAD_ERROR ) {
			_downloadInfo.msg = "";
		}
		_downloadInfo.isComplete = status == DOWNLOAD_COMPLETE;
		_downloadInfo.isError = status == DOWNLOAD_ERROR;
		_downloadInfo.isProgress = status == DOWNLOAD_PROGRESS;
		_downloadInfo.isStart = status == DOWNLOAD_START;
		_downloadInfo.status = status;
		_downloadInfo.percent = percent;
		_downloadInfo.loadedBytesString = _fc ? _fc.redeableBytesLoaded : "0";
		_downloadInfo.totalBytesString = _fc ? _fc.redeableBytesTotal : "0";
		onDownloadStatus.dispatch( _downloadInfo );
	}

	public function pause():void {
		if ( _fc ) {
			_fc.pause();
		}
	}

	public function resume():void {
		if ( _fc ) {
			_fc.resume();
		}
	}

	private function handleDownloadStatus( info:Object ):void {
		if ( info.isProgress ) {
			downloadStatus( DOWNLOAD_PROGRESS, info.data );
//			log( "handleDownloadStatus() percent= {0}% - downloaded {1} / {2}", (_downloadInfo.percent * 100).toFixed( 2 ), _downloadInfo.loadedBytesString, _downloadInfo.totalBytesString );
		} else if ( info.isComplete ) {
			_installerFile = _fc.file;
			downloadStatus( DOWNLOAD_COMPLETE, 1 );
			setState( STATE_ALREADY_DOWNLOADED );
			log( 'New build downloaded!' );
			if ( autoUpdate ) {
				installBuild();
			}
			_fc = null;
		} else if ( info.isError ) {
			_downloadInfo.msg = info.data;
			downloadStatus( DOWNLOAD_ERROR, 0 );
			_fc = null;
		}
	}

	public function installBuild():void {
		// kill app and open the installer.
		log( "Opening installer = " + _installerFile.url );
		_installerFile.openWithDefaultApplication();
		AppHelper.exitApp();
	}

	private function getBuildValue( build:String ):Number {
		var arr:Array = build.split( "." );
		for ( var i:int = 0; i < arr.length; i++ ) {
			// max 3 values.
			if ( arr[i].length > 3 ) arr[i] = arr[i].substr( 0, 3 );
			arr[i] = StringUtils.zeroPad( arr[i], 3 );
		}
		var str:String = arr.join( "" );
		return Number( str );
	}


	private static function log( ...args ):void {
		if ( !verbose ) return;
		var msg:String = ( args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ) ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ AppUpdater ] " + msg );
	}

	private static function error( ...args ):void {
		var msg:String = ( args[0] is String && String( args[0] ).indexOf( "{" ) > -1 ) ? StringUtils.format.apply( null, args ) : String( args );
		trace( "[ AppUpdater ] ERROR =" + msg );
	}

	public function get updateState():String {
		return _updateState;
	}
}
}
