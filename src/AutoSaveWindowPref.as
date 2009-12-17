import flash.filesystem.*;
public var prefsFile:File; // The preferences prefsFile

/*
	Window position saving.
		http://www.adobe.com/jp/devnet/air/flex/quickstart/xml_prefs.html
*/
public function initializeStagePosition():void
{ 
	stage.nativeWindow.addEventListener(Event.CLOSING, windowClosingHandler); 
	prefsFile = File.applicationStorageDirectory;
	prefsFile = prefsFile.resolvePath("preferences.xml"); 
	readXML();
}

private function readXML():void 
{
	var stream:FileStream = new FileStream();
	if (prefsFile.exists) {
		stream.open(prefsFile, FileMode.READ);
	    setWindowPositionByFile(stream);
	} else {
	    saveWindowPosition();
	}
}

/**
* Called after the data from the prefs file has been read. The readUTFBytes() reads
* the data as UTF-8 text, and the XML() function converts the text to XML. The x, y,
* width, and height properties of the main window are then updated based on the XML data.
*/
private function setWindowPositionByFile(stream:FileStream):void 
{
	var prefsXML:XML = XML(stream.readUTFBytes(stream.bytesAvailable));
	stream.close();
	stage.nativeWindow.x = prefsXML.windowState.@x;
	stage.nativeWindow.y = prefsXML.windowState.@y;
	stage.nativeWindow.width = prefsXML.windowState.@width;
	stage.nativeWindow.height = prefsXML.windowState.@height;
}

/**
* Called when the window is closing (and the closing event is dispatched.
*/
private function windowClosingHandler(event:Event):void {
	saveWindowPosition();
}

/**
* Called when the user clicks the Save button or when the window
* is closing.
*/
private function saveWindowPosition():void
{
	writeXMLData(createXMLData());
}

private function createXMLData():XML 
{
	var prefsXML:XML;
	prefsXML = <preferences/>;
	prefsXML.windowState.@width = stage.nativeWindow.width;
	prefsXML.windowState.@height = stage.nativeWindow.height;
	prefsXML.windowState.@x = stage.nativeWindow.x;
	prefsXML.windowState.@y = stage.nativeWindow.y;
	prefsXML.saveDate = new Date().toString();
	return prefsXML;
}

private function writeXMLData(prefsXML:XML):void 
{
	var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
	outputString += prefsXML.toXMLString();
	outputString = outputString.replace(/\n/g, File.lineEnding);
	var stream:FileStream = new FileStream();
	stream.open(prefsFile, FileMode.WRITE);
	stream.writeUTFBytes(outputString);
	stream.close();
}