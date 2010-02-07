package models.events
{
	import flash.events.Event;

	public class HoneypotEvent extends Event
	{
		static public const TYPE:String = "HonepotEvent";


		/*
			For TerminalView
		*/
		/**
		 * Event type for when a new host is created. 
		 */
		static public const HOST_CREATED: String = "created";
		
		/**
		 * Event type for when a host is ceased.
		 */
		 static public const HOST_DESTROYED: String = "destroyed"; 

		/**
		 * Event type for when terminal input is written 
		 */
		static public const HOST_TERM_INPUT: String = "terminalInput";
		
		/**
		 * Event type for when terminal resized 
		 */
		static public const HOST_TERM_RESIZE:String = "terminalResize";
		
		/**
		 * Event type for when the host is invaded.
		*/
		static public const HOST_INVADED: String = "invaded";


		/**
		 * Event type for flush all buffer in all hosts, after seek
		 */
		static public const FLUSH_ALL_BUFFERS: String = "flushAllBuffers"; 


		/*
			For ActivityGrid
		*/
		/**
		 * Event type for when a system call is called
		 **/
		static public const SYSCALL: String = "systemcall";
		
		/**
		 * Event type for when root priviledge is used
		 **/
		static public const ROOT_PRIV:String = "root";
			
		/**
		 * Event type for creation of node information
		 */
		static public const NODE_INFO:String = "node";

		/**
		 * Event type for when a connection is made
		 **/
		static public const CONNECT:String = "connect"


		private var _message:HoneypotEventMessage;

		private var _kind:String;

		public function HoneypotEvent(kind:String, honeypotEventMessage:HoneypotEventMessage)
		{
			super(TYPE);
			_message = honeypotEventMessage;
			_kind = kind; 
		}
		
		public function set kind(value:String):void
		{
			_kind = value;
		}
		
		public function set message(value:HoneypotEventMessage):void
		{
			_message = value;
		}
		
		public function get kind():String
		{
			return _kind;
		}
		
		public function get message():HoneypotEventMessage
		{
			return _message;
		}
	}
}