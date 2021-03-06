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
	[RemoteClass]
	public class HoneypotEventMessage
	{
		/* kind is enum written in  HoneypotEvent?*/
		public var kind: String;
		
		/* term input, host created, host destroyed, host invadd */
		public var hostname:String;

		/* term input */
		public var ttyname:String;
		public var ttyoutput: ByteArray;
		public var ttyoutput_saved_position:uint; /* used to file saving */
		
		/* term resize */
		public var cols:uint;
		public var rows:uint;
		
		/* hosts are connected */
		public var host1:String;
		public var host2:String;
		public var port:uint;	
		public var time:Number;
		public var percentage:Number = -1; // Created by ReplayProcessor.dispatchHoneypotEvent

		/* command name of root priviledges */
		public var command:String;

		/* syscall name */
		public var syscall:String;
		
		/* node information */
		public var addr:String;
		

		public function HoneypotEventMessage(k:String = "")
		{
			kind = k;
		}
		
		public function beforeSerialized():void
		{
			if (ttyoutput != null) {
				ttyoutput_saved_position = ttyoutput.position;
			}
		}
		
		public function afterDeserialized():void
		{
			if (ttyoutput != null) {
				ttyoutput.position = ttyoutput_saved_position;
			}
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
		
		public function buildRootPrivMessage(host:String, cmd:String = "unknown"):void
		{
			// any information?
			this.hostname = host;
			command = cmd; 
		}
		
		public function buildSyscallMessage(host:String, syscall:String):void
		{
			this.hostname = host;
			this.syscall = syscall;
		}
		
		public function buildNodeInfoMessage(host:String, addr:String):void
		{
			this.hostname = host;
			this.addr = addr;
		}
		
		public function buildConnectMessage(from_host:String, to_host:String, addr:String, port:uint):void
		{
			this.host1 = from_host;
			this.host2 = to_host;
			this.addr = addr;
			this.port = port;
		}
		
		public function buildTermResizeMessage(hostName:String, ttyName:String, cols:uint, rows:uint):void
		{
			this.hostname = hostName;
			this.ttyname = ttyName;
			this.cols = cols;
			this.rows = rows;
		}
		
		public function toString():String{
			return String("HoneypotEventMessage(kind=" + kind);
		}
	}
}