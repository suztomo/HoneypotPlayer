// ActionScript file
import controllers.HoneypotEventDispatcher;

import models.events.HoneypotEvent;
import models.events.HoneypotEventMessage;
import models.utils.Logger;

/*

Usage (e.g. in HoneypotViewerAction.as):
  d = new SomeDispatcher();
  activitygrid.setDispatcher(d);
  setCurrentState("ActivityGrid");
  d.run();

*/
public function onCreationComplete():void
{
	trace("ActivityGridAction created, but not visible.");
}

public function setDispatcher(dispatcher:HoneypotEventDispatcher):void
{
	dispatcher.addEventListener(HoneypotEvent.TYPE, onHoneypotEvent);
}

public function onHoneypotEvent(e:HoneypotEvent):void
{
	switch(e.kind) {
		case HoneypotEvent.ROOT_PRIV:
			processRootPrivMessage(e.message);
			break;
		case HoneypotEvent.SYSCALL:
			processSyscallMessage(e.message);
			break;
		default:
			Logger.log("Invalid event arrived " + e.toString() + this.className);
			break;
	}
}


public function processRootPrivMessage(message:HoneypotEventMessage):void
{
	
}

public function processSyscallMessage(message:HoneypotEventMessage):void
{
	
}