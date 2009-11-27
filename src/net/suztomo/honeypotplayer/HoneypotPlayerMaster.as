package net.suztomo.honeypotplayer
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import mx.core.UIComponent;
	
	public class HoneypotPlayerMaster extends UIComponent
	{
		private var machines:Object; // Map of (id => HoneypotMachine).
		private const MESSAGE_TTY_OUTPUT:uint = 1;
		private var _dataProvider:Object;
		private var ttyserver:TTYServer;
		private var bytes:ByteArray;
		
		public function HoneypotPlayerMaster()
		{
			machines = new Object();
			bytes = new ByteArray();
			ttyserver = new TTYServer("192.168.124.188", 8080);
//			ttyserver = new TTYServer("127.0.0.1", 8081);
			ttyserver.connect();
			addDataProvider(ttyserver);
		}
		
		public function addDataProvider(dp:Object) :void {
			if(_dataProvider) {
				_dataProvider.removeEventListner(
							ProgressEvent.PROGRESS, dataHandler);
			}
			dp.addEventListener(ProgressEvent.PROGRESS, dataHandler);
			_dataProvider = dp;
		}
		
		private function dataHandler(event:Event) :void{
			event.target.readAllBytes(bytes);
			bytes.position = 0;
			processBytes(bytes);
			bytes.clear();
		}
		
		public function set dataProvider(dp:Object):void {
			_dataProvider = dp;
		}
		
		public function get dataProvider():Object {
			return _dataProvider;
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
				switch(kind) {
					case 0:
						break;
					case MESSAGE_TTY_OUTPUT:	
						processTTYData(copied_bytes);
						break;
					default:
						trace("Undefined block type");
				}
			}
		}
		
		/*
			processTTYData assumes following header:
			  | hp_node | tty_name |  sec   |  msec  | ...
			  |    4    |   7      |   4    |   4    | ...
		*/
		public const HEADER_SIZEOF_HPNODE:uint = 4;
		public const HEADER_SIZEOF_TTYNAME:uint = 7
		public const HEADER_SIZEOF_SEC:uint = 4;
		public const HEADER_SIZEOF_MSEC:uint = 4;
		public const HEADER_SIZEOF_TTYDATASIZE:uint = 4;

		/*
			Processes the tty data to HoneypotMachine.
			The bytes should be properly set.
		*/
		private function processTTYData(bytes:ByteArray) :void {	
			var hp_node:uint;
			var tty_output_bytes:ByteArray;
			if (bytes.bytesAvailable <= HEADER_SIZEOF_HPNODE + HEADER_SIZEOF_TTYNAME
				+ HEADER_SIZEOF_SEC + HEADER_SIZEOF_MSEC + HEADER_SIZEOF_TTYDATASIZE) {
				trace("Too short bytes for ttydata");
				return;
			}
			
			hp_node = bytes.readUnsignedInt();
			var m:HoneypotMachine = machines[hp_node];
			if (!m) {
				m = createMachine(hp_node);
			}
			/*
				The endian of the bytes should be properly set.
			*/
			m.writeBytesToTTY(bytes);
		}
		
		private function createMachine(hp_node:uint) :HoneypotMachine{
			var m:HoneypotMachine = new HoneypotMachine(hp_node, String(hp_node));
			machines[hp_node] = m;
			addChild(m);
			return m;
		}
		
		public function shutdown():void {
			ttyserver.close();
		}
	}
}