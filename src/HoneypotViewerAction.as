// ActionScript file
// ActionScript file
import controllers.ActivityChartManager;
import controllers.CanvasPlayer;

import flash.errors.*;
import flash.events.Event;

import models.events.*;

import mx.collections.*;
import mx.controls.Alert;
import mx.events.MenuEvent;

private var _activityChartManager:ActivityChartManager;
			
private function receiveFormData(e:DataSelectionEvent):void
{
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
	setCurrentState("Realtime");
	player = new CanvasPlayer(terminalView);
	player.setServerDispatcher(serverAddress, serverPort);
	player.addEventListener(DataProviderError.TYPE, handleError);
	_activityChartManager = new ActivityChartManager(activityLineChart, 1000);
	activityGrid.setDispatcher(player.dispatcher);
	player.addActivityChartManager(_activityChartManager);
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
	setCurrentState("Replay");
	player = new CanvasPlayer(terminalView);
	player.setFileDispatcher(filePath, terminalView.autoProcess);
	slider.total = player.total;
	player.addEventListener(DataProviderError.TYPE, handleError);
	//terminalView.addEventListener(SliderSeekEvent.TYPE, sliderSeekHandler);
	_activityChartManager = new ActivityChartManager(activityLineChart, 100);
	player.addActivityChartManager(_activityChartManager);
	activityGrid.setDispatcher(player.dispatcher);
	player.start();
	slider.addEventListener("sliderStop", player.stopReplayTimer);
	slider.addEventListener("sliderStart", player.startReplayTimer);
}

public function sliderSeekHandler(seekEvent:SliderSeekEvent):void
{
	player.seekByPercentage(seekEvent.value);
}

/*
	Used in HoneypotViewer.mxml
*/
public function onSliderChange(event:Event):void
{
	const value:Number = event.currentTarget.value;
	player.seekByPercentage(value);
}

public function onSliderProgress(event:Event):void
{
	activityLineChart.seekByTime(event.currentTarget.time);
}

public function exitingHandler(exitingEvent:Event):void {
	if (player) {
		player.shutdown();
	}
}


