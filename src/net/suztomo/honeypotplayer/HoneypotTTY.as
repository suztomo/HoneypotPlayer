package net.suztomo.honeypotplayer
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
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
		public function writeBytes(_bytes:ByteArray, offset:uint=0, length:uint=0) :void
		{
			var sec:uint, msec:uint, size:uint;
			if (_bytes.bytesAvailable < 12) {
				trace("Wrong byte length " + String(_bytes.bytesAvailable) + " / HoneypotTTY.writeBytes()");
			}
			sec = _bytes.readUnsignedInt(); // unused
			msec = _bytes.readUnsignedInt(); // unused
			size = _bytes.readUnsignedInt();
			trace("sec " + String(sec) + ", msec " + String(msec) + ", ttydatasize " + String(size));
			if (_bytes.bytesAvailable != size) {
				trace("TTY bytes does not have equal length");
				return;
			}
			appendBytes(_bytes, 0, size);
			var ev:Event = new ProgressEvent(
				ProgressEvent.PROGRESS,
				false,
				false,
				bytes.bytesAvailable,
				bytes.length
			);
			dispatchEvent(ev);
		}
		
		private function appendBytes(_bytes:ByteArray, offset:uint = 0, length:uint=0) :void
		{
			var prev_position:uint = bytes.position;
			bytes.position += bytes.bytesAvailable;
			bytes.writeBytes(_bytes, offset, length);
			bytes.position = prev_position;	
			trace("appended : " + String(bytes.bytesAvailable));
			trace("readBytes() / HoneypotTTY (length, position, avail) " + String(bytes.length) + ", " + String(bytes.position) + ", " + String(bytes.bytesAvailable));
		}

		/*
			Readbytes is called from mxml.Terminal.
		*/
		public function readBytes(_bytes:ByteArray, offset:uint=0, length:uint=0):void
		{
			trace("readBytes() / HoneypotTTY (length, position, avail) " + String(bytes.length) + ", " + String(bytes.position) + ", " + String(bytes.bytesAvailable));
			return bytes.readBytes(_bytes, offset, length);
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