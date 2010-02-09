package views
{
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	import flash.display.*;
	
	import mx.core.UIComponent;
	import mx.core.UITextField;

	public class ActivityGridNode extends UIComponent
	{
		public static var BACKGROUND_COLOR:uint = 0x32CD32;
		public static var HIGHLIGHT_COLOR:uint = 0x99FF00;
		
		public static var HIGHLIGHT_DELAY:Number = 100; // milliseconds 
		
		private var squareSize:Number = 100;
		
		private var _timer:Timer;
		
		private var _name:String;
		private var _addr:String;
		
		private var _terminalPanelCanvas:TerminalPanelView;
		
		private var _infoTimer:Timer;
		private var _info:UIComponent;
		private var _infoCanvas:UIComponent;
		
		private var _gradMatrix:Matrix = new Matrix;
		private var _colors:Array = [0x32CD32, 0x52ED52];
		
		public function ActivityGridNode(name:String, addr:String,
										 terminalPanelCanvas:TerminalPanelView,
										 infoCanvas:UIComponent)
		{
			super();
			_timer = new Timer(HIGHLIGHT_DELAY, 1);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			addEventListener(MouseEvent.CLICK, onClick);
//			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseOver);
			_terminalPanelCanvas = terminalPanelCanvas;
			_infoCanvas = infoCanvas;
			_addr = addr;
			this._name = name;
			this.width = this.height = squareSize;
			drawDefaultSquare();
			prepareInfo();
		}
		
		public function drawDefaultSquare():void
		{
			drawSquare(BACKGROUND_COLOR);
		}
		
		private function onTimer(event:TimerEvent):void
		{
			drawDefaultSquare();
		}
		
		private function onClick(event:MouseEvent):void
		{
			TerminalPanelView.showPanel(_name);
//			_terminalPanelCanvas.showPanel(_name);
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			showInfo();
		}
		
		private function onMouseOver(event:MouseEvent):void
		{
			showInfo();
		}
		
		public function drawSquare(color:uint):void
		{
			//graphics.beginFill(color);
			_gradMatrix.createGradientBox(20, 20, 0, 0, 0);
			_colors[0] = color;
			_gradMatrix.rotate(Math.PI/6 + Math.PI);
			graphics.beginGradientFill(GradientType.LINEAR, _colors, [1.0, 1.0], [0, 255],
			 						   _gradMatrix);
			graphics.drawRoundRect(-50, -50, 100, 100, 10, 10);
			graphics.endFill();
		}
		
		public function highLight():void
		{
			drawSquare(HIGHLIGHT_COLOR);
			if (_timer.running) {
				_timer.reset();
			}
			_timer.start();
			showInfo();
		}
		
		public function set addr(value:String):void
		{
			_addr = value;
		}
		
		
		private function prepareInfo():void
		{
			var u:UIComponent = _info = new UIComponent;
			u.graphics.beginFill(0xFFFFCC, 0.9);
			u.graphics.drawRect(0, 0, 140, 45);
			u.graphics.endFill();
			var t:UITextField = new UITextField;
			t.width = 150;
			t.text = _name + "\n" + _addr;
			t.setStyle("fontSize", 16);
			t.setStyle("textColor", 0x111111); 
			u.addChild(t);
			_infoTimer = new Timer(1000, 1);
			_infoTimer.addEventListener(TimerEvent.TIMER, hideInfo);
		}
		private function hideInfo(event:TimerEvent):void
		{
			_infoCanvas.removeChild(_info);
		}
		
		public function showInfo():void
		{
			_info.x = x;
			_info.y = y;
			_infoCanvas.addChild(_info);
			_infoTimer.reset();
			_infoTimer.start();
		}
	}
}