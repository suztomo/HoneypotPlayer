package controllers
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import models.*;
	import models.events.*;
	import models.network.Block;
	import models.network.HoneypotServer;
	import models.utils.Logger;


	/*
		The class processes the data block of the server 
		and records its abstract data inside the variable messages.
		The stored messages will be used to replay them.
		
		A instance of this class is hold by CanvasPlayer.
	*/
	public class BlockProcessor extends HoneypotEventDispatcher
	{
		private var _server:HoneypotServer;
		private var _machines:Object; // Map of (id => HoneypotMachine).
		private var _messages:Array;
		public static const MESSAGE_TTY_OUTPUT:uint = 1;
		public static const MESSAGE_ROOT_PRIV:uint = 2;
		public static const MESSAGE_SYSCALL:uint = 3;

		public static const HEADER_SIZEOF_SYSCALL_NAME:uint = 16;
		public static const HEADER_SIZEOF_HPNODE:uint = 4;
		public static const HEADER_SIZEOF_TTYNAME:uint = 7
		public static const HEADER_SIZEOF_SEC:uint = 4;
		public static const HEADER_SIZEOF_MSEC:uint = 4;
		public static const HEADER_SIZEOF_TTYDATASIZE:uint = 4;



		private var _recordTimeBase:Number;
		
		public function BlockProcessor(serverName:String, serverPort:uint)
		{
			_machines = new Object(); // assoc array
			_server = new HoneypotServer(serverName, serverPort);
			_server.addEventListener(ProgressEvent.PROGRESS, dataHandler);
			_server.addEventListener(DataProviderError.TYPE, errorHandler);
			_messages = new Array();
			_recordTimeBase = (new Date()).time;
			kind = super.REALTIME; // make difference when it start().
		}
		
		public override function run():void
		{
			_server.connect();
		}
		
		/* just propagation */
		private function errorHandler(e:DataProviderError):void
		{
			var h:DataProviderError = new DataProviderError(e.kind, e.message);
			dispatchEvent(h);
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
					case MESSAGE_ROOT_PRIV:
						processRootPriv(block);
						break;
					case MESSAGE_SYSCALL:
						processSyscall(block);
						break;
					default:
						trace("Undefined block type:" + kind +" /" + Object(this).constructor);
				}
			}
		}

		public function processRootPriv(block:Block):void
		{
			/* To record the events, just aligh this messages according to time */
			var host:String = "host23";
			var message:HoneypotEventMessage = new HoneypotEventMessage(
				HoneypotEvent.ROOT_PRIV
			);
			
			message.buildRootPrivMessage(host, "some command");
			recordMessage(message, (new Date()).time);
			var ev:HoneypotEvent = new HoneypotEvent(message.kind, message);
			dispatchEvent(ev);			
		}
	
	
		public function processSyscall(block:Block):void
		{
			/* To record the events, just aligh this messages according to time */
			var bytes:ByteArray = block.bytes;			
			if (bytes.bytesAvailable != HEADER_SIZEOF_HPNODE + HEADER_SIZEOF_SYSCALL_NAME) {
				Logger.log("invalid bytes available " + bytes.bytesAvailable + " / processSyscall");
				return;
			}
			var hp_node:uint = bytes.readUnsignedInt();
			var hostname:String = "host_" + String(hp_node);
			var syscall:String = bytes.readMultiByte(HEADER_SIZEOF_SYSCALL_NAME, "utf-8");
			var message:HoneypotEventMessage = new HoneypotEventMessage(
				HoneypotEvent.SYSCALL
			);
			trace("processing syscall:" + syscall);
			message.buildSyscallMessage(hostname, syscall);
			Logger.log(String(message));
			recordMessage(message, (new Date()).time);
			var ev:HoneypotEvent = new HoneypotEvent(message.kind, message);
			dispatchEvent(ev);
		}
		

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
				Logger.log("Too short bytes for ttydata");
				return;
			}
			
			hp_node = bytes.readUnsignedInt(); // hp_node
			var hostname:String = "host_" + String(hp_node);
			if (bytes.bytesAvailable < 7 + 4 + 4 + 4) {
				Logger.log("Wrong byte length " + String(bytes.bytesAvailable) + " / HoneypotMachine.writeBytesToTTY()");
				return;
			}
			var prev_position:uint = bytes.position;
			tty_name = bytes.readMultiByte(HEADER_SIZEOF_TTYNAME, "utf-8"); // tty_name
			
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
			if (sec > 1000 || msec > 1000000 || size > 5000) {
				trace("wrong: sec " + String(sec) + ", msec " + String(msec) + ", ttydatasize " + String(size));
			}
			if (bytes.bytesAvailable != size) {
				trace("TTY bytes(" + bytes.bytesAvailable + ") does not have equal length with size(" +
					size +")");
				return;
			}
			
			/* To record the events, just aligh this messages according to time */
			var message:HoneypotEventMessage = new HoneypotEventMessage(
				HoneypotEvent.HOST_TERM_INPUT
			);
			
			message.buildTermInputMessage(hostname, tty_name, bytes);
			recordMessage(message, (new Date()).time);
			var ev:HoneypotEvent = new HoneypotEvent(message.kind, message);
			dispatchEvent(ev);
		}
		
		public override function shutdown():void {
			saveRecordedMessages();
			_server.close(); // to save the data
		}
		
		/* Record the message to replay the messages afterwards */
		private function recordMessage(message:HoneypotEventMessage, msec:Number = -1):void
		{
			if (msec < 0) {
				msec = (new Date()).time;
			}
			message.time = msec - _recordTimeBase;
			_messages.push(message);
		}
		
		private function saveRecordedMessages():void
		{
			var logFile:File = File.documentsDirectory;
			logFile = logFile.resolvePath("honeypot.log");
			var fs:FileStream = new FileStream();
			fs.open(logFile, FileMode.WRITE);
			for each (var o:HoneypotEventMessage in _messages) {
				o.beforeSerialized();
				fs.writeObject(o);
			}
			fs.close();
			Logger.log("Saved: " + String(logFile.nativePath));
		}
		
		private function printBytes(bytes:ByteArray):void
		{
			var s:String = "";
			trace("Position / Length = " + String(bytes.position) + " / " + String(bytes.length) );
			var position:uint = bytes.position;
			for (var i:int=bytes.position; i<bytes.length; ++i) {
				var b:uint = bytes.readUnsignedByte();
				if (b <= 0xF)
					s += "0";
				s += b.toString(16) + "|";
			}
			bytes.position = position;
			trace(s);
		}

	}
}