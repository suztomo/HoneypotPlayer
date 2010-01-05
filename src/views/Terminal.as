package views
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import mx.core.UIComponent;
	
	import org.partty.mxml.Terminal;

	/*
		This class is used to a data provider for mxml.Terminal
	*/
	public class Terminal extends UIComponent implements IDataInput
	{
		private var terminal:org.partty.mxml.Terminal;
		
		public var tty_name:String;
		private var bytes:ByteArray;
		public function Terminal(_tty_name:String)
		{
			terminal = new org.partty.mxml.Terminal();
			addChild(terminal);
			tty_name = _tty_name;

			terminal.dataProvider = this;
			bytes = new ByteArray();
			addEventListener(MouseEvent.CLICK, onClick);
		}
		
		public function writeBytes(src:ByteArray, offset:uint=0, length:uint=0) :void
		{
			bytes.writeBytes(src, offset, length);
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
		
		public function onClick(event:MouseEvent):void
		{
			putFront();	
		}
		
		public function putFront():void
		{
			this.parent.addChild(this);
		}

		public function set scale(x:Number):void
		{
			scaleX = scaleY = x;
		}
		
		public function clear():void
		{
			terminal.clear();
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