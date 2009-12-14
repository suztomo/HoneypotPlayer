package models.utils
{
	import flash.filesystem.File;
	
	public class Logger
	{
		private static var _logger:Logger = new Logger;
		private var _logFile:File = null;
		
		public function Logger()
		{
			// Do nothing.
		}

		static public function get instance():Logger
		{
			return _logger;
		}
		
		public static function log(msg:String):void
		{
			instance.write(msg);
		}
		
		private function write(msg:String):void
		{
			trace(msg);
		}
	}
}