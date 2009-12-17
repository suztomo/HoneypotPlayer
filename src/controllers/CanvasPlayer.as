package controllers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import models.events.*;
	
	import mx.core.UIComponent;
	
	/*
		This class manages two components: CanvasManager and BlockProcessor.
		BlockProcessor generates events according to its input (network / recorded one).
		This class is responsible to handle the events and to give some feedback
		to view classes, that is, CanvasManager.
		A instance of this class is held by HoneypotViewerAction. 
		
		Usage:
		  cp = new CanvasPlayer(uicomp);
		  cp.setServerDispatcher("127.0.0.1", 8888);
		  cp.start();
	*/
	public class CanvasPlayer extends EventDispatcher
	{
		private var manager:CanvasManager;
		private var dispatcher:HoneypotEventDispatcher;
		
		public function CanvasPlayer(canvas:UIComponent)
		{
			manager = new CanvasManager(canvas);
		}
		
		public function setServerDispatcher(serverName:String, serverPort:uint):void {
			dispatcher = new BlockProcessor(serverName, serverPort);
			dispatcher.addEventListener(HoneypotEvent.TYPE, onHoneypotEvent);
			dispatcher.addEventListener(DataProviderError.TYPE, errorHandler);
		}
		
		public function setFileDispatcher(filePath:String):void
		{
			var replayer:ReplayProcessor = new ReplayProcessor(filePath);
		}
		
		/* just propagation */
		private function errorHandler(e:DataProviderError):void
		{
			dispatchEvent(new DataProviderError(e.kind, e.message));
		}
				
		public function start():void
		{
			dispatcher.run();
		}
		
		private function onProcessEvent(event:Event) :void
		{
		}

		private function onHoneypotEvent(ev:HoneypotEvent):void
		{
			var hostname:String;
			switch(ev.kind) {
				case HoneypotEvent.HOST_CREATED:
					hostname = ev.message.hostname;
					manager.createHost(hostname);
					break;
				case HoneypotEvent.HOST_DESTROYED:
					break;
				case HoneypotEvent.HOST_INVADED:
					break;
				case HoneypotEvent.HOST_TERM_INPUT:
					hostname = ev.message.hostname;
					var ttyname:String = ev.message.ttyname;
					var data:ByteArray = ev.message.ttyoutput;
					manager.sendTermInput(hostname, ttyname, data);
					break;
				default:
					trace("Undefined type of HoneypotEvent");
					break;
			}
		}
		
		/**
		 * shutting down clean up sockets and
		 */
		public function shutdown():void
		{
			trace("shutting down player");
			if (dispatcher != null)
				dispatcher.shutdown();
			if (manager != null)
				manager.shutdown();
		}
	}
}