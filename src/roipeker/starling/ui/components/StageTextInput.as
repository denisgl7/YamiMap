/**
 *
 * Created by Rodrigo Lopez [blnk™] on 7/27/17.
 *
 */
package roipeker.starling.ui.components {
import roipeker.starling.ui.*;
import roipeker.helpers.AppHelper;
import roipeker.helpers.UIHelper;
import roipeker.starling.Screener;
import roipeker.starling.StarlingUtils;
import roipeker.starling.ui.AbsSprite;
import roipeker.utils.Pooler;

import flash.display.BitmapData;
import flash.events.FocusEvent;

import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.AutoCapitalize;
import flash.text.ReturnKeyLabel;
import flash.text.SoftKeyboardType;
import flash.text.StageText;
import flash.text.StageTextClearButtonMode;
import flash.text.StageTextInitOptions;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.engine.FontPosture;
import flash.text.engine.FontWeight;

import starling.display.DisplayObject;

import starling.display.Image;

import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.rendering.Painter;
import starling.textures.ConcreteTexture;
import starling.textures.Texture;
import starling.utils.MatrixUtil;
import starling.utils.Pool;

public class StageTextInput extends AbsSprite {

	// create pool
	//===================================================================================================================================================
	//
	//      ------  POOL
	//
	//===================================================================================================================================================
	private static var _pool:Pooler;

	public static function get( family:String, size:int=20, color:uint=0x555555, doc:Sprite = null ):StageTextInput {
		if ( !_pool )
			_pool = Pooler.build( StageTextInput, null, "reset" );
		var tf:StageTextInput = _pool.get(true) as StageTextInput ;
		tf.fontFamily = family ;
		tf.fontSize = size ;
		tf.color = color ;
		if ( doc ) doc.addChild( tf );
		return tf;
	}

	public static function put( spinner:StageTextInput ):void {
		spinner.returnPool();
	}

	public function returnPool():void {
		if ( !_pool.owns( this ) ) {
			trace( 'StageTextInput::returnPool() Only instances requested by StageTextInput::get() are elegible' );
			return;
		}
		_pool.put( this );
		if ( parent ) parent.removeChild( this );
	}

	public function reset():void {
		_fontFamily = null ;
		_fontSize = 12 ;
		_color = 0x0 ;
		clearFocus();
		_pendingSelectionBeginIndex=_pendingSelectionEndIndex=-1;
		maintainTouchFocus = false ;
		_hasFocus = null ;
		text = null ;
	}

	private var _pendingSelectionBeginIndex:int;
	private var _pendingSelectionEndIndex:int;

	private var stageText:StageText;
	private var _stageTextIsComplete:Boolean = false;
	private var _hasFocus:Boolean = false;
	private var _text:String = "";

	public var maintainTouchFocus:Boolean = false ;

	private var _measure_tf:TextField;

	private var _needsNewTexture:Boolean;
	private var _needsTextureUpdate:Boolean;

	private var snapshot:Image;

	private var _touchPointId:int =-1 ;
	private var _isWaitingToSetFocus:Boolean= false;

	public var resizeOnFontSizeChange:Boolean = false ;

	public var setFocusOnEndPhase:Boolean = false ;
	public var updateSnapshotOnScaleChange:Boolean;

	private var _lastGlobalScaleX:Number;
	private var _lastGlobalScaleY:Number;

	public function StageTextInput(doc:Sprite = null ) {
		super( doc );
	}

	override protected function removedFromStageHandler( event:Event ):void {
		super.removedFromStageHandler( event );
		if( _hasFocus ){
			clearFocus();
		}
		_touchPointId = -1 ;
		if ( stageText ) stageText.stage = null;
		// cursors?
	}

	private function clearFocus():void {
		if( !_hasFocus) return ;
		starling.nativeStage.focus = null ;
	}

	private function setFocusOnTouch( touch:Touch ):void {
		var p:Point = Pool.getPoint();
		touch.getLocation(stage, p);
		var isInBounds:Boolean = contains(stage.hitTest(p));
		if( isInBounds && !_hasFocus ){
			_isWaitingToSetFocus = false ;
			globalToLocal(p, p);
			setFocus( p );
		}
		Pool.putPoint(p);
	}

	public function setFocus( p:Point = null ):void {
		if( !_isEditable && ( AppHelper.isAndroid || !_isSelectable )) return ;
		if( !visible ) return ;
		if( stage && !stageText.stage ){
			stageText.stage = starling.nativeStage ;
		}
		if( stageText && _stageTextIsComplete ){
			if( p ) {
				var px:Number = p.x + 2;
				var py:Number = p.y + 2;
				if ( px < 0 ) {
					_pendingSelectionBeginIndex = _pendingSelectionEndIndex = 0;
				} else {
					_pendingSelectionBeginIndex = _measure_tf.getCharIndexAtPoint( px, py );
					if ( _pendingSelectionBeginIndex < 0 ) {
						if( _multiline ){
							var lineIdx:int = int(py / _measure_tf.getLineMetrics(0).height);
							try {
								_pendingSelectionBeginIndex = _measure_tf.getLineOffset(lineIdx) * _measure_tf.getLineLength(lineIdx);
								if( _pendingSelectionBeginIndex != _text.length ){
									_pendingSelectionBeginIndex--;
								}
							} catch( e: Error ){
								_pendingSelectionBeginIndex = _text.length;
							}
						} else {
							_pendingSelectionBeginIndex = _measure_tf.getCharIndexAtPoint(px, _measure_tf.getLineMetrics(0).ascent/2);
							if( _pendingSelectionBeginIndex < 0 ){
								_pendingSelectionBeginIndex = _text.length ;
							}
						}
					} else {
						var bounds:Rectangle = _measure_tf.getCharBoundaries( _pendingSelectionBeginIndex );
						if ( bounds && (bounds.x + bounds.width - px ) < (px - bounds.x) ) {
							_pendingSelectionBeginIndex++;
						}
					}
					_pendingSelectionEndIndex = _pendingSelectionBeginIndex;
				}
			} else {
				_pendingSelectionEndIndex = _pendingSelectionBeginIndex = -1;
			}
			stageText.visible = true ;
			if( !_isEditable ){
				stageText.editable = true ;
			}
			if( !_hasFocus ){
				stageText.assignFocus();
			}
		} else {
			_isWaitingToSetFocus = true ;
		}
	}

	public function selectRange(start:int, end:int):void {
		if( _stageTextIsComplete && stageText ){
			_pendingSelectionBeginIndex = _pendingSelectionEndIndex= -1 ;
			stageText.selectRange(start, end);
		} else {
			trace("selecting range...", start, end );
			_pendingSelectionBeginIndex = start;
			_pendingSelectionEndIndex= end ;
		}
	}

	override protected function initialize():void {
		super.initialize();
		if ( _measure_tf && !_measure_tf.parent ) {
			starling.nativeStage.addChild( _measure_tf );
		} else if ( !_measure_tf ) {
			_measure_tf = new TextField();
			_measure_tf.visible = false;
			_measure_tf.mouseWheelEnabled = _measure_tf.mouseEnabled = false;
			_measure_tf.autoSize = "left";
			_measure_tf.border = true;
			_measure_tf.borderColor = 0xff0000;
			_measure_tf.multiline = false;
			_measure_tf.wordWrap = false;
			_measure_tf.embedFonts = false;
			_measure_tf.defaultTextFormat = new TextFormat( null, 12, 0x0, false, false, false );
			starling.nativeStage.addChild( _measure_tf );
		}
		createStageText();
	}

	private function createStageText():void {
		_stageTextIsComplete = false;
		var initOptions:StageTextInitOptions = new StageTextInitOptions( _multiline );
		stageText = new StageText( initOptions );
		stageText.visible = false ;
		stageText.clearButtonMode = StageTextClearButtonMode.NEVER;
		stageText.stage = starling.nativeStage;
		activate( true );
	}

	private function disposeStageText():void {
		if ( !stageText ) return;
		activate( false );
		stageText.stage = null;
		stageText.dispose();
		stageText = null;
	}

	override public function activate( flag:Boolean ):void {
		if ( flag == _active ) return;
		super.activate( flag );
		UIHelper.listener( stageText, Event.COMPLETE, completeHandler, flag );
		UIHelper.listener( stageText, [FocusEvent.FOCUS_IN,FocusEvent.FOCUS_OUT,FocusEvent.MOUSE_FOCUS_CHANGE], focusHandler, flag );
		UIHelper.listener( stageText, Event.CHANGE, changeHandler, flag );
		// custom
		UIHelper.listenerTouch( this, touchHandler, flag );
	}

	//===================================================================================================================================================
	//
	//      ------  EVENTS
	//
	//===================================================================================================================================================

	private function touchHandler(e:TouchEvent):void {
		if (!_isEnabled ){
			_touchPointId = -1;
			return ;
		}
		var touch:Touch;
		if( _touchPointId  == -1 ){
			touch = e.getTouch(this, TouchPhase.BEGAN);
			if( touch ){
				_touchPointId = touch.id ;
				// TODO: set touch on end phase?
				if( !setFocusOnEndPhase ) setFocusOnTouch( touch );
				return ;
			}
			touch = e.getTouch(this, TouchPhase.HOVER);
			if( touch ){
//				if ( (_isEditable || _isSelectable ))
				// TODO: refresh cursor?
				return ;
			}
		} else {
			touch = e.getTouch(this, TouchPhase.ENDED, _touchPointId );
			if (!touch ) return ;
			var p:Point = Pool.getPoint();
			touch.getLocation(stage, p);
			var isInBounds:Boolean = contains(stage.hitTest(p));
			Pool.putPoint(p);
			if( !isInBounds ){
				// remove cursor
			}
			_touchPointId = -1;
			if( setFocusOnEndPhase ) setFocusOnTouch(touch);
		}
	}


	private function changeHandler(e:*):void {
		text = stageText.text ;
	}

	private function completeHandler( e:* ):void {
		UIHelper.listener( stageText, Event.COMPLETE, completeHandler, false );
		_stageTextIsComplete = true;
		invalidate();
	}

	private function focusHandler(e:FocusEvent):void {

		if( e.type == FocusEvent.MOUSE_FOCUS_CHANGE ){
			if (!maintainTouchFocus ) return ;
			e.preventDefault() ;
			return ;
		}

		_hasFocus = e.type == FocusEvent.FOCUS_IN;
		if( _hasFocus ){
			if( !_isEditable ){
				// hack for setFocus()
				stageText.editable = false ;
			}
			addEventListener(Event.ENTER_FRAME, hasFocusEnterFrameHandler);
			if( snapshot ) snapshot.visible = false ;
		} else {
			stageText.selectRange(1,1);
			invalidate(INVALIDATE_DATA);
		}

		invalidate(INVALIDATE_SKIN);
		dispatchEventWith(e.type);
	}

	private function hasFocusEnterFrameHandler( event:Event ):void {
		if( _hasFocus ){
			// if some parent becomes invisible... remove focus.
			var target:DisplayObject = this ;
			while( target ){
				if(!target.visible){
					stageText.stage.focus = null ;
					break;
				}
				target = target.parent;
			}
		} else {
			removeEventListener( Event.ENTER_FRAME, hasFocusEnterFrameHandler);
		}
	}


	override public function render( painter:Painter ):void {
		if ( _hasFocus ) painter.excludeFromCache( this );
		// update on scale change??
		if( snapshot && updateSnapshotOnScaleChange ){
			var m:Matrix = Pool.getMatrix();
			getTransformationMatrix(stage, m);
			if( StarlingUtils.matrixToScaleX(m) != _lastGlobalScaleX || StarlingUtils.matrixToScaleY(m) != _lastGlobalScaleY ){
				// UFF, ENFORCE THE INVALIDATION to redraw the texture.
				invalidate(INVALIDATE_SIZE);
				validate();
			}
			Pool.putMatrix(m);
		}

		if( _needsTextureUpdate ){
			_needsTextureUpdate=false;
			var hasText:Boolean = _text.length>0;
			if( hasText ){
				refreshSnapshot();
			}
			if( snapshot ){
				snapshot.visible = !_hasFocus;
				snapshot.alpha = hasText ? 1 : 0 ;
			}
			if( !_hasFocus){
				stageText.visible = false;
			}
		}

		if ( stageText && stageText.visible ) {
			refreshViewport();
		}
		if( snapshot ){
			positionSnapshot();
		}
		super.render( painter );
	}

	private function refreshSnapshot():void {
		if( stage && !stageText.stage){
			stageText.stage = starling.nativeStage ;
		}
		if( !stageText.stage ){
			invalidate(INVALIDATE_DATA);
			return ;
		}
		var viewport:Rectangle = stageText.viewPort;
		if( !viewport || viewport.isEmpty()) return ;
		var nativeScaleFactor:Number = 1 ;
		if( starling.supportHighResolutions ) {
			nativeScaleFactor = starling.nativeStage.contentsScaleFactor ;
		}
		try {
			var bd:BitmapData = new BitmapData(viewport.width*nativeScaleFactor,viewport.height*nativeScaleFactor, true, 0x00ff00ff);
			stageText.drawViewPortToBitmapData(bd);
		} catch( e:Error ){
			bd.dispose();
			bd = new BitmapData(viewport.width, viewport.height, true, 0x00ff00ff);
			stageText.drawViewPortToBitmapData(bd);
		}
		var newTexture:Texture ;
		if (!snapshot || _needsNewTexture ){
			var scaleFactor:Number = starling.contentScaleFactor ;
			newTexture = Texture.empty(bd.width/scaleFactor,bd.height/scaleFactor, true, false, false, scaleFactor );
			newTexture.root.uploadBitmapData(bd);
			newTexture.root.onRestore = texture_onRestore ;
		}
		if (!snapshot){
			snapshot = new Image(newTexture);
			snapshot.pixelSnapping = true ;
			addChild(snapshot);
		} else {
			if( _needsNewTexture ){
				snapshot.texture.dispose();
				snapshot.texture = newTexture;
				snapshot.readjustSize();
			} else {
				var currTexture:Texture = snapshot.texture;
				currTexture.root.uploadBitmapData(bd);
				snapshot.setRequiresRedraw();
			}
		}
		if( updateSnapshotOnScaleChange ){
			var m:Matrix = Pool.getMatrix();
			getTransformationMatrix(stage, m);
			var sx:Number = StarlingUtils.matrixToScaleX(m);
			var sy:Number = StarlingUtils.matrixToScaleY(m);
			snapshot.scaleX = 1 / sx ;
			snapshot.scaleY = 1 / sy ;
			_lastGlobalScaleX = sx ;
			_lastGlobalScaleY = sy ;
			Pool.putMatrix(m);
			// update on scale change???
		} else {
			snapshot.scale = 1 ;
		}

		if( nativeScaleFactor > 1 && bd.width == viewport.width ){
			// fallback texture (low res)
			snapshot.scaleX *= nativeScaleFactor ;
			snapshot.scaleY *= nativeScaleFactor ;
		}
		bd.dispose();
		_needsNewTexture = false ;
	}

	private function texture_onRestore():void {
		if( snapshot.texture.scale != starling.contentScaleFactor ){
			invalidate(INVALIDATE_SIZE);
		} else {
			refreshSnapshot();
			if( snapshot ){
				snapshot.visible = !_hasFocus;
				snapshot.alpha = _text.length>0?1:0;
			}
			if( !_hasFocus){
				stageText.visible = false ;
			}
		}
	}

	private function positionSnapshot():void {
		var m:Matrix = Pool.getMatrix();

		var nativeScaleFactor:Number  = starling.supportHighResolutions ? starling.nativeStage.contentsScaleFactor : 1 ;
		var scaleFactor:Number = starling.contentScaleFactor / nativeScaleFactor;
		var desktopGutterPosOff:Number = 0 ;
		if( scaleFactor < 1 ){
			desktopGutterPosOff = 2 ;
		}
		snapshot.x = Math.round(m.tx)-m.tx - desktopGutterPosOff ;
		snapshot.y = Math.round(m.ty)-m.ty - desktopGutterPosOff + verticalAlignOffset ;
		Pool.putMatrix(m);
	}

	override protected function draw():void {
		super.draw();
		var invalidSize:Boolean = isInvalid( INVALIDATE_SIZE );
		commitProps();
		invalidSize = autosizeIfNeeded() || invalidSize;
		layout( invalidSize );
	}

	private function autosizeIfNeeded():Boolean {
		if( _w > 0 && _h > 0 ) return false ;
		var p:Point = Pool.getPoint();
		measure( p );
		// take the measurement and validate if its bigger?
		var changedSize:Boolean = setSize(p.x, p.y);
		Pool.putPoint(p);
		return changedSize ;
	}

	private function measure( p:Point ):Point {
		if( !p ) p = new Point();
		_measure_tf.autoSize = "left";
		var newW:int = _w ;
		var newH:int = _h ;
		if( _w <= 0 ){
			newW = _measure_tf.textWidth + 4 ;
//			newW = _measure_tf.width;
			// todo: contemplate min and max measures?
		}
		_measure_tf.width = newW ;
		if( _h <= 0 ){
//			newH = _measure_tf.height;
			newH = _measure_tf.textHeight ;
			// todo: contemplate min and max measures?
		}
		_measure_tf.autoSize = "none";
		// put back dimensions for other validation.
		_measure_tf.width = _w ;
		_measure_tf.height = _h ;
		p.setTo(newW, newH);
		return p ;
	}

	private function commitProps():void {
		var invalidData:Boolean = isInvalid( INVALIDATE_DATA );
		var invalidStyle:Boolean = isInvalid( INVALIDATE_STYLE );

		if ( invalidStyle || invalidData ) {
			// refresh TextField.
			refreshMeasureProps();
		}

		if ( invalidStyle ) {
			refreshStageTextProps();
		}

		if ( invalidData ) {
			if ( stageText.text != _text ) {
				if ( _pendingSelectionBeginIndex < 0 ) {
					_pendingSelectionBeginIndex = stageText.selectionActiveIndex;
					_pendingSelectionEndIndex = stageText.selectionAnchorIndex;
				}
				stageText.text = _text;
			}
		}
	}

	private function refreshMeasureProps():void {
		_measure_tf.wordWrap = _measure_tf.multiline = _multiline;
		var format:TextFormat = _measure_tf.defaultTextFormat;
		format.size = _fontSize > 0 ? _fontSize : 12;
		format.font = _fontFamily;
		format.bold = _bold;
		format.italic = _italic;
		format.color = color ;
		_measure_tf.displayAsPassword = _displayAsPassword ;
		_measure_tf.maxChars = _maxChars ;
		_measure_tf.restrict = _restrict ;
		_measure_tf.defaultTextFormat = format;
		_measure_tf.text = _text.length == 0 ? " " : _text;
		_measure_tf.setTextFormat( format );
	}

	private function refreshStageTextProps():void {
		if ( stageText.multiline != _multiline ) {
			disposeStageText();
			createStageText();
		}
		stageText.fontPosture = _italic ? FontPosture.ITALIC : FontPosture.NORMAL;
		stageText.fontWeight = _bold ? FontWeight.BOLD : FontWeight.NORMAL;
		stageText.color = _color;
		stageText.fontFamily = _fontFamily;

		stageText.autoCapitalize = _autoCapitalize ;
		stageText.autoCorrect = _autoCorrect ;
		stageText.displayAsPassword = _displayAsPassword;
		stageText.locale = _locale ;
		stageText.maxChars = _maxChars;
		stageText.restrict = _restrict ;
		stageText.returnKeyLabel = _returnKeyLabel;
		stageText.softKeyboardType = _softKeyboardType;
		stageText.textAlign = _textAlign ? _textAlign : TextFormatAlign.START ;
		stageText.clearButtonMode  = _clearButtonMode ;
	}

	private function layout( invalidSize:Boolean ):void {
		var invalidData:Boolean = isInvalid( INVALIDATE_DATA );
		var invalidStyle:Boolean = isInvalid( INVALIDATE_STYLE );
		if ( invalidSize || invalidData || invalidStyle ) {
			refreshViewport();
			refreshMeasureDimensions();
			var viewport:Rectangle = stageText.viewPort ;
			var textureRoot:ConcreteTexture = snapshot?snapshot.texture.root:null;
			_needsNewTexture = _needsNewTexture || !snapshot ||
					(textureRoot &&
					textureRoot.scale != starling.contentScaleFactor ||
					viewport.width != textureRoot.nativeWidth ||
					viewport.height != textureRoot.nativeHeight ) ;
		}
		if (!_hasFocus && (invalidSize||invalidStyle||invalidData || _needsNewTexture )){
			_needsTextureUpdate = true ;
			setRequiresRedraw();
		}
		doPendingActions();
	}

	private function doPendingActions():void {
		if( _isWaitingToSetFocus ){
			_isWaitingToSetFocus = false ;
			setFocus();
		}

		if( _pendingSelectionBeginIndex >= 0 ){
			var start:int = _pendingSelectionBeginIndex ;
			var end:int = _pendingSelectionEndIndex < 0 ? _pendingSelectionBeginIndex : _pendingSelectionEndIndex ;
			if( stageText.selectionAnchorIndex != start || stageText.selectionActiveIndex != end ){
				selectRange(start, end);
			}
		}
	}

	private function refreshMeasureDimensions():void {
		_measure_tf.width = _w ;
		_measure_tf.height = _h;
	}

	private function refreshViewport():void {
		var m:Matrix = Pool.getMatrix();
		var p:Point = Pool.getPoint();

		var desktopGutterPosOff:Number = 0 ;
		var desktopGutterDimOff:Number = 2 ;

		var nativeScaleFactor:Number = 1;
		if ( starling.supportHighResolutions ) {
			nativeScaleFactor = starling.nativeStage.contentsScaleFactor;
		}
		var scaleFactor:Number = starling.contentScaleFactor / nativeScaleFactor;
		if( scaleFactor < 1 ){
			desktopGutterPosOff = 2 ;
			desktopGutterDimOff = 4 ;
		}
		// if its textfield!
		getTransformationMatrix( stage, m );
		var sx:Number =1;
		var sy:Number =1 ;
		var smallerScale:Number =1 ;
		if ( _hasFocus || updateSnapshotOnScaleChange ) {
			sx = StarlingUtils.matrixToScaleX( m );
			sy = StarlingUtils.matrixToScaleY( m );
			smallerScale = sx;
			if ( smallerScale < sy ) {
				smallerScale = sy;
			}
		}
		
		var verticalOffset:Number = verticalAlignOffset;
		// 3d flag???
		if ( is3D ) {
		} else {
			MatrixUtil.transformCoords( m, -desktopGutterPosOff, -desktopGutterPosOff + verticalOffset, p );
		}
		var starlingViewport:Rectangle = starling.viewPort;
		var textViewport:Rectangle = stageText.viewPort;
		if ( !textViewport ) textViewport = new Rectangle();

		var viewW:int = Math.round( (_w ) * scaleFactor * sx ) + desktopGutterDimOff ;
		if ( viewW < 1 ) viewW = 1;
		var viewH:int = Math.round( (_h ) * scaleFactor * sy ) + desktopGutterDimOff ;
		if ( viewH < 1 ) viewH = 1;

		var viewX:Number = Math.floor( starlingViewport.x + (p.x * scaleFactor ) );
		var viewY:Number = Math.floor( starlingViewport.y + (p.y * scaleFactor ) );
		// contemplate max position????
		if ( viewX + viewW > 8191 ) viewX = 8191 - viewW;
		else if ( viewX < -8191 ) viewX = -8191;
		if ( viewY + viewH > 8191 ) viewY = 8191 - viewH;
		else if ( viewY < -8191 ) viewY = -8191;

		textViewport.x = viewX;
		textViewport.y = viewY;
		textViewport.width = viewW;
		textViewport.height = viewH;

		stageText.viewPort = textViewport;
		var fontSize:int = _fontSize > 0 ? _fontSize : 12;
		var newFontSize:int = fontSize * scaleFactor * smallerScale;
		if ( stageText.fontSize != newFontSize ) {
			stageText.fontSize = newFontSize;
		}

		// match the textfield!
//		_measure_tf.x = 100 * scaleFactor ;
//		_measure_tf.y = 100 * scaleFactor ;
//		_measure_tf.scaleX = scaleFactor ;
//		_measure_tf.scaleY = scaleFactor ;

		Pool.putPoint( p );
		Pool.putMatrix( m );
	}

	override public function dispose():void {
		if( _measure_tf ){
			if(_measure_tf.parent) _measure_tf.parent.removeChild(_measure_tf);
			_measure_tf = null ;
		}
		if( stageText ){
			disposeStageText();
		}
		if( snapshot ){
			snapshot.texture.dispose();
			removeChild(snapshot);
			snapshot = null ;
		}
		super.dispose();
	}

	private function get verticalAlignOffset():Number {
		return 0 ;
		if( _measure_tf.textHeight > _h ) return 0 ;
		// center by default.
		return (_h - _measure_tf.textHeight) / 2 ;
	}

	//===================================================================================================================================================
	//
	//      ------  ACCESSORS
	//
	//===================================================================================================================================================
	protected var _autoCapitalize:String = AutoCapitalize.NONE;
	protected var _autoCorrect:Boolean = false ;
	protected var _color:int = 0x0 ;
	protected var _displayAsPassword:Boolean = false;
	protected var _isEditable:Boolean = true;
	protected var _isSelectable:Boolean = true;
	protected var _fontFamily:String = null;
	protected var _fontSize:int = 0;
	protected var _maxChars:int = 0;
	protected var _locale:String = "en";
	protected var _multiline:Boolean = false ;
	protected var _restrict:String;
	protected var _returnKeyLabel:String = ReturnKeyLabel.DEFAULT ;
	protected var _softKeyboardType:String = SoftKeyboardType.DEFAULT;
	protected var _textAlign:String;
	protected var _clearButtonMode:String = StageTextClearButtonMode.WHILE_EDITING;
	private var _bold:Boolean = false;
	private var _italic:Boolean = false;
	private var _isEnabled:Boolean = true ;


	public function get clearButtonMode():String {return _clearButtonMode;}
	public function set clearButtonMode( value:String ):void {
		if ( _clearButtonMode == value ) return;
		_clearButtonMode = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get textAlign():String {return _textAlign;}
	public function set textAlign( value:String ):void {
		if ( _textAlign == value ) return;
		_textAlign = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get softKeyboardType():String {return _softKeyboardType;}
	public function set softKeyboardType( value:String ):void {
		if ( _softKeyboardType == value ) return;
		_softKeyboardType = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get returnKeyLabel():String {return _returnKeyLabel;}
	public function set returnKeyLabel( value:String ):void {
		if ( _returnKeyLabel == value ) return;
		_returnKeyLabel = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get restrict():String {return _restrict;}
	public function set restrict( value:String ):void {
		if ( _restrict == value ) return;
		_restrict = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get multiline():Boolean {return _multiline;}
	public function set multiline( value:Boolean ):void {
		if ( _multiline == value ) return;
		_multiline = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get maxChars():int {return _maxChars;}
	public function set maxChars( value:int ):void {
		if ( _maxChars == value ) return;
		_maxChars = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get locale():String {return _locale;}
	public function set locale( value:String ):void {
		if ( _locale == value ) return;
		_locale = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get fontSize():int {return _fontSize;}
	public function set fontSize( value:int ):void {
		if ( _fontSize == value ) return;
		_fontSize = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get bold():Boolean {return _bold;}
	public function set bold( value:Boolean ):void {
		if ( _bold == value ) return;
		_bold = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get italic():Boolean {return _italic;}
	public function set italic( value:Boolean):void {
		if ( _italic == value ) return;
		_italic = value;
		invalidate( INVALIDATE_STYLE );
	}

	public function get fontFamily():String {return _fontFamily;}
	public function set fontFamily( value:String ):void {
		if ( _fontFamily == value ) return;
		_fontFamily = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get isSelectable():Boolean {return _isSelectable;}
	public function set isSelectable( value:Boolean ):void {
		if ( _isSelectable == value ) return;
		_isSelectable = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get isEditable():Boolean {return _isEditable;}
	public function set isEditable( value:Boolean ):void {
		if ( _isEditable == value ) return;
		_isEditable = value;
		invalidate( INVALIDATE_STYLE );
	}

	public function get displayAsPassword():Boolean {return _displayAsPassword;}
	public function set displayAsPassword( value:Boolean ):void {
		if ( _displayAsPassword == value ) return;
		_displayAsPassword = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get color():int {return _color;}
	public function set color( value:int ):void {
		if ( _color == value ) return;
		_color = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get autoCorrect():Boolean {return _autoCorrect;}
	public function set autoCorrect( value:Boolean ):void {
		if ( _autoCorrect == value ) return;
		_autoCorrect = value;
		invalidate( INVALIDATE_STYLE );
	}

	public function get autoCapitalize():String {return _autoCapitalize;}
	public function set autoCapitalize( value:String ):void {
		if ( _autoCapitalize == value ) return;
		_autoCapitalize = value;
		invalidate( INVALIDATE_STYLE );
	}


	public function get baseline():Number {
		if ( !_measure_tf ) return 0;
		return _measure_tf.getLineMetrics( 0 ).ascent;
	}

	public function get selectionBeginIndex():int {
		if ( _pendingSelectionBeginIndex >= 0 ) return _pendingSelectionBeginIndex;
		if ( stageText ) return stageText.selectionAnchorIndex;
		return 0;
	}

	public function get selectionEndIndex():int {
		if ( _pendingSelectionEndIndex >= 0 ) return _pendingSelectionEndIndex;
		if ( stageText ) return stageText.selectionActiveIndex;
		return 0;
	}

	public function get text():String {
		return _text;
	}

	public function set text( value:String ):void {
		if ( !value ) value = "";
		if ( _text == value ) return;
		_text = value;
		invalidate( INVALIDATE_DATA );
		dispatchEventWith( Event.CHANGE );
	}
}
}
