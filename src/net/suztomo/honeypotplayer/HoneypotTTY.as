package net.suztomo.honeypotplayer
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.Endian;
	
	import mx.core.UIComponent;
	
	import org.partty.mxml.Terminal;

	/*
		This class is used to a data provider for mxml.Terminal
	*/
	public class HoneypotTTY extends UIComponent implements IDataInput
	{
		private var terminal:Terminal;
		
		public var tty_name:String;
		private var bytes:ByteArray;
		public static var count:int = 0;
		public function HoneypotTTY(_tty_name:String)
		{
			terminal = new Terminal();
			addChild(terminal);
			tty_name = _tty_name;

			terminal.dataProvider = this;
			bytes = new ByteArray();
			trace(String(count) + ": terminal "+tty_name+ " is created");
			x = count * 30;
			y = count * 30;
			count++;			
		}

		/*
			WriteBytes assumes following byte stream:
			
			|  sec  | msec  | size  |  buffer data
			|   4   |   4   |   4   |  ...
			
			The endian of the bytes should be properly set before the call.
		*/
		public function writeBytes(src:ByteArray, offset:uint=0, length:uint=0) :void
		{
			var sec:uint, msec:uint, size:uint;
			if (src.bytesAvailable < 12) {
				trace("Wrong byte length " + String(src.bytesAvailable) + " / HoneypotTTY.writeBytes()");
			}
			sec = src.readUnsignedInt(); // unused
			msec = src.readUnsignedInt(); // unused
			size = src.readUnsignedInt();
			if (sec > 1000 || msec > 1000 || size > 1000) {
				trace("sec " + String(sec) + ", msec " + String(msec) + ", ttydatasize " + String(size));
			}
			if (src.bytesAvailable != size) {
				trace("TTY bytes does not have equal length");
				return;
			}
			appendBytes(src);
			var ev:Event = new ProgressEvent(
				ProgressEvent.PROGRESS,
				false,
				false,
				bytes.bytesAvailable,
				bytes.length
			);
			dispatchEvent(ev);
		}
		
		private function appendBytes(src:ByteArray) :void
		{
			var prev_position:uint = bytes.position;
						bytes.position += bytes.bytesAvailable;
			bytes.writeBytes(src, src.position, src.bytesAvailable);
			bytes.position = prev_position;	
		}

		/*
			Readbytes is called from mxml.Terminal.
		*/
		public function readBytes(dest:ByteArray, offset:uint=0, length:uint=0):void
		{
			return bytes.readBytes(dest, offset, length);
		}
		
		public function readBoolean():Boolean
		{
			return bytes.readBoolean();
		}
		
		public function readByte():int
		{
			return bytes.readByte();
		}
		
		public function readUnsignedByte():uint
		{
			return bytes.readUnsignedByte();
		}
		
		public function readShort():int
		{
			return bytes.readShort();
		}
		
		public function readUnsignedShort():uint
		{
			return bytes.readUnsignedShort();
		}
		
		public function readInt():int
		{
			return bytes.readInt();
		}
		
		public function readUnsignedInt():uint
		{
			return bytes.readUnsignedInt();
		}
		
		public function readFloat():Number
		{
			return bytes.readFloat();
		}
		
		public function readDouble():Number
		{
			return bytes.readDouble();
		}
		
		public function readMultiByte(length:uint, charSet:String):String
		{
			return bytes.readMultiByte(length, charSet);
		}
		
		public function readUTF():String
		{
			return bytes.readUTF();
		}
		
		public function readUTFBytes(length:uint):String
		{
			return bytes.readUTFBytes(length);
		}
		
		public function get bytesAvailable():uint
		{
			return bytes.bytesAvailable;
		}
		
		public function readObject(): *
		{
			return bytes.readObject();
		}
		
		public function get objectEncoding():uint
		{
			return bytes.objectEncoding;
		}
		
		public function set objectEncoding(version:uint):void
		{
			bytes.objectEncoding = version;
		}
		
		public function get endian():String
		{
			return bytes.endian;
		}
		
		public function set endian(type:String):void
		{
			bytes.endian = type;
		}
	}
}