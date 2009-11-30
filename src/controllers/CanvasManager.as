package controllers
{
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	
	import views.Host;
	
	/**
	 * This class manages screen and objects on it,  e.g., views.Host class.
	 * CanvasPlayer receives some events from BlockProcessor and 
	 * sends feedbacks to this class, CanvasManager.
	 * Note that this Canvas manager itself is not Display Object, so it does not 
	 * have addChild nor removeChild in its methods.
	 * 
	 * Terminal class is managed by views.Host, so this class is not responsible
	 * to find nor send the terminal data to that class.
	 */
	public class CanvasManager
	{
		private var screen:UIComponent;
		private var hosts:Object;
		/*
			Class for reach a canvas to draw on.
			Mainly used for view classes.
		*/
		public function CanvasManager(s:UIComponent)
		{
			screen = s;
			hosts = new Object();
		}
		
		public function createHost(hostname:String):void
		{
			var host:Host = new Host(hostname);
			hosts[hostname] = host;
			screen.addChild(host);
		}
		
		public function destroyHost(hostname:String):void
		{
			var host:Host = findHost(hostname);
			host.cease();
			screen.removeChild(host);
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
		
		public function findHost(hostname:String):Host
		{
			var h:Host = hosts[hostname];
			if (h is null) {
				return null;
			}
			return h;
		}
		
		public function shutdown():void
		{
			
		}
	}
}