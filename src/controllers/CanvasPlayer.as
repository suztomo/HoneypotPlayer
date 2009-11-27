package controllers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	/*
		This class manages two components: CanvasManager and BlockProcessor.
		BlockProcessor generates events according to its input (network / recorded one).
		This class is responsible to handle the events and to give some feedback
		to view classes, that is, CanvasManager.
	*/
	public class CanvasPlayer
	{
		private var manager:CanvasManager;
		private var processor:EventDispatcher;
		
		public function CanvasPlayer()
		{
			manager = new CanvasManager();
			processor = new BlockProcessor();
		}
		
		private function onProcessEvent(event:Event)
		{
			trace("onProcessEvent / CanvasPlayer");
			trace(event);
		}

	}
}