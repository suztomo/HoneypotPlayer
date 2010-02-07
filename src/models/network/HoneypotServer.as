package models.network
{
	import flash.events.*;
	import flash.filesystem.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import models.events.DataProviderError;
	import models.utils.Logger;
	
	/*
		This class represents a honeypot server that sends 
		its information about attackers; tty data etc.
		An instance of this class is held by BlockProcessor.
	*/
	public class HoneypotServer extends EventDispatcher
	{
		private var _serverName:String = "127.0.0.1";
		private var _serverPort:int = 8081;
		private var _isConnected:Boolean = false;
		private var _socket:Socket;
		private var bytes:ByteArray;
		private var block_cursor:uint = 0;
		private var receivedBytes:ByteArray;
		
		public function HoneypotServer(serverName:String, serverPort:int = 8081)
		{
			_serverName = serverName;
			_serverPort = serverPort;
			_socket = new Socket();
			prepareEvents();
			bytes = new ByteArray();
			receivedBytes = new ByteArray();
		}
		public function connect():void
		{
			Logger.log("connecting...");
			if (connected()) {
				Logger.log("Already connected");
			}
			_socket.connect(_serverName, _serverPort);
			Logger.log("connected!");
		}

		public function connected():Boolean
		{
			return _socket && _socket.connected;
		}
		
		private function onConnect(event:Event):void
		{
			sendAck();
		}
		
		private function onDataArrived(event:ProgressEvent):void
		{
			var bytes:ByteArray = new ByteArray();
			_socket.readBytes(bytes);
			bytes.readBytes(receivedBytes);
//			receivedBytes.writeBytes(bytes);
			processData(bytes);
			sendAck();
		}

		private function sendAck():void
		{
			_socket.writeUTFBytes("ok");
		}

		private function printBytes(bytes:ByteArray):void
		{
			var s:String = "";
			trace("Position / Length = " + String(bytes.position) + " / " + String(bytes.length));
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
		
		
		/*
			This is called outside of the class to retrieve the bytes
		*/
		public function readAllBytes(dest:ByteArray):void
		{
			/*
				ByteArray.readByts(*,*, length=0) means all available data to read.
				
				| block1  | block2      | bloo(not all bytes are arrived yet) oo.|
				                        | <- block_cursor
				| copied to dest        | copied to new_bytes                    |
			*/
			var src:ByteArray = bytes;
			var new_bytes:ByteArray = new ByteArray;
			src.position = 0;
			if (src.bytesAvailable < block_cursor) {
				Logger.log("Wrong block_cursor. availableBytes, block_cursor = " 
					+ String(src.bytesAvailable) + ", " + String(block_cursor));
			}
			src.readBytes(dest, 0, block_cursor);
			src.readBytes(new_bytes);
			src.clear();
			bytes = new_bytes;
			block_cursor = 0;
		}
		
		private function processData(_bytes:ByteArray):void
		{
			bytes.position = bytes.length;
			bytes.writeBytes(_bytes);
			var bs:int; // compensation for 1 + 4
			var ok:Boolean = false;
			/*
				Variable ok is to avoid splitting bytes that will be processed readAllBytes
				Variable block_cursor points the head of the most recent block.

			if (bytes.length < 200) {
				bytes.position = 0;
				printBytes(bytes);
			}
			*/
			
			while (true) {
				bytes.position = block_cursor + 1;
				bytes.endian = Endian.LITTLE_ENDIAN;
				if (bytes.bytesAvailable < 4) {
					break;
				}
				
				bs = bytes.readUnsignedInt();
				if (bs > 100000) {
				    trace("block_cursor / bs : " + String(block_cursor) + ", " + String(bs));
				}
				if (bs <= bytes.bytesAvailable) {
					ok = true;
				}
				/*
					The left size of current block is bs
					The entire size of current block is 1 + 4
					|kind|  size  |
					| 1  |   4    |
				*/
				if (block_cursor + bs + 5 < bytes.length) {
					block_cursor += bs + 5; // points next block
				} else {
					break;
				}
			}
			if (ok) {
				dispatchProgressEvent();
			} else {
			}
		}
		
		private function dispatchProgressEvent():void
		{
			dispatchEvent(new Event(ProgressEvent.PROGRESS));
		}
		
		private function onIOError(ioevent:IOErrorEvent):void
		{
			var e:DataProviderError = new DataProviderError(DataProviderError.SERVER_UNREACHABLE,
															"IOErrror");
			dispatchEvent(e);
		}
		
		private function onError(event:Event):void
		{
			trace("onError / HoneypotServer");
			dispatchEvent(new DataProviderError(DataProviderError.SERVER_SOME_ERROR, "some error"));
		}
		
		private function onClose(event:Event):void
		{
			trace("connection closed");
		}
		private function prepareEvents() :void
		{
			_socket.addEventListener(Event.CONNECT, onConnect);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA , onDataArrived);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_socket.addEventListener(Event.CLOSE, onClose);
		}

		public function close() :void {
			if (connected()) {
				trace("closing socket");
				_socket.close();
				outputReceivedData();
			}
		}
		
		private function outputReceivedData() :void
		{
			var fileName:String = "tty_data.out";
			var outFile:File = File.desktopDirectory;
			outFile = outFile.resolvePath(fileName);
			var outStream:FileStream = new FileStream();
			outStream.open(outFile, FileMode.WRITE);
			outStream.writeBytes(receivedBytes, 0, receivedBytes.length);
			outStream.close();
		}

	}
}