package net.suztomo.honeypotplayer
{
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	public class TTYServer
	{
		private var _serverName:String = "localhost";
		private var _serverPort:int = 8081;
		private var _isConnected:Boolean = false;
		private var _honeypotPlayer:HoneypotPlayerMaster;
		private var _socket:Socket;
		
		public function TTYServer(serverName:String, serverPort:int = 8081)
		{
			_serverName = serverName;
			_serverPort = serverPort;
			_socket = new Socket(_serverName, _serverPort);
			prepareEvents();
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
			_socket.writeUTF("Hello");
			_socket.flush();
		}
		
		private function onDataArrived(event:ProgressEvent):void
		{
			trace("onDataArraived");
			var bytes:ByteArray = new ByteArray();
			_socket.readBytes(bytes);
			processData(bytes);
		}
		
		private function processData(bytes:ByteArray):void
		{
			trace(bytes);
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