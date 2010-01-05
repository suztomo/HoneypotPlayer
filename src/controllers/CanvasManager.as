package controllers
{
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import models.utils.Logger;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	import views.Host;
	
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
		private var _terminalPanelCanvas:Canvas;

		public var hostCount:uint = 0;
		public var R:Number = 300;
		public var centerX:Number = 400;
		public var centerY:Number = 300;
		public var gradScale:Number = 0.8;
		
		
		/*
			Class for reach a canvas to draw on.
			Mainly used for view classes.
			TerminalView.canvas will be the screen in CanvasPlayer(screen) 
			in HoneypotViewerAction.as 
		*/
		public function CanvasManager(s:Canvas, terminalPanelCanvas:Canvas)
		{
			screen = s;
			centerX = s.width / 2;
			centerY = s.height / 2;
			hosts = new Object();
			_lineScreen = new UIComponent();
			_hostScreen = new UIComponent();
			screen.addChild(_lineScreen); // lines in background
			screen.addChild(_hostScreen);
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
			var host:Host = new Host(hostname, _terminalPanelCanvas);
			hosts[hostname] = host;
			hostsArray.push(hostname);
			hostCount++;
			_hostScreen.addChild(host);
			alignHosts();
		}
		
		public function destroyHost(hostname:String):void
		{
			var host:Host = findHost(hostname);
			host.cease();
			_hostScreen.removeChild(host);
		}
		
		public function highlightHost(hostname:String):void
		{
			var host:Host = findHost(hostname);
			host.highlight();
		}
		
		public function sendTermInput(hostname:String, ttyname:String, data:ByteArray):void
		{
			var host:Host = findHost(hostname);
			host.writeTTY(ttyname, data);
		}
		
		/* Adds ip address information to the host
			How the host uses the address depends on Host class.
		 */
		public function sendNodeInfo(hostname:String, addr:String):void
		{
			Logger.log("Nodeinfo: " + hostname + " has " + addr + " / " + Object(this).constructor);
			var host:Host = findHost(hostname);
			host.addr = addr;
		}
		
		/* draws a line on screen */
		public function sendConnectInfo(from_host:String, to_host:String):void
		{
			drawLineBetweenHosts(from_host, to_host);
		}
		
		private function drawLineBetweenHosts(from_host:String, to_host:String):void
		{
			var h1:Host = findHost(from_host);
			var h2:Host = findHost(to_host);
			
			var l:UIComponent = new UIComponent();
			l.graphics.lineStyle(10, 0xFF1493, 1, false, LineScaleMode.VERTICAL,
                               CapsStyle.NONE, JointStyle.MITER, 10);
			l.graphics.moveTo(h1.x, h1.y);
			l.graphics.lineTo(h2.x, h2.y);
			trace(h1.x + "," + h2.y + " - " + h2.x + "," + h2.y);
			l.graphics.endFill();
			_lineScreen.addChild(l);
			var t:Timer = new Timer(3000, 1);
			t.addEventListener(TimerEvent.TIMER, function ():void {
				_lineScreen.removeChild(l);
			});
			t.start();
			Logger.log("drawd a line");
		}
		
		
		/*
			Finds host using its name.
			If the host does not exist, creates a host with the name.
		*/
		public function findHost(hostname:String):Host
		{
			var h:Host = hosts[hostname];
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
			var h:Host;
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
					h.moveWidthEffect(R * Math.cos(o * i) + centerX, R * Math.sin(o * i) + centerY);
					h.scale = gradScale * Math.sin(Math.PI / hostCount);
					i++;
				}
			}
		}
		
		public function flushAllBuffers():void
		{
			for each (var h:Host in hosts) {
				h.flushAllBuffers();
			}
		}
	}
}
