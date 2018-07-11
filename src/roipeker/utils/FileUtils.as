/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/17/17.
 *
 */
package roipeker.utils {
import by.blooddy.crypto.image.JPEGEncoder;
import by.blooddy.crypto.image.PNGEncoder;

import flash.display.BitmapData;

import flash.display.JPEGEncoderOptions;

import flash.display.Loader;
import flash.display.PNGEncoderOptions;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

public class FileUtils {

	private static const READEABLE_BYTES_HASH:Array = ['bytes', 'kb', 'MB', 'GB', 'TB', 'PB'];
	private static const TMP_FILE:File = new File();

	public static function read( file:File, bytes:ByteArray = null ):ByteArray {
		var stream:FileStream = new FileStream();
		stream.open( file, FileMode.READ );
		if ( !bytes ) bytes = new ByteArray();
		bytes.clear();
		stream.readBytes( bytes );
		stream.close();
		return bytes;
	}

	public static function writeJSON( file:File, json:Object ):void {
		saveStringToFile(file, JSON.stringify(json));
	}

	public static function readJSON( file:File ):* {
		var str:String = readString( file );
		if ( !str ) return null;
		try {
			var json:Object = JSON.parse( str );
		} catch ( e:Error ) {
			return null;
		}
		return json ;
	}

	public static function readString( file:File ):String {
		if ( !file || !file.exists ) return null;
		var ba:ByteArray = read( file );
		return ba.readUTFBytes( ba.bytesAvailable );
	}


	public static function saveStringToFile( file:File, text:String, fallbackFilename:String = '' ):File {
		if ( !file ) {
			if ( !fallbackFilename ) {
				file = File.createTempFile();
			} else {
				file = File.desktopDirectory.resolvePath( fallbackFilename );
			}
		}
		var ba:ByteArray = new ByteArray();
		ba.writeUTFBytes( text );
		var fileStream:FileStream = new FileStream();
		fileStream.open( file, FileMode.WRITE );
		fileStream.writeBytes( ba );
		fileStream.close();
		return file;
	}

	//============================
	// IMAGES --
	//============================
	public static function saveJPG( bd:BitmapData, fileOrUrl:Object, quality:uint = 80 ):void {
		TMP_FILE.url = (fileOrUrl is String) ? String( fileOrUrl ) : File( fileOrUrl ).url ;
		var ba:ByteArray = new ByteArray();
		bd.encode( bd.rect, new JPEGEncoderOptions( quality ), ba );
		var fs:FileStream = new FileStream();
		fs.open( TMP_FILE, FileMode.WRITE );
		fs.writeBytes( ba );
		fs.close();
		ba.clear();
		ba = null;
		fs = null;
	}

	public static function savePNG( bd:BitmapData, fileOrUrl:Object, fastCompression:Boolean = false ):void {
		TMP_FILE.url = (fileOrUrl is String) ? String( fileOrUrl ) : File( fileOrUrl ).url ;
		var ba:ByteArray = new ByteArray();
		bd.encode( bd.rect, new PNGEncoderOptions( fastCompression ), ba );
		var fs:FileStream = new FileStream();
		fs.open( TMP_FILE, FileMode.WRITE );
		fs.writeBytes( ba );
		fs.close();
		ba.clear();
		ba = null;
		fs = null;
	}

	public static function readLoaderContent( file:File, callback:Function, ba:ByteArray ):void {
		if( !ba ) ba =new ByteArray();
		read(file, ba);
		var loader:Loader = new Loader() ;
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onFileLoaded );
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFileError );
		loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileError );
		loader.loadBytes( ba );

		function onFileError( e:Event ):void {
			if( callback ) callback( null );
			disposeLoader();
		}

		function onFileLoaded( e:Event ):void {
			if( callback ) callback( loader.content );
			disposeLoader();
		}

		function disposeLoader():void {
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onFileLoaded );
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onFileError );
			loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileError );
			loader.unloadAndStop(true);
			loader = null ;
		}
	}

	public static function deleteFile( file:File, recursive:Boolean = true ):void {
		if ( !file || !file.exists ) return;
		if ( file.isDirectory ) {
			file.deleteDirectory( recursive );
		} else {
			file.deleteFile();
		}
	}

	//============================
	// STRING AND NUMBER STUFFS --
	//============================

	public static function getFilename( path:String, includeExtension:Boolean = true ):String {
		if ( !path ) return '';
		var fn:String = unescape( path.split( "/" ).pop() ).split( "?" ).shift();
		if ( !includeExtension ) {
			var arr:Array = fn.split( '.' );
			arr.pop();
			fn = arr.join( '.' );
		}
		return fn;
	}

	public static function redeableBytes( bytes:uint ):String {
		var exp:int = Math.log( bytes ) / Math.log( 1024 );
		return (bytes / Math.pow( 1024, exp )).toFixed( 2 ) + " " + READEABLE_BYTES_HASH[exp];
	}
}
}
