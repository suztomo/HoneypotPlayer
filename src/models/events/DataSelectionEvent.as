package models.events
{
	import flash.events.Event;

	public class DataSelectionEvent extends Event
	{
		static public const TYPE:String = "DataSelected";
		static public const serverSelectedType:String = "serverSelected";
		static public const fileSelectedType:String = "fileSelected";
		
		public var kind:String;
		
		public var selectedFilePath:String;
		public var serverAddress:String;
		public var serverPort:uint; 
		
		public function DataSelectionEvent(filePath:String = "",
			 serverAddress:String = "", serverPort:uint = 0)
		{
			selectedFilePath = filePath;
			this.serverAddress = serverAddress;
			this.serverPort = serverPort;
			if (this.serverPort != 0) {
				kind = serverSelectedType;
			} else if (this.selectedFilePath != "") {
				kind = fileSelectedType;
			} else {
				trace("Invalid DataSelectionEvent dispatch");
			}
			super(TYPE);
		}
	}
}