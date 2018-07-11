// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 06/02/2018.
//
// =================================================================================================

package core {
import roipeker.helpers.AppHelper;

import starling.display.Image;
import starling.textures.Texture;
import starling.utils.AssetManager;

public class MyAssets {

    public static var assets:AssetManager;

    public static function init(completeHandler:Function, scaleFactor:Number = 1):void {
        assets = new AssetManager(scaleFactor, false);
        assets.enqueue(AppHelper.appDir.resolvePath('assets'));
        assets.loadQueue(function (p:Number):void {
            if (p == 1) {
                if (completeHandler) completeHandler();
            }
        });
    }

    public static function getTexture(name:String):Texture {
        return assets.getTexture(name);
    }

    public static function getImage(textureName:String):Image {
        return new Image(getTexture(textureName));
    }

    public function MyAssets() {
    }
}
}
