package controllers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import models.events.*;
	import models.utils.Logger;
	
	import views.TerminalView;
	import views.TerminalPanelView;
	
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
		private var _dispatcher:HoneypotEventDispatcher;
		private var _activityChartManager:ActivityChartManager;
		private var _total:Number = -1;
		
		public function get dispatcher():HoneypotEventDispatcher
		{
			return _dispatcher;
		}
				
		public function CanvasPlayer(terminalView:TerminalView)
		{
			manager = new CanvasManager(terminalView.canvas, terminalView.terminalPanelCanvas);
		}

		public function addActivityChartManager(activityChartManager:ActivityChartManager):void
		{
			_activityChartManager = activityChartManager;
			if (_dispatcher == null) {
				Logger.log("Invalid call sequence / " + Object(this).constructor);
			}
			/* 
			  ReplayProcessor knows whole activity message and sends to the chart
			*/
			if (_dispatcher.kind == HoneypotEventDispatcher.REPLAY) {
				
				(_dispatcher as ReplayProcessor).prepareActivityChart(_activityChartManager);
			}
		}
		
		public function stopReplayTimer(e:Event):void
		{
			(_dispatcher as ReplayProcessor).stopTimer();
		}
		
		public function startReplayTimer(e:Event):void
		{
			(_dispatcher as ReplayProcessor).startTimer();
		}
		
		public function setServerDispatcher(serverName:String, serverPort:uint):void {
			_dispatcher = new BlockProcessor(serverName, serverPort);
			_dispatcher.addEventListener(HoneypotEvent.TYPE, onHoneypotEvent);
			_dispatcher.addEventListener(DataProviderError.TYPE, errorHandler);
		}
		
		public function setFileDispatcher(filePath:String, startSliderCallback:Function):void
		{
			_dispatcher = new ReplayProcessor(filePath);
			_dispatcher.addEventListener(HoneypotEvent.TYPE, onHoneypotEvent);
			_dispatcher.addEventListener(DataProviderError.TYPE, errorHandler);
			
			/*
				To start slider at the time replay starts
				because the slider does not know total time.
			*/
			(_dispatcher as ReplayProcessor).sliderStartCallback = startSliderCallback;
		}
		
		/* just propagation */
		private function errorHandler(e:DataProviderError):void
		{
			dispatchEvent(new DataProviderError(e.kind, e.message));
		}

		public function start():void
		{
			if (_dispatcher == null) {
				Logger.log("Dispatcher is not set");
				return;
			}
			_dispatcher.run();
		}
		
		public function get total():Number
		{
			if (_total >= 0) return _total;
			// this call can be called after this.setFileDispatcher in HoneypotViewerAction.as
			return (_total = (_dispatcher as ReplayProcessor).total);
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
				case HoneypotEvent.SYSCALL:
					if (_dispatcher.kind == HoneypotEventDispatcher.REALTIME)
						_activityChartManager.put(ev.message);
					break;
				case HoneypotEvent.NODE_INFO:
					hostname = ev.message.hostname;
					var addr:String = ev.message.addr;
					manager.sendNodeInfo(hostname, addr);
					break;
				case HoneypotEvent.CONNECT:
					var from_host:String = ev.message.host1;
					var to_host:String = ev.message.host2;
					manager.sendConnectInfo(from_host, to_host);
					break;
				default:
					Logger.log("Undefined type of HoneypotEvent / " + String(Object(this).constructor));
					break;
			}
		}
		
		private function flushAllBuffers():void
		{
			manager.flushAllBuffers();
		}
		
		
		/* Replay only 
		   called by HOneypotViewerAction sliderSeekHandler, on SliderChange */
		public function seekByPercentage(percentage:Number):void
		{
			_dispatcher.seekByPercentage(percentage);
			_activityChartManager.seekByTime(this.total * percentage / 100);
		}
		
		
		/**
		 * shutting down clean up sockets and
		 */
		public function shutdown():void
		{
			Logger.log("shutting down player");
			if (_dispatcher != null)
				_dispatcher.shutdown();
			if (manager != null)
				manager.shutdown();
		}
	}
}