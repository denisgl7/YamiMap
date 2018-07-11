/**
 *
 * Created by Rodrigo Lopez [blnk™] on 6/27/17.
 *
 */
package roipeker.utils {
public class MathUtils {
    private static const TODEG:Number = 180 / Math.PI;
    private static const TORAD:Number = Math.PI / 180;

    [Inline]
    public static function deg2rad(degrees:Number):Number {
        return degrees * TORAD;
    }
    [Inline]
    public static function rad2deg(rads:Number):Number {
        return rads * TODEG;
    }

    public static function roundToPrecision(value:Number, precision:uint = 2):Number {
        var decimalPlaces:Number = Math.pow(10, precision);
        return Math.round(decimalPlaces * value) / decimalPlaces;
    }

    public static function roundToNearest(value:Number, nearest:Number = 1):Number {
        if (nearest == 0) return value;
        var roundedNumber:Number = Math.round(roundToPrecision(value / nearest, 10)) * nearest;
        return roundToPrecision(roundedNumber, 10);
    }

    public static function roundDownToNearest(number:Number, nearest:Number = 1):Number {
        if (nearest == 0) return number;
        return Math.floor(roundToPrecision(number / nearest, 10)) * nearest;
    }

    public static function roundUpToNearest(number:Number, nearest:Number = 1):Number {
        if (nearest == 0) return number;
        return Math.ceil(roundToPrecision(number / nearest, 10)) * nearest;
    }

    public static function randomRange(start:Number, end:Number, round:Boolean = false):Number {
        var val:Number = start + (Math.random() * (end - start));
        return round ? Math.round(val) : val;
    }

}
}
