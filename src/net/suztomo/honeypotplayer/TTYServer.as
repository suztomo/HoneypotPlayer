package net.suztomo.honeypotplayer
{
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	
	public class TTYServer extends EventDispatcher
	{
		private var _serverName:String = "127.0.0.1";
		private var _serverPort:int = 8081;
		private var _isConnected:Boolean = false;
		private var _honeypotPlayer:HoneypotPlayerMaster;
		private var _socket:Socket;
		private var bytes:ByteArray;
		
		public function TTYServer(serverName:String, serverPort:int = 8081)
		{
			_serverName = serverName;
			_serverPort = serverPort;
			_socket = new Socket();
			prepareEvents();
			bytes = new ByteArray();
		}
		public function connect():void
		{
			if (connected()) {
				trace("Already connected");
			}
			_socket.connect(_serverName, _serverPort);
		}

		public function connected():Boolean
		{
			return _socket && _socket.connected;
		}
		
		private function onConnect(event:Event):void
		{
			trace("onConnect");
		}
		
		private function onDataArrived(event:ProgressEvent):void
		{
			var bytes:ByteArray = new ByteArray();
			_socket.readBytes(bytes);
			processData(bytes);
		}

		private function printBytes(bytes:ByteArray):void
		{
			var s:String = "";
			for (var i:int=0; i<bytes.length; ++i) {
				var b:uint = bytes.readUnsignedByte();
				if (b <= 0xF)
					s += "0";
				s += b.toString(16) + "|";
			}
			trace(s);			
		}
		
		public function readAllBytes(dest:ByteArray):void
		{
			/*
				ByteArray.readByts(*,*, length=0) means all available data to read.
			*/
			var src:ByteArray = bytes;
			src.position = 0;
			src.readBytes(dest);
			trace(dest.endian);
			src.clear();
		}
		
		private function processData(_bytes:ByteArray):void
		{
			bytes.writeBytes(_bytes);
			trace("bytes of TTYServer length is " + String(bytes.length));
			dispatchEvent(new Event(ProgressEvent.PROGRESS));
		}
		
		private function onIOError(ioevent:IOErrorEvent):void
		{
			trace(ioevent.text);
		}
		
		private function onError(event:Event):void
		{
			trace(event.type);
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

	}
}