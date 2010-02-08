package models.graphs
{
	import models.events.HoneypotEvent;
	import models.events.HoneypotEventMessage;
	import models.utils.Logger;


	/*
		Time -> Array(Activity3DChartNode);
	*/
	public class ActivityTimeDict
	{


		private var dict:Object;
		function ActivityTimeDict() {
			dict = new Object();
		}
		
		public function putMessages(time:Number, messages:Array):void
		{
			var msg:HoneypotEventMessage;
			var i:int = 0;
			var nodeDict:Object = new Object;
			var hostName:String;
			var a:NodeActivity;
			var n:Activity3DChartNode;
			var activity:Number;
			while((msg = messages[i]) != null) {
				hostName = msg.hostname ? msg.hostname : msg.host1;
				a = nodeDict[hostName];
				if (a == null) {
					a = new NodeActivity(hostName);
					nodeDict[hostName] = a;
				}
				switch(msg.kind) {
					case HoneypotEvent.HOST_CREATED:
						break;
					case HoneypotEvent.HOST_DESTROYED:
						break;
					case HoneypotEvent.HOST_INVADED:
						break;
					case HoneypotEvent.HOST_TERM_INPUT:
						break;
					case HoneypotEvent.FLUSH_ALL_BUFFERS:
						break;
					case HoneypotEvent.SYSCALL:
						a.syscall++;
						break;
					case HoneypotEvent.NODE_INFO:
						break;
					case HoneypotEvent.CONNECT:
						a.connect++;
						break;
					default:
						break;
				}
				++i;
			}
			for (hostName in nodeDict) {
				a = nodeDict[hostName];
				activity = a.connect + a.syscall;
				if (activity < 1) continue;
				n = new Activity3DChartNode(hostName, activity);
				putMessageByTime(time, n);
			}
		}
		
		private function putMessageByTime(time:Number, node:Activity3DChartNode):void
		{
			var e:Array = dict[time];
			if (e == null) {
				e = new Array;
				dict[time] = e;
			}
			e.push(node);
		} 
		
		public function getMessagesByTime(time:Number):Array
		{
			var e:Array = dict[time];
			if (e == null) {
			}
			return e;
		}
		
		public function keys():Array
		{
			var a:Array = new Array;
			var k:String;
			for (k in dict) {
				a.push(k);
			}
			return a;
		}
	}
}

