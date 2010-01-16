package views
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.effects.*;
	/**
	 *  Host class that represents host in view
	 *  Host has several terminals that represents tty inside its _terminalPanel. 
	 *  Host highlights itself if its controller (CanvasManager) orders to do so. 
	 */
	public class TerminalViewNode extends UIComponent
	{
		public var term:Terminal;
		public var terms:Object;
		public var hostname:String;
		public var zoomRatio:Number;
		public var addr:String;
		
		private var _terminalPanel:TerminalPanel;
		private var _terminalPanelCanvas:Canvas;
		
		private var _terminalCount:int = 0;
						
		public function TerminalViewNode(name:String, terminalPanelCanvas:Canvas = null)
		{
			hostname = name;
			super();
			terms = new Object();
			drawCircle();
			drawName();
			addEventListener("creationComplete", creationEffects);
/*
			addEventListener(MouseEvent.ROLL_OVER, onMouseOverEffects);
			addEventListener(MouseEvent.ROLL_OUT, onMouseOutEffects);
			*/
			addEventListener(MouseEvent.CLICK, onMouseClick);
			
			zoomRatio = 1.0;
			_terminalPanelCanvas = terminalPanelCanvas;
			_terminalPanel = new TerminalPanel();
			_terminalPanelCanvas.addChild(_terminalPanel);
			_terminalPanel.hostname = hostname;
		}
		
		public function creationEffects(e:Event):void
		{
			var creationEffects:Parallel;
			var fadeEffect:Fade;
			fadeEffect = new Fade(this);
			fadeEffect.alphaFrom = 0.0;
			fadeEffect.alphaTo = 1.0;
			fadeEffect.duration = 1000;
			
			creationEffects = new Parallel();
			creationEffects.addChild(fadeEffect);
			creationEffects.play();
		}
		
		public function onMouseOverEffects(e:Event):void
		{
			var ze:Zoom;
			ze = new Zoom(this);
			ze.zoomWidthFrom = ze.zoomHeightFrom = 1.0;
			ze.zoomHeightTo = ze.zoomWidthTo = 2.0;
			ze.duration = 350;
			ze.play();
		}
		
		public function onMouseOutEffects(e:Event):void
		{
			var ze:Zoom;
			ze = new Zoom(this);
			ze.zoomWidthFrom = ze.zoomHeightFrom = 2.0;
			ze.zoomHeightTo = ze.zoomWidthTo = 1.0;
			ze.duration = 350;
			ze.play();
		}
		
		public function onMouseClick(e:Event):void
		{
			showTerminalPanel();
		}
		
		public function moveWidthEffect(x:Number, y:Number):void
		{
			if (this.x == 0 && this.y == 0) {
				this.x = x;
				this.y = y;
				return;
			}
			var m:Move = new Move(this);
			m.xFrom = this.x;
			m.yFrom = this.y;
			m.xTo = x;
			m.yTo = y;
			m.duration = 1000;
			m.play();
			this.x = x;
			this.y = y;
		}
		
		public function writeTTY(ttyname:String, data:ByteArray):void
		{
			var t:Terminal = findTerminal(ttyname);
			t.writeBytes(data);
			_terminalPanel.flashTab(t);
		}
		
		public function showTerminalPanel():void
		{
			_terminalPanel.on();	
		}
		
		private function addTerminal(name:String):void
		{
			var t:Terminal = new Terminal(name);
			terms[name] = t;
			_terminalPanel.addTerminal(t);
			_terminalCount += 1;
			t.x = _terminalCount * 30;
			t.y = _terminalCount * 30;

//			t.scale = zoomRatio;
		}
		
		private function drawCircle():void
		{
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(0xFFCC00);
			circle.graphics.drawCircle(0, 0, 40);
			addChild(circle);
		}
		
		private function drawName():void
		{
			var t:TextField = new TextField();
			t.text = hostname;
			// set the contents before textformat
			var format:TextFormat = new TextFormat("Arial", 20, 0x0000000);
			t.setTextFormat(format);
			addChild(t);
		}
		
		/*
			Finds terminal using its name.
			If the terminal is not exist, this function creates and 
			registers it to terms dictionary.
		*/
		private function findTerminal(name:String):Terminal
		{
			var t:Terminal = terms[name];
			if (t == null) {
				addTerminal(name);
				t = terms[name];
			}
			return t;
		}
		
		public function set scale(s:Number):void
		{
			// scaleX = scaleY = s;
			for each(var t:Terminal in terms) {
				t.scale = s;
			}
			zoomRatio = s;
		}
		
		public function highlight():void
		{
			
		}
		
		public function cease():void
		{
			
		}
		
		public function flushAllBuffers():void
		{
			for each(var t:Terminal in terms) {
				t.clear();
			}
		}
	}
}