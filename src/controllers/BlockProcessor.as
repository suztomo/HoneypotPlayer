package controllers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import models.*;
	import models.events.*;
	import models.network.Block;
	import models.network.HoneypotServer;

	public class BlockProcessor extends HoneypotEventDispatcher
	{
		private var server:HoneypotServer;
		private var machines:Object; // Map of (id => HoneypotMachine).
		private var messages:Array;
		public const MESSAGE_TTY_OUTPUT:uint = 1;
		
		public function BlockProcessor(serverName:String, serverPort:uint)
		{
			machines = new Object(); // assoc array
			server = new HoneypotServer(serverName, serverPort);
			server.addEventListener(ProgressEvent.PROGRESS, dataHandler);
			messages = new Array();
		}
		
		public override function run():void
		{
			server.connect();
		}

		private function dataHandler(event:Event) :void{
			var bytes:ByteArray = new ByteArray();
			event.target.readAllBytes(bytes);
			bytes.position = 0;
			processBytes(bytes);
			bytes.clear();
		}

		/*
			ProcessBytes assumes following header:
			  |kind|  size  |  data
			  | 1  |   4    | ....
		*/
		
		public const HEADER_SIZEOF_KIND:uint = 1;
		public const HEADER_SIZEOF_SIZE:uint = 4;
		private function processBytes(bytes:ByteArray) :void {
			while (bytes.bytesAvailable > 0) {
				if (bytes.bytesAvailable < HEADER_SIZEOF_KIND
					+ HEADER_SIZEOF_SIZE) {
					trace("Too short bytes for process bytes bytesAvailable is "
						+ String(bytes.bytesAvailable));
					break;
				}
				bytes.endian = 	Endian.LITTLE_ENDIAN;
				var kind:uint = bytes.readUnsignedByte();
				var size:uint = bytes.readUnsignedInt();

				if (bytes.bytesAvailable < size) {
					trace("wrong size header / HoneypotPlayerMaster.processBytes");
					break;
				}
				var copied_bytes:ByteArray = new ByteArray;
					
				//  The endian lives until  HoneypotTTY.writeBytes()
				copied_bytes.endian = Endian.LITTLE_ENDIAN;
				bytes.readBytes(copied_bytes, 0, size);
				copied_bytes.position = 0;
				var block:Block = new Block(kind, copied_bytes);

				switch(kind) {
					case 0:
						break;
					case MESSAGE_TTY_OUTPUT:
						processTTYData(block);
						break;
					default:
						trace("Undefined block type");
				}
			}
		}


		public const HEADER_SIZEOF_HPNODE:uint = 4;
		public const HEADER_SIZEOF_TTYNAME:uint = 7
		public const HEADER_SIZEOF_SEC:uint = 4;
		public const HEADER_SIZEOF_MSEC:uint = 4;
		public const HEADER_SIZEOF_TTYDATASIZE:uint = 4;

		/*
			Processes the tty data to HoneypotMachine.
			The bytes should be properly set.

			processTTYData assumes following header:
			  | hp_node | tty_name |  sec   |  msec  |  size  |...
			  |    4    |   7      |   4    |   4    |   4    |...
		*/
		private function processTTYData(block:Block) :void {
			var bytes:ByteArray = block.bytes;	
			var hp_node:uint;
			var tty_name:String;
			var sec:uint, msec:uint, size:uint;

			if (bytes.bytesAvailable <= HEADER_SIZEOF_HPNODE + HEADER_SIZEOF_TTYNAME
				+ HEADER_SIZEOF_SEC + HEADER_SIZEOF_MSEC + HEADER_SIZEOF_TTYDATASIZE) {
				trace("Too short bytes for ttydata");
				return;
			}
			
			hp_node = bytes.readUnsignedInt(); // hp_node
			var hostname:String = "host_" + String(hp_node);
			
			if (bytes.bytesAvailable < 7 + 4 + 4 + 4) {
				trace("Wrong byte length " + String(bytes.bytesAvailable) + " / HoneypotMachine.writeBytesToTTY()");
				return;
			}
			var prev_position:uint = bytes.position;
			tty_name = bytes.readMultiByte(7, "utf-8"); // tty_name
			
			/*
				Only pseudo terminal slave, not master.
			*/
			if (tty_name.substr(0, 3) != "pts") {
				return;
			} else {
				
			}

			if (bytes.bytesAvailable < 4 + 4 + 4) {
				trace("Wrong byte length " + String(bytes.bytesAvailable) + " / HoneypotTTY.writeBytes()");
			}
			sec = bytes.readUnsignedInt(); // unused
			msec = bytes.readUnsignedInt(); // unused
			size = bytes.readUnsignedInt(); 
			if (sec > 1000 || msec > 1000 || size > 1000) {
				trace("sec " + String(sec) + ", msec " + String(msec) + ", ttydatasize " + String(size));
			}
			if (bytes.bytesAvailable != size) {
				trace("TTY bytes does not have equal length");
				return;
			}
			
			/* To record the events, just aligh this messages according to time */
			var message:HoneypotEventMessage = new HoneypotEventMessage(
				HoneypotEvent.HOST_TERM_INPUT
			);
			
			message.buildTermInputMessage(hostname, tty_name, bytes);
			
			var ev:HoneypotEvent = new HoneypotEvent(HoneypotEvent.HOST_TERM_INPUT, message);
			dispatchEvent(ev);
		}
		
		public override function shutdown():void {
			server.close();
		}
		
		/* Record the message to replay the messages afterwards */
		private function recordMessage(sec:uint, msec:uint, message:HoneypotEventMessage):void
		{
			messages.push(message);
			return;
		}
	}
}