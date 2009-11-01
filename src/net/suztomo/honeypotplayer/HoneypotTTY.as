package net.suztomo.honeypotplayer
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import mx.core.UIComponent;
	
	import org.partty.mxml.Terminal;

	public class HoneypotTTY extends UIComponent implements IDataInput
	{
		private var terminal:Terminal;
		
		public var tty_name:String;
		private var bytes:ByteArray;
		public function HoneypotTTY(_tty_name:String)
		{
			terminal = new Terminal();
			tty_name = _tty_name;
			addChild(terminal);
			terminal.dataProvider = this;
			bytes = new ByteArray();
		}
		
		public function writeBytes(_bytes:ByteArray, offset:uint=0, length:uint=0) :void
		{
			bytes.writeBytes(_bytes, offset, length);
			var sec:uint, msec:uint, size:uint;
			sec = bytes.readUnsignedInt();
			msec = bytes.readUnsignedInt();
			size = bytes.readUnsignedInt();
			dispatchEvent(new Event(ProgressEvent.PROGRESS));
		}

		public function readBytes(bytes:ByteArray, offset:uint=0, length:uint=0):void
		{
			return bytes.readBytes(bytes, offset, length);
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