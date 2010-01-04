package controllers
{
	import flash.events.EventDispatcher;

	/*
	 * Abstract class that dispatches HoneypotEvent
	 * This class is to provide same interfaces among server's events
	 * and replayer's events.
	 */
	public class HoneypotEventDispatcher extends EventDispatcher
	{
		public var kind:String;
		public static const REPLAY:String = "Replay";
		public static const REALTIME:String = "Realtime";
		public function HoneypotEventDispatcher():void
		{
			super(null);
			if (Object(this).constructor == HoneypotEventDispatcher) {
				throw new Error("This class is abstract class!");
			}
		}
		
		public function run():void
		{
			trace("abstract run!");
		}
		
		public function shutdown():void
		{
			trace("abstract shutting down!");	
		}
		
		public function seekByPercentage(percentage:Number):void
		{
			trace("abstract seekByPercentage");
		}
	}
}
