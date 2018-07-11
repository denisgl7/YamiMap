// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 03/02/2018.
//
// =================================================================================================

package core {
import flash.display.Graphics;
import flash.display.Shape;
import flash.geom.Point;
import flash.utils.getTimer;

import roipeker.geom.Simplify;

import roipeker.geom.SimplifyPoints;
import roipeker.helpers.AppHelper;
import roipeker.utils.FileUtils;

import starling.core.Starling;
import starling.display.Sprite;
import starling.events.Event;

// this is just to test a Simplification of points in a line... to reduce the geometry.
public class MainSimplify extends Sprite {

    public function MainSimplify() {
        addEventListener(Event.ADDED_TO_STAGE, run);
    }


    public function run():void {
//       benchmark();
        renderPoints();
    }

    private function renderPoints():void {
        var originalPoints:Array = FileUtils.readJSON(AppHelper.appDir.resolvePath('tests/test-points.json')); //x,y
        trace('orignal points:', originalPoints.length );
        var ppp:Array = [];
        for (var i:int = 0, len:int= originalPoints.length; i < len; i++) {
            ppp[ppp.length] = new Point(originalPoints[i].x,originalPoints[i].y);
        }

        var shape:Shape = new Shape();
        shape.x = -100 ;
//        shape.scaleX = shape.scaleY = 2 ;
        var g:Graphics = shape.graphics;
        Starling.current.nativeOverlay.addChild(shape);

        var render_arr:Array ;

        /// apply tollerance.
        var t:int = getTimer() ;
        render_arr = Simplify.simplify( ppp, .003, false );
        trace('result:', render_arr.length , ' in : ', getTimer()-t);

        renderMe();

        function renderMe():void {
            var arr:Array = render_arr;
            g.clear();
            g.lineStyle(0, 0xff0000, 1, false);
            g.moveTo(arr[0].x, arr[0].y);

            var i:int = 1, len:int = arr.length;
            for (i; i < len; i++) {
                g.lineTo(arr[i].x, arr[i].y);
            }
        }

    }

    private function benchmark():void {
        var pointsObj:Array = FileUtils.readJSON(AppHelper.appDir.resolvePath('tests/1k.json')); //x,y

        var points:Array = [];
        for (var i:int = 0, len:int = pointsObj.length; i < len; i++) {
            points[i] = new Point(pointsObj[i].x, pointsObj[i].y);
        }

        // benchmark.
        trace('benchmarking simplify on ' + points.length + ' points...');

        var t:int;
        var res:Array = points.concat();

        t = getTimer();
        res = SimplifyPoints.simplify(res, 20, true);
        trace('simplify HQ ', getTimer() - t, " res:", res.length);

        res = points.concat();

        t = getTimer();
        SimplifyPoints.simplify(res, 3, false);
        trace('simplify normal ', getTimer() - t, " res:", res.length);

    }
}
}
