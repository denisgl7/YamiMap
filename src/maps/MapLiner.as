// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 05/02/2018.
//
// =================================================================================================

package maps {
import roipeker.utils.BasicShape;

import flash.geom.Point;
import flash.geom.Rectangle;

import maps.geo.LatLng;

import starling.display.Sprite;
import starling.filters.FragmentFilter;
import starling.textures.Texture;
import starling.utils.Pool;

public class MapLiner extends Sprite {
    private var _points:Array;
    private var _shape:roipeker.utils.BasicShape;
    public var map:YAMIMap;
    private var _lineColor:int;
    private var _lineThick:Number;
    private var _lineAlpha:Number;
    private var _lineTexture:Texture;

    public function MapLiner() {
        var ff:FragmentFilter = new FragmentFilter();
        ff.antiAliasing = 4;
        _shape = new BasicShape();
        //_shape.filter = ff;
        addChild(_shape);
        touchable = false;
//        _shape.useCircleJoints = true;
    }

    public function setLatLngData(arr:Array):void {
        // create actual pixel points.
        var len:int = arr.length;
        _points = [];
        for (var i:int = 0; i < len; i++) {
            _points[i] = LatLng(arr[i]).worldPoint;
        }
    }

    public function lineStyle(color:int, thickness:Number = 1, alpha:Number = 1):void {
        _lineColor = color;
        _lineThick = thickness;
        _lineAlpha = alpha;
        updateScaleRender();
    }

    /**
     * Bad performance... do not use when u have a lot of points.
     * @param texture
     * @param color
     * @param thickness
     * @param alpha
     */
    public function lineStyleTexture(texture:Texture, color:int, thickness:Number = 1, alpha:Number = 1):void {
        _lineTexture = texture;
        _lineColor = color;
        _lineThick = thickness;
        _lineAlpha = alpha;
        updateScaleRender();
    }

    public function updateScaleRender():void {
        if (!map) return;
        var sc:Number = map.toucher.scaleX;
        trace("map zoom scale etc", map.zoom, sc);
        _shape.scale = 1 / sc * 2;
        _shape.clear();
        if (_lineTexture) {
            _shape.lineStyleTexture(_lineTexture, _lineThick, _lineColor, _lineAlpha);
        } else {
            _shape.lineStyle(_lineThick, _lineColor, _lineAlpha);
        }

        // optimize rendering calculating bounds.
//        trace( map.viewport ) ;
//        var list:Array = getPointsInViewport();

        var p:Point = _points[0];
        _shape.moveTo(p.x * sc, p.y * sc);
        for (var i:int = 1; i < _points.length; i++) {
            p = _points[i];
            _shape.lineTo(p.x * sc, p.y * sc);
        }
    }

    private function getPointsInViewport():Array {
        var out:Array = [];
        var sc:Number = map.toucher.scaleX;
        var rect:Rectangle = map.viewport;
        var p:Point = Pool.getPoint();
        for (var i:int = 0, len:int = _points.length; i < len; i++) {
            p.x = _points[i].x //* sc;
            p.y = _points[i].y //* sc;
            trace("result", p, rect, "exists:", rect.containsPoint(p));
            out.push(p);
        }
        return out;
    }

    public function setBBox(box:Array):void {
        var p1:LatLng = box[0];
        var p3:LatLng = box[1];
        var p2:LatLng = new LatLng(p1.lat, p3.lng);
//        var p4:LatLng = new LatLng(p3.lat, p1.lng);
        setLatLngData([p1, p3]);
    }
}
}
