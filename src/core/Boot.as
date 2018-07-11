package core {

import flash.display.Sprite;
import flash.events.Event;
import flash.filesystem.File;
import flash.geom.Rectangle;

import roipeker.helpers.AppHelper;
import roipeker.starling.Screener;
import roipeker.starling.StarlingFactory;
import roipeker.utils.FileUtils;
import roipeker.utils.StringUtils;

import starling.core.Starling;
import starling.utils.AssetManager;

[SWF(width="800", height="600", backgroundColor="#FFFFFF", frameRate="60")]
public class Boot extends Sprite {
    private var screen:ScreenSetup;

    public function Boot() {
        AppHelper.init(stage);
        AppHelper.onLoaderInfoComplete(init, this );
    }

    private function init():void {
        trace("stage size is:", stage.stageWidth, stage.stageHeight );
        screen = new ScreenSetup( stage.stageWidth, stage.stageHeight, [1]);
        Starling.multitouchEnabled = true ;
        
//        var starling:Starling = new Starling( MainSimplify, stage, screen.viewPort );
        var starling:Starling = new Starling( MainApp2, stage, screen.viewPort );
        starling.skipUnchangedFrames = true ;
        starling.showStats = true ;
        starling.simulateMultitouch = true ;
        starling.supportHighResolutions = true ;
        starling.stage.stageWidth = screen.stageWidth;
        starling.stage.stageHeight = screen.stageHeight;
        starling.start();
    }
}
}
