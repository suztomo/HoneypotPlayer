package models.events
{
	import flash.events.Event;
	
	public class DataProviderError extends Event
	{
		public static const TYPE:String = "DATA_PROVIDER_ERRROR";
		private var _message:String;
		
		private var _kind:String;
		public static const SERVER_UNREACHABLE:String = "Server unreachable"; 
		public static const SERVER_SOME_ERROR:String = "Some Error";
		/*
			Class that passes when any error on server occurs
			the error is notified to view classes.
		*/
		public function DataProviderError(kind:String, message:String)
		{
			_message = message;
			_kind = kind;
			super(TYPE);
		}
		
		public function get message():String
		{
			return _message;
		}
		
		public function get kind():String
		{
			return _kind;
		}
	}
}