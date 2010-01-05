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
	player.addActivityChartManager(_activityChartManager);
	player.start();	
}


/*
	Menu
*/
[Bindable]
public var menuBarCollection:XMLListCollection;

private var menubarXML:XMLList =
    <>
        <menuitem label="Menu1" data="top">
            <menuitem label="MenuItem 1-A" data="1A"/>
            <menuitem label="MenuItem 1-B" data="1B"/>
        </menuitem>
        <menuitem label="Menu2" data="top">
            <menuitem label="MenuItem 2-A" type="check"  data="2A"/>
            <menuitem type="separator"/>
            <menuitem label="MenuItem 2-B" >
                <menuitem label="SubMenuItem 3-A" type="radio"
                    groupName="one" data="3A"/>
                <menuitem label="SubMenuItem 3-B" type="radio"
                    groupName="one" data="3B"/>
            </menuitem>
        </menuitem>
    </>;

// Event handler to initialize the MenuBar control.
private function initCollections():void {
    menuBarCollection = new XMLListCollection(menubarXML);
}

// Event handler for the MenuBar control's itemClick event.
private function menuHandler(event:MenuEvent):void  {
    // Don't open the Alert for a menu bar item that 
    // opens a popup submenu.
    if (event.item.@data != "top") {
        Alert.show("Label: " + event.item.@label + "\n" + 
            "Data: " + event.item.@data, "Clicked menu item");
    }        
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
	_activityChartManager = new ActivityChartManager(activityLineChart, 1000);
	player.addActivityChartManager(_activityChartManager);
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


