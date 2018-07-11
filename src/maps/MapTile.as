// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 22/01/2018.
//
// =================================================================================================

package maps {
import com.greensock.TweenLite;
import com.greensock.TweenMax;

import roipeker.utils.Pooler;

import starling.display.Image;
import starling.display.MeshBatch;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.TextField;
import starling.utils.StringUtil;

public class MapTile extends Sprite {


    private static const _pool:Pooler = new Pooler(MapTile);

    public var loadPriority:Number = 1;

    public static function get(key:String, layer:MapLayer):MapTile {
        var tile:MapTile = _pool.get();
        tile.layer = layer;
        tile.key = key;
        return tile;
    }

    public function returnPool(remove:Boolean = true):void {
        if (remove) {
            removeFromParent();
        }
        reset();
        if (_pool.owns(this)) {
            _pool.put(this);
        }
    }

    private function reset():void {
        TweenMax.killTweensOf(_image);
        if (_url) {
            // add texture for deletion?
            MapTileLoader.addPendingDisposal(_url);
        }
        loadPriority = 1;

        var loader:MapTileLoader = MapTileLoader.getInstanceByUrl(_url);
        if (loader) {
            trace("Loader exists!", _url)
            if (!loader.isLoading) {
                trace('kill delay loading', _url);
                TweenLite.killDelayedCallsTo(loader.load);
            }
            loader.returnPool();
        }

        // stop loading or leave it in the background ?
        /*var loader:MapTileLoader = MapTileLoader.isLoading(_url);
        if( loader ){
            loader.returnPool();
        }*/
        textureFormat = "bgra";
        textureScale = 1;
//        debug_tf.text = "";
        key = null;
        _url = null;
        layer = null;
        textureScale = 1;
        _image.visible = false;
        _image.texture = null;
        _bg.visible = true;
    }

    public var key:String;
    private var _tileSize:Number;
    private var _bg:Quad;
    private var _url:String;

    // save a reference.
    public var layer:MapLayer;

    public var textureFormat:String;
    public var textureScale:Number;

    private var debug_tf:TextField;
    public var zoom:uint;

    private var _grid:MeshBatch;
    private static var _gridLine:Quad;
    private var _image:Image;

    public function MapTile() {
        super();
        init();
    }

    private function init():void {

//        _bg = new Quad(10, 10, Math.random() * 0xffffff);
        _bg = new Quad(10, 10, 0xffffff);
        addChild(_bg);
        _bg.alpha = .1;
    

        _image = new Image(null);
        addChild(_image);


//        drawGrid();

        /*var format:TextFormat = new TextFormat("firasans", 12, 0xffffff, "left");
        debug_tf = new TextField(100, 100, "", format);
        debug_tf.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
        var dfs:DistanceFieldStyle = debug_tf.style as DistanceFieldStyle;
        dfs.setupOutline(3, 0x0, .8);
        debug_tf.batchable = true;
        debug_tf.touchable = false;
        debug_tf.alpha = .8;
        // todo: make a layer for labels.
        addChild(debug_tf);*/
        touchGroup = true;

        reset();
    }

    private function drawGrid():void {
//        alpha = .3 + Math.random();
        _grid = new MeshBatch();
        if (!_gridLine) {
            _gridLine = new Quad(1, 1, 0xdddddd);
            _gridLine.alpha = 0.1;
        }
        var tileS:int = 256;
        var q:Quad = _gridLine;
        var i:int;
        var a:Number;
        q.height = 256;
        q.width = 1;
        /*for (i = 0; i < 9; i++) {
            q.x = i * 32;
            if (i == 8) q.x = tileS - 1;
            a = i == 0 || i == 8 ? 1 : .3;
            _grid.addMesh(q, null, a);
        }*/
        _grid.addMesh(q, null, 1);
        q.height = 1;
        q.width = tileS;
        _grid.addMesh(q, null, 1);
        /*for (i = 0; i < 9; i++) {
            q.x = 0;
            q.y = i * 32;
            if (i == 8) q.y = tileS - 1;
            a = i == 0 || i == 8 ? 1 : .3;
            _grid.addMesh(q, null, a);
        }*/
        addChild(_grid);
    }

    public function setUrl(url:String):void {
        _url = url;
        // check if the file exists.
        if (MapTileLoader.isTextureExistent(url, layer.provider)) {
            loadPriority = 0;
        }
        trace('tile load url:', url);
        // only store the loader reference if the tile is reset BEFORE the loader ends.
        // the loader does auto pooling.
//        var loader:MapTileLoader = MapTileLoader.requestTile( url, handleComplete, handleError, true );
    }

    public function toString():String {
        return "[MapTile]" + key + "-" + loadPriority;
    }

    public function load(delay:Number = 0):void {
        var loader:MapTileLoader = MapTileLoader.get();
        loader.provider = layer.provider;
        loader.addEventListener(MapTileLoader.COMPLETE, handleComplete);
        loader.addEventListener(MapTileLoader.ERROR, handleError);
        loader.url = _url;

        // enforce cache priority.
        if (loadPriority == 0) {
            loader.load();
        } else {
            TweenLite.delayedCall(delay, loader.load);
        }
        loadPriority = 1;
    }

    private function handleError(e:Event):void {
        trace('error loading tile ' + _url);
    }

    private function handleComplete(e:Event):void {
        var loader:MapTileLoader = e.target as MapTileLoader;
        _image.texture = loader.texture;
        _image.readjustSize(_tileSize, _tileSize);

        // transition.
        _image.visible = true;
        _image.alpha = 1;
        if (loader.usingMemCache) {
            _image.alpha = 1;
            _bg.visible = false;
        } else {
	        var duration:Number = loader.loadingFromDisk ? .1 : .2;
	        //            _image.alpha = 1;
            _image.alpha = 0;
            TweenMax.to(_image, duration, {
                alpha: 1, onComplete: function () {
                    _bg.visible = false;
                }
            });
        }
        loader = null;
    }

    public function debugPosition(x:int, y:int, zoomy:int):void {
        if (debug_tf) debug_tf.text = StringUtil.format("x={0} y={1} zoom={2}", x, y, zoomy);
    }

    private function invalidate():void {
        _bg.height = _bg.width = _tileSize;
//        _grid.width = _grid.height = _tileSize ;
    }

    public function get tileSize():Number {
        return _tileSize;
    }

    public function set tileSize(value:Number):void {
        _tileSize = value;
//        trace('tile size:', value );
        invalidate();
    }

    public static function getUsed():int {
        return _pool.used;
    }
}
}
