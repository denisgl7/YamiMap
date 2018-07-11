// =================================================================================================
//
//	Created by Rodrigo Lopez [roipeker™] on 03/02/2018.
//
// =================================================================================================

package core
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import roipeker.utils.MathUtils;
	
	import starling.display.Canvas;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.display.MeshBatch;
	import starling.display.Quad;
	import starling.filters.FragmentFilter;
	import starling.geom.Polygon;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import starling.utils.MeshSubset;
	
	public class BasicShape extends DisplayObjectContainer
	{
		private var _thickness:Number;
		private var _color:uint;
		private var _alpha:Number;
		
		private var _fromX:Number;
		private var _fromY:Number;
		private var _toX:Number;
		private var _toY:Number;
		
		private var _currenMesh:MeshBatch;
		private var _lineJoinCirc:Mesh;
		private var _numLineTo:int;
		private var _helperQuad:Quad;
		private var _circleResolution:int = -1;
		private var _lineTexture:Texture;
		
		public function BasicShape()
		{
			_thickness = 1;
			_color = 0x0;
			_alpha = 1;
			init();
		}
		
		private function init():void
		{
			
			circleResolution = 30;
			
			if (!_helperQuad) _helperQuad = new Quad(100, 100, 0x0);
			
			_lineJoinCirc = getCircMesh(4, 12);
		}
		
		private var _tileGrid:Rectangle = new Rectangle();
		
		public function lineStyleTexture(texture:Texture, thickness:Number = 1, color:uint = 0, alpha:Number = 1):void
		{
			lineStyle(thickness, color, alpha);
			_tileGrid.width = texture.width;
			_tileGrid.height = texture.height;
			if (texture.width > texture.height)
			{
				_offsetLineTextureRotation = Math.PI;
			} else
			{
				_offsetLineTextureRotation = Math.PI / 2 + Math.PI;
			}
			_lineTexture = texture;
		}
		
		public function lineStyle(thickness:Number = 1, color:uint = 0, alpha:Number = 1):void
		{
			_lineTexture = null;
			_lineMode = true;
			_thickness = thickness;
			_color = color;
			_alpha = alpha;
			
			_lineJoinCirc.width = _lineJoinCirc.height = thickness;
			_lineJoinCirc.color = _color;
			_lineJoinCirc.alpha = _alpha;
		}
		
		private var _fillColor:uint = 0x0;
		private var _fillAlpha:Number = 1;
		private var _fillMode:Boolean = false;
		private var _lineMode:Boolean = false;
		
		public var useCircleJoints:Boolean;
		
		public function endFill():void
		{
			_fillMode = false;
			_lineMode = false;
		}
		
		public function beginFill(color:uint = 0, alpha:Number = 1):void
		{
			_fillMode = true;
			_fillColor = color;
			_fillAlpha = alpha;
			_helperCircle.color = _fillColor;
			_helperCircle.alpha = _fillAlpha;
			_helperQuad.color = _fillColor;
			_helperQuad.alpha = _fillAlpha;
		}
		
		//    _helperCircle.color =
		
		public function moveTo(x:Number, y:Number):void
		{
			_fromX = x;
			_fromY = y;
			_numLineTo = 0;
		}
		
		private var _offsetLineTextureRotation:Number = 0;
		
		public function lineTo(x:Number, y:Number):void
		{
			_toX = x;
			_toY = y;
			
			
			
			if (_lineTexture)
			{
				var dx:Number = _toX - _fromX;
				var dy:Number = _toY - _fromY;
				var dist:Number = Math.sqrt(dx * dx + dy * dy);
				// create image and remove.
				var img:Image = new Image(_lineTexture);
				img.textureRepeat = true;
				img.color = _color;
				img.tileGrid = _tileGrid;
				img.readjustSize(_thickness, dist);
				if (_lineTexture.width >= _lineTexture.height)
				{
					img.pivotY = _thickness * 0.5;
				} else
				{
					img.pivotX = _thickness * 0.5;
				}
				img.x = _fromX;
				img.y = _fromY;
				img.rotation = _offsetLineTextureRotation + Math.atan2(dy, dx);
				trace("len is:", dist);
				addMesh(img, img.transformationMatrix, _alpha);
				img.dispose();
			} else
			{
				var fXOffset:Number = _toX - _fromX;
				var fYOffset:Number = _toY - _fromY;
				var len:Number = Math.sqrt(fXOffset * fXOffset + fYOffset * fYOffset);
				fXOffset = fXOffset * _thickness / (len * 2);
				fYOffset = fYOffset * _thickness / (len * 2);
				var quad:Quad = new Quad(2, 2, _color);
				quad.setVertexPosition(0, _toX + fYOffset, _toY - fXOffset);
				quad.setVertexPosition(1, _toX - fYOffset, _toY + fXOffset);
				quad.setVertexPosition(2, _fromX + fYOffset, _fromY - fXOffset);
				quad.setVertexPosition(3, _fromX - fYOffset, _fromY + fXOffset);
				addMesh(quad, quad.transformationMatrix, _alpha);
				quad.dispose();
			}
			
			// adds a circle joint.
			if (useCircleJoints)
			{
				_lineJoinCirc.x = _toX;
				_lineJoinCirc.y = _toY;
				addMesh(_lineJoinCirc, _lineJoinCirc.transformationMatrix, _alpha);
			}
			
			_fromX = x;
			_fromY = y;
			_numLineTo++;
		}
		
		private function addMesh(mesh:Mesh, matrix:Matrix, alpha:Number, subset:MeshSubset = null):void
		{
			if (_currenMesh && !_currenMesh.canAddMesh(mesh))
			{
				// create a new mesh.
				_currenMesh = null;
			}
			if (!_currenMesh)
			{
				_currenMesh = new MeshBatch();
				addChild(_currenMesh);
			}
			_currenMesh.addMesh(mesh, matrix, alpha, subset);
		}
		
		public function drawRect(x:Number, y:Number, w:Number, h:Number):void
		{
			if (_fillMode)
			{
				_helperQuad.color = _fillColor;
				_helperQuad.readjustSize(w, h);
				_helperQuad.x = x;
				_helperQuad.y = y;
				addMesh(_helperQuad, _helperQuad.transformationMatrix, _fillAlpha);
			}
			
			if (_lineMode)
			{
				moveTo(x, y);
				lineTo(x + w, y);
				lineTo(x + w, y + h);
				lineTo(x, y + h);
				lineTo(x, y);
			}
		}
		
		public function drawRoundRect(x:Number, y:Number, w:Number, h:Number, radius:Number = 0):void
		{
			var buffLine:Boolean = _lineMode;
			_lineMode = false;
			
			drawCircle(x + radius, y + radius, radius);
			drawCircle(x + radius, y + h - radius, radius);
			drawCircle(x + w - radius, y + radius, radius);
			drawCircle(x + w - radius, y + h - radius, radius);
			
			drawRect(x, y + radius, radius, h - radius * 2);
			drawRect(x + w - radius, y + radius, radius, h - radius * 2);
			drawRect(x + radius, y, w - radius * 2, h);
			
			// manual draw line.
			if (buffLine)
			{
				moveTo(x + radius, y);
				lineTo(x + w - radius, y);
				
				moveTo(x, y + radius);
				lineTo(x, y + h - radius);
				
				moveTo(x + w, y + radius);
				lineTo(x + w, y + h - radius);
				
				moveTo(x + radius, y + h);
				lineTo(x + w - radius, y + h);
				
				var torad:Function = MathUtils.deg2rad;
				drawPartialCirc(x + radius, y + radius, torad(270), torad(180), radius);
				drawPartialCirc(x + w - radius, y + radius, torad(-90), torad(0), radius);
				drawPartialCirc(x + w - radius, y + h - radius, torad(0), torad(90), radius);
				drawPartialCirc(x + radius, y + h - radius, torad(90), torad(180), radius);
			}
			_lineMode = buffLine;
		}
		
		private function drawPartialCirc(x:int, y:int, fromAngle:Number, toAngle:Number, radius:Number):void
		{
			var angle:Number = fromAngle;
			var angleDiff:Number = toAngle - fromAngle;
			var steps:int = Math.abs(angleDiff / (Math.PI * 2)) * _circleResolution;
			moveTo(x + Math.cos(angle) * radius,
					y + Math.sin(angle) * radius
			);
			for (var i:int = 1; i <= steps; i++)
			{
				angle = fromAngle + angleDiff / steps * i;
				var px:Number = Math.cos(angle) * radius;
				var py:Number = Math.sin(angle) * radius;
				lineTo(x + px, y + py);
			}
		}
		
		public function drawCircle(x:Number, y:Number, radius:Number):void
		{
			
			if (_fillMode)
			{
				_helperCircle.x = x;
				_helperCircle.y = y;
				_helperCircle.height = _helperCircle.width = radius * 2;
				addMesh(_helperCircle, _helperCircle.transformationMatrix, _alpha);
			}
			
			if (_lineMode)
			{
				// how many sides?
				var num:int = _circleResolution;
				var max:Number = Math.PI * 2;
				var step:Number = max / num;
				moveTo(x, y - radius);
				for (var i:int = 0; i <= num; i++)
				{
					var a:Number = i * step;
					var px:Number = Math.sin(a) * radius;
					var py:Number = -Math.cos(a) * radius;
					lineTo(x + px, y + py);
				}
			}
		}
		
		public function clear():void
		{
			_lineTexture = null;
			if (numChildren)
			{
				removeChildren(1, -1, true);
				_currenMesh = getChildAt(0) as MeshBatch;
				_currenMesh.clear();
			}
			_numLineTo = 0;
			_fromX = _fromY = _toX = _toY = 0;
			_color = 0x0;
			_alpha = 1;
			_numLineTo = 0;
		}
		
		public function get circleResolution():int
		{
			return _circleResolution;
		}
		
		private var _helperCircle:Mesh;
		
		public function set circleResolution(value:int):void
		{
			if (_circleResolution == value) return;
			_circleResolution = value;
			// RECREATE the circle.
			if (_helperCircle)
			{
				_helperCircle.dispose();
			}
			_helperCircle = getCircMesh(10, value);
		}
		
		private function getCircMesh(radius:Number, numSides:uint):Mesh
		{
			var polygon:Polygon = Polygon.createCircle(0, 0, radius, numSides);
			var vertexData:VertexData = new VertexData();
			var indexData:IndexData = new IndexData(polygon.numTriangles * 3);
			polygon.triangulate(indexData);
			polygon.copyToVertexData(vertexData);
			vertexData.colorize("color", 0x0, 1);
			return new Mesh(vertexData, indexData);
		}
		
		//===================================================================================================================================================
		//
		//      ------  TEXTURE UTILS
		//
		//===================================================================================================================================================
		
		//    private static var _antialiasFilter:FragmentFilter ;
		
		public static function createRectDotTexture(thickness:int, lineLength:int, separation:int = -1, color:uint = 0xfffffff, bufferCanvas:Canvas = null):Texture
		{
			var ff:FragmentFilter = new FragmentFilter();
			ff.antiAliasing = 4;
			
			// scale by 2.
			var canvas:Canvas;
			if (bufferCanvas)
			{
				bufferCanvas.clear();
				canvas = bufferCanvas;
			} else
			{
				canvas = new Canvas();
			}
			canvas.filter = ff;
			canvas.beginFill(color);
			canvas.drawRectangle(0, 0, thickness * 2, lineLength * 2);
			canvas.drawCircle(thickness, thickness + lineLength * 2 + separation, thickness);
			canvas.endFill();
			canvas.scale = .5;
			
			var rt:RenderTexture = new RenderTexture(thickness, lineLength + thickness + separation, false, 2);
			rt.draw(canvas);
			canvas.filter = null;
			ff.dispose();
			if (!bufferCanvas)
			{
				canvas.dispose();
			}
			return rt;
		}
		
		public static function createDotTexture(thickness:int, separation:int = -1, color:uint = 0xfffffff, bufferCanvas:Canvas = null):Texture
		{
			var ff:FragmentFilter = new FragmentFilter();
			ff.antiAliasing = 4;
			
			// scale by 2.
			var canvas:Canvas;
			if (bufferCanvas)
			{
				bufferCanvas.clear();
				canvas = bufferCanvas;
			} else
			{
				canvas = new Canvas();
			}
			canvas.filter = ff;
			canvas.beginFill(color);
			canvas.drawCircle(thickness, thickness, thickness);
			canvas.endFill();
			canvas.scale = .5;
			
			var rt:RenderTexture = new RenderTexture(thickness, thickness + separation, false, 2);
			rt.draw(canvas);
			canvas.filter = null;
			ff.dispose();
			if (!bufferCanvas)
			{
				canvas.dispose();
			}
			return rt;
		}
		
		public static function createRectLineTexture(length1:int, length2:int = -1, color:uint = 0xfffffff):Texture
		{
			var q:Quad = new Quad(4, length1, color);
			if (length2 < 1) length2 = length1;
			var rt:RenderTexture = new RenderTexture(4, length1 + length2, true, 1);
			rt.draw(q);
			q.dispose();
			return rt;
		}
	}
}
