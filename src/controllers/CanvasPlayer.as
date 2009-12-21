package controllers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import models.events.*;
	import models.utils.Logger;
	
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
		
		public function setFileDispatcher(filePath:String, startSliderCallback:Function):void
		{
			dispatcher = new ReplayProcessor(filePath);
			dispatcher.addEventListener(HoneypotEvent.TYPE, onHoneypotEvent);
			dispatcher.addEventListener(DataProviderError.TYPE, errorHandler);
			
			// To start slider at the time replay starts
			(dispatcher as ReplayProcessor).sliderStartCallback = startSliderCallback;
		}
		
		/* just propagation */
		private function errorHandler(e:DataProviderError):void
		{
			dispatchEvent(new DataProviderError(e.kind, e.message));
		}
				
		public function start():void
		{
			if (dispatcher == null) {
				Logger.log("Dispatcher is not set");
				return;
			}
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
				case HoneypotEvent.FLUSH_ALL_BUFFERS:
					flushAllBuffers();
					break;
				default:
					Logger.log("Undefined type of HoneypotEvent");
					break;
			}
		}
		
		private function flushAllBuffers():void
		{
			manager.flushAllBuffers();
		}
		
		
		/* Replay only */
		public function seekByPercentage(percentage:Number):void
		{
			dispatcher.seekByPercentage(percentage);
		}
		
		/**
		 * shutting down clean up sockets and
		 */
		public function shutdown():void
		{
			Logger.log("shutting down player");
			if (dispatcher != null)
				dispatcher.shutdown();
			if (manager != null)
				manager.shutdown();
		}
	}
}