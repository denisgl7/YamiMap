/**
 * Code by rodrigolopezpeker (aka 7interactive™) on 3/5/15 3:32 PM.
 */
package roipeker.utils {
import flash.net.URLRequestHeader;
import flash.net.URLVariables;
import flash.utils.ByteArray;

public class URIUtils {
	public function URIUtils() {
	}

	private static var _ba:ByteArray;

	public static function getResponseHeaderByName( name:String, headers:Array ):URLRequestHeader {
		if ( !headers ) {
			return null;
		}
		name = name.toLowerCase();
		for each( var header:URLRequestHeader in headers ) {
			if ( header && header.name.toLowerCase() == name )
				return header;
		}
		return null;
	}

	/**
	 * Utility function to convert object properties to URLVariables.
	 * @param parameters
	 * @return
	 */
	public static function getUrlVariablesFromObject( parameters:Object ):URLVariables {
		var vars:URLVariables = new URLVariables();
		var p:String;
		// only 1 level.
		for ( p in parameters ) {
			vars[p] = parameters[p];
		}
		return vars;
	}

	public static function getVariablesFromUrl( url:String ):URLVariables {
		var cleanUrl:String = stripParametersFromUrl( url );
//        trace('clea nrul:', cleanUrl);
		var urlVars:URLVariables = new URLVariables();
		if ( url == cleanUrl )
			return urlVars;

		var urlParameters:String = url.substr( cleanUrl.length + 1 ); // +1 to exclude ? or # ;
		if ( urlParameters == "" )
			return urlVars;

		urlParameters = StringUtils.replace( urlParameters, "?", "&" );
		urlParameters = StringUtils.replace( urlParameters, "#", "&" );
		urlVars.decode( urlParameters );
		return urlVars;
	}

	public static function stripParametersFromUrl( url:String ):String {
		var i:int;
		const SEARCH:Array = ["?", "#", "&"];
		for each( var key:String in SEARCH ) {
			i = url.indexOf( key );
			if ( i > -1 ) {
				url = url.substr( 0, i );
			}
		}
		return url;
	}

	public static function addParametersToUrl( url:String, parametersObj:Object, doSort:Boolean = false ):String {
		var separator:String = "?";

		if ( url.indexOf( "?" ) == -1 && url.indexOf( "#" ) > -1 )
			separator = "#";

		var urlPath:String = stripParametersFromUrl( url );
		var urlVariables:URLVariables = getVariablesFromUrl( url );

		var propertyName:String;

		// include new variables.
		for ( propertyName in parametersObj )
			urlVariables[propertyName] = parametersObj[propertyName];

		var parameters_arr:Array = [];
		for ( propertyName in urlVariables ) {
			parameters_arr.push( propertyName + "=" + encodeURIComponent( urlVariables[propertyName] ) );
		}

		if ( doSort ) {
			parameters_arr = parameters_arr.sort();
		}

		return urlPath + separator + parameters_arr.join( "&" );
	}

	public static function getDomain( url:String ):String {
		var baseUrl:String = url.split( "://" )[1].split( "/" )[0];
		return (baseUrl.substr( 0, 4 ) == "www.") ? baseUrl.substr( 4 ) : baseUrl;
	}

	public static function sameDomain( url1:String, url2:String ):Boolean {
		return getDomain( url1 ) == getDomain( url2 );
	}

	public static function mergeObjects( params:Object, extra:Object ):void {
		for ( var p:String in extra ) {
			params[p] = extra[p];
		}
	}

	public static function getOauth1HeaderValue( props:Object ):String {
		var headerParts:Array = [];
		for ( var param:String in props ) {
			headerParts.push( param + '="' + encodeURIComponent( props[param] ) + '"' );
		}
		return "OAuth " + headerParts.join( ", " );
	}
}
}
