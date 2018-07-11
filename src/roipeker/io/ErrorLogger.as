/**
 * Code by Rodrigo López Peker on 12/10/15 11:15 AM.
 *
 * STATIC CLASS
 *
 * set logFile and call ErrorLogger.init()
 */
package roipeker.io {

import roipeker.helpers.AppHelper;

import flash.display.LoaderInfo;
import flash.events.UncaughtErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.getTimer;

public class ErrorLogger {

	public static var ERROR_LOG_SEPARATION:String = "----------------------------------";

	private static var _fs:FileStream = new FileStream();
	private static var _logInitTime:Number;
	private static var _logDateTime:Number;
	private static var _logDate:Date;
	private static var monthYear:String;

	public static var logFolder:File = null;
	private static var logFile:File = null;
	private static var NEW_LINE1:String = "\n";
	private static var NEW_LINE:String = "\n\n";

	// 10mb for option 2
	private static const MAX_LOG_FILESIZE:Number = 10 * 1000 * 1000;

	private static var isWin:Boolean;

	public function ErrorLogger() {}

	public static function init( loader:LoaderInfo, logFolder:File = null ):void {
		ErrorLogger.logFolder = logFolder;
		if ( !ErrorLogger.logFolder ) ErrorLogger.logFolder = File.applicationStorageDirectory.resolvePath( "logs" )
		isWin = AppHelper.isWin;
		if ( isWin ) {
			NEW_LINE1 = File.lineEnding;
			NEW_LINE = File.lineEnding + File.lineEnding;// \r\r
		}
		loader.uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtError );
	}

	private static function handleUncaughtError( event:UncaughtErrorEvent ):void {
		event.preventDefault();
		event.stopImmediatePropagation();
		var msg:String = "[ uncaught ] ";
		if ( event.error is Error ) {
			log( msg + event.error.name + event.error.getStackTrace() );
		} else {
			log( msg + " text = " + event.error.toString() );
		}
	}

	public static function log( ...args ):void {
		if ( !_logDate ) {
			createLogFile();
		}
		// flush to disk
		var str:String = args.join( NEW_LINE1 );
		if ( isWin ) str = str.split( "\t" ).join( NEW_LINE1 + "\t" );

		var msg:String = getCurrentTime() + str + NEW_LINE + ERROR_LOG_SEPARATION + NEW_LINE;
		trace( "[ ErrorLogger ] ERROR = " + msg );
		if ( logFile ) {
			_fs.open( logFile, FileMode.APPEND );
			_fs.writeUTFBytes( msg );
			_fs.close();
		}
	}

	private static function createLogFile():void {
		_logDate = new Date();
		_logDateTime = _logDate.time;
		_logInitTime = getTimer();
		monthYear = formatZero( _logDate.getMonth() + 1 ) + "-" + _logDate.getFullYear().toString().substr( 2 );

		// -- option1:
		// Delete log file if it exceeds the max size.
		/*if( logFile && logFile.exists && logFile.size > MAX_LOG_FILESIZE ) {
		 FileUtils.deleteFile( logFile );
		 }*/

		// -- option 2:
		// Dynamic logfile, filename based on the date.
		var filename:String = "log_" + formatZero( _logDate.getDate() ) + "-" + monthYear + ".txt";
		if ( logFolder ) {
			if ( !logFolder.exists ) logFolder.createDirectory();
			logFile = logFolder.resolvePath( filename );
		}
	}

	private static function getCurrentTime():String {
		var ct:Number = _logDateTime + ( getTimer() - _logInitTime );
		_logDate.setTime( ct );
		return formatZero( _logDate.getDate() ) + "-" + monthYear + " "
				+ formatZero( _logDate.getHours() )
				+ ":"
				+ formatZero( _logDate.getMinutes() )
				+ ":"
				+ formatZero( _logDate.getSeconds() )
				+ "."
				+ formatZero( _logDate.getMilliseconds() ) + " :: ";
	}

	[Inline]
	private static function formatZero( timeValue:Number ):String {
		return timeValue > 9 ? timeValue.toString() : "0" + timeValue.toString();
	}
}
}
