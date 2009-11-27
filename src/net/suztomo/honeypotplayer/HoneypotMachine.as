package net.suztomo.honeypotplayer
{
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;

	public class HoneypotMachine extends UIComponent
	{
		public var hp_node:uint;
		public var hp_name:String;		
		private var ttys:Object;
		public function HoneypotMachine(_id:uint, _name:String)
		{
			hp_node = _id;
			hp_name = _name;
			trace("Machine " + hp_name + " is created");
			ttys = new Object();
		}

		/*
			writeBytes assumes following byte stream
			
			| tty_name  |   sec  |  msec  |  size  |  tty_data ...
			|    7      |    4   |    4   |    4   |    ....
			
			The endian of the bytes should be properly set before this call
		*/
		public function writeBytesToTTY(bytes:ByteArray, offset:uint=0, length:uint=0):void
		{
			var tty_name:String;
			if (bytes.bytesAvailable < 7 + 4 + 4 + 4) {
				trace("Wrong byte length " + String(bytes.bytesAvailable) + " / HoneypotMachine.writeBytesToTTY()");
				return;
			}
			var prev_position:uint = bytes.position;
			tty_name = bytes.readMultiByte(7, "utf-8");
			
			/*
				Only pseudo terminal slave, not master.
			*/
			if (tty_name.substr(0, 3) != "pts") {
				return;
			}
			var t:HoneypotTTY = ttys[tty_name];
			if (!t) {
				t = createTTY(tty_name);
			}
			t.writeBytes(bytes);
		}
				
		private function createTTY(tty_name:String) :HoneypotTTY {
			var t:HoneypotTTY = new HoneypotTTY(tty_name);
			trace(tty_name + "/" + hp_name + " is created");
			ttys[tty_name] = t;
			addChild(t);
			return t;
		}
	}
}