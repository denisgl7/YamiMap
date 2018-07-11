// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 27/01/2018.
//
// =================================================================================================

package maps.config {
import flash.display3D.Context3DTextureFormat;
import flash.net.URLVariables;
import flash.system.System;
import flash.utils.describeType;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

import maps.MapUtils;

import roipeker.utils.StringUtils;
import roipeker.utils.URIUtils;

public class AbsLayerProvider {

    // toggle this config to save tiles to disk.
    public var useFileCache:Boolean = false ;

    // store the texture in memory cache.
    public var useMemCache:Boolean = true;

    public var tileSize:int = 256;
    public var textureFormat:String = Context3DTextureFormat.BGRA;//BGR_PACKED;

    public var minZoomLevel:int = 0;
    public var maxZoomLevel:int = 17;

    protected var _textureScale:Number = 1;

    protected var _subdomains:Array;
    private var _subdomainCounter:uint;

    protected var _mapType:String;
    private var _validMapTypes:Array;

    // optional
    protected var _imageFormat:String;
    private var _validImageFormats:Array;

    // used for validation when describing the class.
    protected var _maptypeConstantPrefix:String = "MAPTYPE_";
    protected var _imageformatConstantPrefix:String = "FORMAT_";

    // used as id/name for the cache folder.
    public var providerId:String;

    // url params to folder path order.
    protected var _urlParamsToFolderSort:Array;

    public function AbsLayerProvider(providerId:String = '') {
        this.providerId = providerId;
        defineValidations();
    }

    private function defineValidations():void {
        /// create validation lists.
        var className:String = getQualifiedClassName(this);

        // use class name as providerId is not defined.
        if (!providerId) {
            providerId = StringUtils.replace(className.split("::")[1].toLowerCase(), "provider");
        }

        var classRef:Class = getDefinitionByName(className) as Class;
        var classDesc:XML = describeType(classRef);

        var node:XML;
        var list:XMLList = classDesc.constant;
        for each(node in list) {
            if (node.@type == "String") {
                var varName:String = node.@name;
                if (varName.indexOf(_maptypeConstantPrefix) == 0) {
                    if (!_validMapTypes) _validMapTypes = [];
                    _validMapTypes.push(classRef[varName]);
                } else if (varName.indexOf(_imageformatConstantPrefix) == 0) {
                    if (!_validImageFormats) _validImageFormats = [];
                    _validImageFormats.push(classRef[varName]);
                }
            }
        }
        System.disposeXML(classDesc);
        classDesc = null;
    }


    protected function get nextSubdomain():String {
        if (!_subdomains || !_subdomains.length) return null;
        ++_subdomainCounter;
        if (_subdomainCounter >= _subdomains.length) _subdomainCounter = 0;
        return _subdomains[_subdomainCounter];
    }

    public function resolveUrl(x:uint, y:uint, zoom:Number):String {
        return null;
    }

    public function get textureScale():Number {
        if (isNaN(_textureScale)) return 1;
        return _textureScale;
    }

    public function get mapType():String {
        return _mapType;
    }

    public function set mapType(value:String):void {
        if (_validMapTypes && _validMapTypes.indexOf(value) == -1) {
            trace('Invalid map type ' + value);
            return;
        }
        _mapType = value;
        adjustTextureFormat();
    }

    // @override for specific map types.
    protected function adjustTextureFormat():void {
    }

    public function get imageFormat():String {
        return _imageFormat;
    }

    public function set imageFormat(value:String):void {
        if (_validImageFormats && _validImageFormats.indexOf(value) == -1) {
            trace('Invalid image format ' + value);
            return;
        }
        _imageFormat = value;
    }

    public function resolveFilepath(url:String):String {
        var domain:String = URIUtils.getDomain(url);
        var path:String = providerId + "/" + trimStart(url, domain);
        // validate the url params and append.
        var paramsIndex:int = path.search(/\?|#|&/);
        if (paramsIndex > -1) {
            var baseUrl:String = path.substr(0, paramsIndex);
            path = baseUrl + "/" + MapUtils.getFilepathFromUrlParams(path, _urlParamsToFolderSort);
        }
        // slow?
        return path.replace(/\/\/+/g, '/');
    }


    //===================================================================================================================================================
    //
    //      ------  utilities
    //
    //===================================================================================================================================================

    protected function trimStart(str:String, findTrim:String, offset:int = 0):String {
        var idx:int = str.indexOf(findTrim);
        return idx == -1 ? str : str.substr( idx + findTrim.length + offset, str.length);
    }

    protected function trimEnd(str:String, findTrim:String, offset:int = 0):String {
        var idx:int = str.indexOf(findTrim);
        return idx == -1 ? str : str.substr(0, idx + offset);
    }

    protected function trimBetween(str:String, findStart:String, findEnd:String, findStartOffset:int = 0, findEndOffset:int = 0):String {
        return trimStart( trimEnd(str, findEnd,findEndOffset), findStart, findStartOffset ) ;
//        str = str.substr(0, str.indexOf(findEnd) + findEndOffset);
//        return str.substr(str.indexOf(findStart) + findStart.length + findStartOffset, str.length);
    }

    protected function resolveFilepathFromParamsOnly(url:String, trimFromUrl:String):String {
        var resultPath:String = providerId + "/";
        var urlvars:URLVariables = new URLVariables(trimStart(url, trimFromUrl));
        var keys:Array = _urlParamsToFolderSort;
        var len:int = keys.length;
        for (var i:int = 0; i < len; i++) {
            resultPath += urlvars[keys[i]];
            if (i < len - 1) {
                resultPath += "/";
            }
        }
        urlvars = null;
        return resultPath;
    }
}
}
