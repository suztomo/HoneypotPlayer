// ActionScript file
// ActionScript file
import controllers.CanvasPlayer;

import flash.errors.*;
import flash.events.Event;

import models.events.*;
import models.utils.Logger;

import mx.controls.Alert;

			
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
	player = new CanvasPlayer(terminalView.canvas);
	player.setServerDispatcher(serverAddress, serverPort);
	player.addEventListener(DataProviderError.TYPE, handleError);
	player.start();
}

/*
	Realtime
*/
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

/*
	Replay
*/
public function startCanvasPlayerWithFile(filePath:String):void
{
	player = new CanvasPlayer(terminalView.canvas);
	player.setFileDispatcher(filePath, terminalView.autoProcess);
	player.addEventListener(DataProviderError.TYPE, handleError);
	terminalView.addEventListener(SliderSeekEvent.TYPE, sliderSeekHandler);
	player.start();
}

public function startSlider(updateTimerSpan:Number, percentagePerSpan:Number):void
{
	terminalView.autoProcess(updateTimerSpan, percentagePerSpan);
}

public function sliderSeekHandler(seekEvent:SliderSeekEvent):void
{
	player.seekByPercentage(seekEvent.value);
}


public function exitingHandler(exitingEvent:Event):void {
	if (player) {
		player.shutdown();
	}
}
