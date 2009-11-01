package net.suztomo.honeypotplayer
{
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;

	public class HoneypotMachine extends UIComponent
	{
		public var hp_node:uint;
		public var hp_name:String;
		public var bytes:ByteArray;
		
		private var ttys:Object;
		public function HoneypotMachine(_id:uint, _name:String)
		{
			hp_node = _id;
			hp_name = _name;
			bytes = new ByteArray();
			ttys = new Object();
		}

		public function writeBytes(_bytes:ByteArray, offset:uint=0, length:uint=0):void
		{
			var tty_name:String;
			bytes.writeBytes(_bytes, offset, length);
			tty_name = bytes.readMultiByte(7, "utf-8");
			var t:HoneypotTTY = ttys[tty_name];
			
			if (t) {
				t.writeBytes(bytes);
			} else {
				createTTY(tty_name);
			}		
		}
		
		private function createTTY(tty_name:String) :void {
			var t:HoneypotTTY = new HoneypotTTY(tty_name);
		}
	}
}