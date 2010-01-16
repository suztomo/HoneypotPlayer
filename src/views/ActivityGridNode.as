package views
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;

	public class ActivityGridNode extends UIComponent
	{
		public static var BACKGROUND_COLOR:uint = 0x32CD32;
		public static var HIGHLIGHT_COLOR:uint = 0x99FF00;
		
		public static var HIGHLIGHT_DELAY:Number = 100; // milliseconds 
		
		private var squareSize:Number = 100;
		
		private var _timer:Timer;
		
		private var _name:String;
		private var _addr:String;
		public function ActivityGridNode(name:String, addr:String = "NONE")
		{
			super();
			_timer = new Timer(HIGHLIGHT_DELAY, 1);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			this._name = name;
			this.width = this.height = squareSize;
			drawDefaultSquare();
		}
		
		public function drawDefaultSquare():void
		{
			drawSquare(BACKGROUND_COLOR);
		}
		
		private function onTimer(event:TimerEvent):void
		{
			drawDefaultSquare();
		}
		
		public function drawSquare(color:uint):void
		{
			graphics.beginFill(color);
			graphics.drawRect(-50, -50, 100, 100);
		}
		
		public function highLight():void
		{
			drawSquare(HIGHLIGHT_COLOR);
			if (_timer.running) {
				_timer.reset();
			}
			_timer.start();
			showName();
		}
		
		public function showName():void
		{
			
		}
	}
}