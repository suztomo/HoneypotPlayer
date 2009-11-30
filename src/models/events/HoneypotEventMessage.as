package models.events
{
	import flash.utils.ByteArray;
	
	
	/**
	 * 
	 * Message class that will be send with HoneypotEvent
	 * The receiver of the event will see message attribute of it
	 * to get more information to give feedback to view manager.
	 * 
	 * The attributes of this class may not be used to a message.
	 * e.g. HOST_TERM_INPUT message doesn't use hostname
	 * 
	 */
	public class HoneypotEventMessage
	{
		public var kind: String;
		
		/* term input, host created, host destroyed, host invadd */
		public var hostname:String;

		/* term input */
		public var ttyname:String;
		public var ttyoutput: ByteArray;
		
		/* hosts are connected */
		public var host1:String;
		public var host2:String;
		public var weight:uint;
		

		public function HoneypotEventMessage(k:String)
		{
			kind = k;	
		}
		
		public function buildTermInputMessage(h:String, t:String, b:ByteArray):void
		{
			hostname = h;
			ttyname = t;
			ttyoutput = b;
		}
		
		public function setHost(h:String):void
		{
			hostname = h;
		}
		
		public function buildConnectionMessage(h1:String, h2:String, w:uint = 1):void
		{
			weight = w;
			host1 = h1;
			host2 = h2;
		}
	}
}