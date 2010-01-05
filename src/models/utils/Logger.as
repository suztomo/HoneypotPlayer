package models.utils
{
	import flash.filesystem.File;
	
	import mx.controls.TextArea;
	
	public class Logger
	{
		private static var _logger:Logger = new Logger;
		private var _logFile:File = null;
		private static var _textarea:Object = null;
		
		public function Logger()
		{
			// Do nothing.
		}

		static public function get instance():Logger
		{
			return _logger;
		}
		
		public static function setConsole(textarea:Object):void
		{
			_textarea = textarea;
		}
		
		public static function log(msg:String):void
		{
			instance.write(msg);
		}
		
		private function write(msg:String):void
		{
			trace(msg);
			if (_textarea != null) {
				_textarea.write(msg);
			}
		}
	}
}