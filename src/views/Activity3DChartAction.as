// ActionScript file
import models.events.HoneypotEventMessage;
import models.graphs.*;

import org.papervision3d.cameras.*;
import org.papervision3d.materials.*;
import org.papervision3d.objects.*;
import org.papervision3d.objects.primitives.*;
import org.papervision3d.scenes.*;

/*
	Array(HoneypotMessage) =>
	  Object( time => Array( Activity3DChartNode ) )
*/

private var packPeriod:Number; // milliseconds 

private function processHoneypotMessages(messages:Array, period:int = 10000):ActivityTimeDict
{
	var dict:ActivityTimeDict = new ActivityTimeDict();
	var msg:HoneypotEventMessage;
	var i:int;
	packPeriod = period;
	if (messages.length < 1) {
		Logger.log("No messages " + "processHoneypotMessages / Activity3DChartAction");
		return null;
	}
	var lastPackedTime:Number = 0;
	var packingMessages:Array = new Array;
	while((msg = messages[i]) != null) {
		if (msg.time > lastPackedTime + packPeriod) {
			dict.putMessages(lastPackedTime, packingMessages);
			packingMessages = new Array;
			lastPackedTime = lastPackedTime + packPeriod;
		}
		packingMessages.push(msg);
		++i;
	}
	return dict; 
}
