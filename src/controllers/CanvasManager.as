package controllers
{
	import com.dncompute.graphics.GraphicsUtil;
	
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	import views.TerminalPanelView;
	import views.TerminalViewNode;
			
			
	
	/**
	 * This class manages TerminalViewer and objects on it,  e.g., views.Host class.
	 * CanvasPlayer receives some events from BlockProcessor and 
	 * sends feedbacks to this class, CanvasManager.
	 * Note that this Canvas manager itself is not Display Object, so it does not 
	 * have addChild nor removeChild in its methods.
	 * 
	 * Terminal class is managed by views.Host, so this class is not responsible
	 * to find nor send the terminal data directly to the class.
	 */
	public class CanvasManager
	{
		private var screen:UIComponent;
		private var hosts:Object;
		private var hostsArray:Array;
		private var _lineScreen:UIComponent;
		private var _hostScreen:UIComponent;
		private var _terminalPanelCanvas:TerminalPanelView;

		public var hostCount:uint = 0;
		public var R:Number = 300;
		public var centerX:Number = 400;
		public var centerY:Number = 300;
		public var gradScale:Number = 0.8;
		public static var LINE_COLOR:uint = 0xFF3300;
		public static var LINE_DELAY:Number = 2000; // milliseconds
		
		
		/*
			Class for reach a canvas to draw on.
			Mainly used for view classes.
			TerminalView.canvas will be the screen in CanvasPlayer(screen) 
			in HoneypotViewerAction.as 
		*/
		public function CanvasManager(s:Canvas, terminalPanelCanvas:TerminalPanelView)
		{
			screen = s;
			centerX = s.width / 2;
			centerY = s.height / 2;
			hosts = new Object();
			_lineScreen = new UIComponent();
			_hostScreen = new UIComponent();
			screen.addChild(_hostScreen);
			screen.addChild(_lineScreen);
			_terminalPanelCanvas = terminalPanelCanvas;
			
			hostsArray = new Array;
			
			/*
			    Foreground
			  -----------------
			     _terminalPanelCanvas
			     screen    |  hostScreen
			               |  lineScreen
			  ------------------
			    Background
			*/
		}
		
		public function createHost(hostname:String):void
		{
			var host:TerminalViewNode = new TerminalViewNode(hostname, _terminalPanelCanvas);
			hosts[hostname] = host;
			hostsArray.push(hostname);
			hostCount++;
			_hostScreen.addChild(host);
			alignHosts();
		}
		
		public function destroyHost(hostname:String):void
		{
			var host:TerminalViewNode = findHost(hostname);
			host.cease();
			_hostScreen.removeChild(host);
		}
		
		public function highlightHost(hostname:String):void
		{
			var host:TerminalViewNode = findHost(hostname);
			host.highlight();
		}
		
		public function sendTermInput(hostname:String, ttyname:String, data:ByteArray):void
		{
			var host:TerminalViewNode = findHost(hostname);
			host.writeTTY(ttyname, data);
		}
		
		public function resizeTerm(hostname:String, ttyname:String, cols:uint, rows:uint):void
		{
			var host:TerminalViewNode = findHost(hostname);
			host.resizeTerm(ttyname, cols, rows);
		}
		
		/* Adds ip address information to the host
			How the host uses the address depends on Host class.
		 */
		public function sendNodeInfo(hostname:String, addr:String):void
		{
			var host:TerminalViewNode = findHost(hostname);
			host.addr = addr;
		}
		
		/* draws a line on screen */
		public function sendConnectInfo(from_host:String, to_host:String):void
		{
			drawLineBetweenHosts(from_host, to_host);
		}
		
		private function drawLineBetweenHosts(from_host:String, to_host:String):void
		{
			var h1:TerminalViewNode = findHost(from_host);
			var h2:TerminalViewNode = findHost(to_host);
			drawLine(h1.x, h1.y, h2.x, h2.y);
		}
		
		
		/*
			Finds host using its name.
			If the host does not exist, creates a host with the name.
		*/
		public function findHost(hostname:String):TerminalViewNode
		{
			var h:TerminalViewNode = hosts[hostname];
			if (h == null) {
				/* Yasashisa */
				createHost(hostname);
				h = hosts[hostname];
			}
			return h;
		}
		
		public function shutdown():void
		{
			
		}
		
		public function alignHosts():void
		{
			var i:uint = 0;
			var h:TerminalViewNode;
			var hn:String;

			if (hostCount <= 1) { // one
				for each(h in hosts) {
					h.x = centerX;
					h.y = centerY;
					h.scale = 1.0;
				}
			} else if (hostCount == 2) { // two
				for each(h in hosts) {
					if (i == 0) {
						h.moveWidthEffect(centerX + R, centerY + 0);
					} else {
						h.moveWidthEffect(centerX - R, centerY + 0);
					}
					h.scale = 0.8;
					++i;
				}
			} else { // Three or more
				var o:Number = 2 * Math.PI / hostCount;
				for each (hn in hostsArray) {
					h = hosts[hn];
					h.move(R * Math.cos(o * i) + centerX, R * Math.sin(o * i) + centerY);
					h.scale = gradScale * R * Math.sin(Math.PI / hostCount) / 40.0;
					i++;
				}
			}
		}
		
		
		private function drawLine(fromX:Number, fromY:Number, toX:Number, toY:Number):void
		{
			var l:UIComponent = new UIComponent;
			l.graphics.lineStyle(10, LINE_COLOR, 1, false, LineScaleMode.VERTICAL,
								 CapsStyle.NONE, JointStyle.MITER, 10);
			l.graphics.beginFill(LINE_COLOR);
			GraphicsUtil.drawArrow(l.graphics,
				new Point(fromX, fromY),new Point(toX, toY),
				{shaftThickness:1,headWidth:14,headLength:12,
				shaftPosition:.16,edgeControlPosition:.60}
			);
		/*
			l.graphics.moveTo(fromX, fromY);
			l.graphics.lineTo(toX, toY);*/
			l.graphics.endFill();
			_lineScreen.addChild(l);
			var t:Timer = new Timer(LINE_DELAY, 1);
			t.addEventListener(TimerEvent.TIMER, function () :void{
				_lineScreen.removeChild(l);
			});
			t.start();
		}
		
		public function flushAllBuffers():void
		{
			for each (var h:TerminalViewNode in hosts) {
				h.flushAllBuffers();
			}
		}
	}
}
