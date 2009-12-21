package controllers
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.*;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import models.events.*;
	import models.utils.Logger;
	
	
	public class ReplayProcessor extends HoneypotEventDispatcher
	{
		private var _file:File; /* The file that contains previous information of the history. */
		private var _currentSec:uint;
		private var _currentUsec:uint;
		private var _timer:Timer;
		private var _messages:Array;
		private var _msgCursor:uint = 0;
		private static var dispatchInterval:Number = 100; // milliseconds
		private var _seeker:Seeker;
		public var sliderStartCallback:Function;

		public function ReplayProcessor(filePath:String)
		{
			_messages = new Array();
			loadFile(filePath);
			_seeker = new Seeker(_messages);
			
			// make difference when it start()
			kind = super.REPLAY;
		}
		
		private function loadFile(filePath:String):void
		{
			// Any exception handler?
			var f:File = new File(filePath);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			while(fs.bytesAvailable) {
				var o:HoneypotEventMessage = fs.readObject() as HoneypotEventMessage;
				_messages.push(o);
				o.afterDeserialized();
			}
			fs.close();
		}
		
		public override function run():void
		{
			startSlider();
			processBlock();
		}
		
		public override function seekByPercentage(percentage:Number):void
		{
			_timer.stop();
			var i:uint = _seeker.seek(percentage);
			_msgCursor = i;
			dispatchFlushAllBuffers(); // clear before start replaying
			processBlock();
		}
		
		/*
			To clean buffers after seeking
		*/
		private function dispatchFlushAllBuffers():void
		{
			var e:HoneypotEvent = new HoneypotEvent(HoneypotEvent.FLUSH_ALL_BUFFERS, null);
			dispatchEvent(e);
		}
		
		public override function shutdown():void
		{
			// do nothing
		}
		
		private function processBlock():void
		{
			var s:uint = 0;
			var u:uint = 0;
			var gap:Number = 0;
			var msgs:Array = new Array();
			if (_msgCursor >= _messages.length) return;
			var baseTime:Number = (_messages[_msgCursor] as HoneypotEventMessage).time;
			
			// Gather some events on a time in order to avoid splitting too small pieces
			while(true) {
				var msg:HoneypotEventMessage = _messages[_msgCursor++] as HoneypotEventMessage;
				msgs.push(msg);
				if (_msgCursor >= _messages.length) {
					break;
				} else {
					// Look at next message
					gap = (_messages[_msgCursor] as HoneypotEventMessage).time - baseTime;
					if (gap > dispatchInterval) {
						break;
					}
				}
			}

			dispatchMessages(msgs);
			
			// wait the gap
			_timer = new Timer(gap, 1);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
			_timer.start();
		}
		
		private function dispatchMessages(messages:Array):void
		{
			for each(var msg:HoneypotEventMessage in messages) {
				dispatchHoneypotEvent(msg);
			}
		}
		
		private function dispatchHoneypotEvent(message:HoneypotEventMessage):void
		{
			message.percentage = _seeker.percentageByTime(message.time);
			var ev:HoneypotEvent = new HoneypotEvent(message.kind, message);
			dispatchEvent(ev);
		}
		
		private function timerHandler(event:Event):void
		{
			processBlock();
		}
		
		public function startFrom():void
		{
			
		}
		
		private function printBytes(bytes:ByteArray):void
		{
			var s:String = "";
			trace("Position / Length = " + String(bytes.position) + " / " + String(bytes.length) );
			var position:uint = bytes.position;
			for (var i:int=bytes.position; i<bytes.length; ++i) {
				var b:uint = bytes.readUnsignedByte();
				if (b <= 0xF)
					s += "0";
				s += b.toString(16) + "|";
			}
			bytes.position = position;
			trace(s);			
		}
		
		public function startSlider():void
		{
			if (_seeker == null || sliderStartCallback == null) {
				Logger.log("Invalid procedure / ReplayProcessor.startSlider");
				return;
			}
			var total:Number = _seeker.total; // milliseconds
			var updateTimerSpan:Number = 500;
			var percentagePerSpan:Number = updateTimerSpan / total * 100;
			// the callback is TerminalView.autoProcess 
			sliderStartCallback(updateTimerSpan, percentagePerSpan);   
		}

	}
}

import models.events.HoneypotEventMessage;
import models.utils.Logger;
/*
	Seeks index: percentage -> appropriate index
*/
class Seeker
{
	private var _messages:Array;
	private var _total:Number;
	public const finishGap:Number = 1000;
	public function Seeker(messages:Array)
	{
		_messages = messages;
		var msg:HoneypotEventMessage = messages[messages.length - 1] as HoneypotEventMessage;
		_total = msg.time + finishGap;
	}
	
	/*
		Seeks the index by its percentage,
		the messages[index] will be the first element that overs or equals the percentage.
	*/
	public function seek(percent:Number):uint
	{
		var t:Number = _total * percent / 100;
		var i:uint;
		for (i = 0; (_messages[i] as HoneypotEventMessage).time < t; ++i) {
		}
		return i; 
	}
	
	public function get total():Number
	{
		return _total;
	}
	
	public function percentageByTime(time:Number):Number
	{
		var ret:Number = time / _total * 100;
		if (ret < 0 || ret > 100) {
			Logger.log("out of bounds / Seeker.percentageByTime");
			return 100;
		}
		return ret;
	}
}
