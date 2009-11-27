package models.events
{
	import flash.utils.ByteArray;
	
	
	/**
	 * 
	 * Message class that will be send with HoneypotEvent
	 * The receiver of the event will see message attribute of it
	 * to get more information to give feedback to view manager.
	 * 
	 */
	public class HoneypotEventMessage
	{
		public var kind: String;
		public var sec: uint;
		public var msec: uint;
		public var bytes: ByteArray;

		public function HoneypotEventMessage(k:uint,s:uint, ms:uint, b:ByteArray)
		{
			var kind_options:Array = {
				HoneypotEvent.HOST_TERM_INPUT,
				HoneypotEvent.HOST_CREATED,
				HoneypotEvent.HOST_DESTROYED,
				HoneypotEvent.HOST_INVADED
			};
			if (k > kind_options.length) {
				kind = "error";
			}
			
			sec = s;
			msec = ms;
			bytes = b;
		}
	}
}