// ActionScript file
// ActionScript file
import controllers.CanvasPlayer;

import flash.errors.*;
import flash.events.Event;

import models.events.*;

import mx.controls.Alert;

private function init():void
{	
	trace("Ths is init()");
}

public function hello():void
{
	trace("this is hello");
	
}

			
private function receiveFormData(e:DataSelectionEvent):void
{
	setCurrentState("TerminalView");
	switch(e.kind) {
		case DataSelectionEvent.serverSelectedType:
			startCanvasPlayerWithServer(e.serverAddress, e.serverPort);
			break;
		case DataSelectionEvent.fileSelectedType:
			startCanvasPlayerWithFile(e.selectedFilePath);
			break;
	}
}

public function startCanvasPlayerWithServer(serverAddress:String, serverPort:uint):void
{
	player = new CanvasPlayer(terminalViewCanvas);
	player.setServerDispatcher(serverAddress, serverPort);
	player.addEventListener(DataProviderError.TYPE, handleError);
	player.start();
}

public function handleError(event:DataProviderError):void
{
	switch(event.kind) {
		case DataProviderError.SERVER_UNREACHABLE:
			setCurrentState("DataSelection");
			Alert.show("Invalid server information");
			break;
		default:
			break;
	}
	
}

public function startCanvasPlayerWithFile(filePath:String):void
{
	trace("startCanvasPlayerWidthFile");
	player = new CanvasPlayer(terminalViewCanvas);
	player.setFileDispatcher(filePath);
	
	// do nothing
} 


public function exitingHandler(exitingEvent:Event):void {
	if (player) {
		player.shutdown();
	}
}
