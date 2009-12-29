package controllers
{
	/*
		This class is responsible gather messages that is related to
		activitychart, and calculates the number of activity
		between a certain period.
	*/ 
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import models.events.HoneypotEventMessage;
	import models.utils.Logger;
	
	import views.ActivityLineChart;
	
	public class ActivityChartManager
	{
		private var _period:Number;
		private var _lastDispatch:Number;
		private var _activityLineChart:ActivityLineChart;
		private var _currentRecord:Object;
		private var _timer:Timer;
		private var _seriesNames:Object;
		private var _totalTime:Number;
		
		public function ActivityChartManager(activityLineChart:ActivityLineChart, period:Number)
		{
			_period = period;
			_lastDispatch = 0;
			_currentRecord = createRecord(_lastDispatch);
			_activityLineChart = activityLineChart;
			_timer = new Timer(1000); // milliseconds
			_timer.addEventListener(TimerEvent.TIMER, onPeriod);
			//_timer.start(); // for realtime
			_seriesNames = new Object();
		}
		
		public function set totalTime(value:Number):void
		{
			_totalTime = value;
		}
				
		public function seekByTime(time:Number):void
		{
			_activityLineChart.seekByTime(time);
			_lastDispatch = Math.floor(time / _period) * _period;
		}
				
		private function onPeriod(e:TimerEvent):void
		{
			flush();
		}

		public function put(message:HoneypotEventMessage):void
		{
			var host:String = message.hostname;
			var syscall:String = message.syscall; // unused for activity
			var time:Number = message.time;
			if (_seriesNames[host] == null)
				addSeries(host, host);
			if (_currentRecord[host] == null)
				_currentRecord[host] = 0;
			_currentRecord[host] += 1;
		}
		
		public function addSeries(yField:String, displayName:String):void
		{
			_activityLineChart.addSeries(yField, displayName);
			_seriesNames[yField] = true;
		}
		
		public function flush():void
		{
			// in order that a record have all series (hostname) entry to draw a chart
			for (var h:String in _seriesNames) {
				if (_currentRecord[h] == null) {
					_currentRecord[h] = 0;
				}
			}
			
			sendRecord(_currentRecord);
			_currentRecord = createRecord(_lastDispatch);
			_lastDispatch += _period;
		}
		
		private function sendRecord(record:Object):void
		{
			_activityLineChart.addRecord(record);
		}
		
		/*
			Prepare for replaying
		*/
		public function prepareMessages(messages:Array):void
		{
			var t:Number = 0;
			var i:uint = 0;
			var msg:HoneypotEventMessage;
			var records:Array = new Array();
			var r:Object = createRecord(t);
			while((msg = messages[i]) != null) {
				if (msg.time < t + _period) {
					// add 1 to the host in current record
					var host:String = msg.hostname;
					var time:Number = msg.time;
					if (r[host] == null) {
						r[host] = 0;
					}
					r[host] += 1;
					if (_seriesNames[host] == null) {
						addSeries(host, host);
					}
					++i;				
				} else {
					// reflesh the record.
					for (var h:String in _seriesNames) {
						if (r[h] == null) {
							r[h] = 0;
						}
					}

					records.push(r);
					r = createRecord(t);
					t += _period;
				}
			}
			if (records.length == 0) {
				Logger.log("There is no activity messages.");
			} else {
				_activityLineChart.prepareRecords(records);
				Logger.log("Stored " + records.length + " records");
			}
		}
		
		private static function createRecord(time:Number):Object
		{
			const o:Object = new Object;
			o[ActivityLineChart.XAXIS] = time;
			return o;
		}

	}
}