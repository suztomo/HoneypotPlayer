package net.suztomo.honeypotplayer
{
	import flash.utils.ByteArray;
	
	public class HoneypotPlayerMaster
	{
		private var machines:Object; // Map of (id => HoneypotMachine).
		private const MESSAGE_TTY_OUTPUT:uint = 1;
		
		public function HoneypotPlayerMaster()
		{
			machines = new Object();
		}

		private function processBytes(bytes:ByteArray) :void {
			if (bytes.bytesAvailable < 1) {
				trace("Too short bytes for process bytes");
			} 
			var kind:uint = bytes.readUnsignedByte();
			switch(kind) {
				case 0:
					trace("case 0");
					break;
				case MESSAGE_TTY_OUTPUT:	
					trace("case 1");
					break;
				default:
					trace("Undefined block type");
			}
		}
		private function processTTYData(bytes:ByteArray) :void {	
			var hp_node:uint;
			var tty_output_bytes:ByteArray;
			if (bytes.bytesAvailable <= 23) {
				trace("Too short bytes for ttydata");
			}
			hp_node = bytes.readUnsignedInt();
			var m:HoneypotMachine = machines[hp_node];
			if (m) {
				m.writeBytes(bytes);
			} else {
				createMachine(hp_node);
			}
		}
		
		private function createMachine(hp_node:uint) :void{
			var m:HoneypotMachine = new HoneypotMachine(hp_node, String(hp_node));
			machines[hp_node] = m;
		}
	}
}