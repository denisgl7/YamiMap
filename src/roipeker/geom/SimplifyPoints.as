// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 03/02/2018.
//
//  Port from the original JS implementation
//  https://github.com/mourner/simplify-js
//
// =================================================================================================

package roipeker.geom {
import flash.geom.Point;

public class SimplifyPoints {

    public function SimplifyPoints() {}

    /**
     * Square distance between 2 points
     * @param p1
     * @param p2
     * @return distance
     */
    [Inline]
    public static function getSqDist(p1:Point, p2:Point):Number {
        const dx:Number = p1.x - p2.x;
        const dy:Number = p1.y - p2.y;
        return dx * dx + dy * dy;
    }

    /**
     * Square distance from a point to a segment.
     * @param p     reference point
     * @param p1    segment start point
     * @param p2    segment end point
     * @return      distance
     */
    public static function getSqSegDist(p:Point, p1:Point, p2:Point):Number {
        if( !p || !p1 || !p2 ) {
            trace('Error on getSqSegDist(), a Point is null');
            return 0;
        }
        var x:Number = p1.x;
        var y:Number = p1.y;
        var dx:Number = p2.x - x;
        var dy:Number = p2.y - y;
        if (dx != 0 || dy != 0) {
            var t:Number = ((p.x - x) * dx + (p.y - y) * dy) / (dx * dx + dy * dy);
            if (t > 1) {
                x = p2.x;
                y = p2.y;
            } else if (t > 0) {
                x += dx * t;
                y += dy * t;
            }
        }
        dx = p.x - x;
        dy = p.x - y;
        return dx * dx + dy * dy;
    }

    public static function simplifyRadialDist(points:Array, sqTolerance:Number):Array {
        var prevPoint:Point = points[0];
        var result:Array = [prevPoint];
        var point:Point, i:uint = 0, len:uint = points.length;
        for (i; i < len; i++) {
            point = points[i];
            if (getSqDist(point, prevPoint) > sqTolerance) {
                result[result.length] = point;
                prevPoint = point;
            }
        }
        if (prevPoint != point) result[result.length] = point;
        return result;
    }

    /*public static function simplifyDPStep(points:Array, first:uint, last:uint, sqTolerance:Number, simplified:Array = null):void {
        // initialize the first time
        if (!simplified) simplified = [];
        var maxSqDist:Number = sqTolerance, sqDist:Number=0;
        var index:int;
        var i:int;
        for (i = first + 1; i < last; i++) {
            sqDist = getSqSegDist(points[i], points[first], points[last]);
            if (sqDist > maxSqDist) {
                index = i;
                maxSqDist = sqDist;
            }
        }
        if (maxSqDist > sqTolerance) {
            if (index - first > 1) simplifyDPStep(points, first, index, sqTolerance, simplified);
            simplified[simplified.length] = points[index];
            if (last - index > 1) simplifyDPStep(points, index, last, sqTolerance, simplified);
        }
    }*/

    /**
     * Simplification using Ramer-Douglas-Peucker algorithm
     * @see https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
     * @param points        Array
     * @param sqTolerance   Number
     * @return Array simplified points.
     */
    /*public static function simplifyDouglasPeucker(points:Array, sqTolerance:Number):Array {
        var last:int = points.length - 1;
        var simplified:Array = [points[0]];
        simplifyDPStep(points, 0, last, sqTolerance, simplified);
        simplified[simplified.length] = points[last];
        return simplified;
    }*/



    public static function simplifyDouglasPeucker(points:Array, sqTolerance:Number):Array {
        var len:int = points.length;
        var first:int = 0 , last:int = len-1,stack:Array=[], newPoints:Array=[];
        var markers:Array =[];
        var i:int, maxSqDist:Number,sqDist:Number, index:int;
        markers[first]=markers[last]=1;

        while(last){
            maxSqDist = 0 ;
            for( i=first+1;i<last;++i){
                sqDist = getSqSegDist(points[i], points[first], points[last]);
                if( sqDist > maxSqDist ){
                    index=i;
                    maxSqDist = sqDist;
                }
            }
            if( maxSqDist > sqTolerance ){
                markers[index]=i;
                stack.push(first, index, index, last);
            }
            last = stack.pop();
            first = stack.pop();
        }
        for( i=0;i<len;++i){
            if( markers[i]){
                newPoints.push(points[i]);
            }
        }
        trace('actual len:', len, points.length );
        return newPoints;
    }


    /**
     * Both algorithms combined for awesome performance.
     * @param points            Array, original points to process
     * @param tolerance         Number, default 1, not square tolerance.
     * @param highestQuality    Boolean, if true it doesn't process first with Sutherland–Hodgman algorithm.
     * @return                  Array, result simplified points.
     */
    public static function simplify( points:Array, tolerance:Number = 0, highestQuality:Boolean = false):Array {
        if (points.length <= 2) return points;
        var sqTolerance: Number = tolerance > 0 ? tolerance * tolerance : 1;
        points = highestQuality ? points : simplifyRadialDist(points, sqTolerance);
        points = simplifyDouglasPeucker( points, sqTolerance);
        return points;
    }

}
}
