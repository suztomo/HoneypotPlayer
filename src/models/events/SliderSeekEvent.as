package models.events
{
	import flash.events.Event;
	import models.utils.Logger;
	
	public class SliderSeekEvent extends Event
	{
		public static const TYPE:String = "SliderSeekEvent";
		public var _value:Number;
		
		public function SliderSeekEvent(value:Number)
		{
			_value = value;
			super(TYPE, false, false);
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		public function set value(value:Number):void
		{
			if (value > 100 || value < 0) {
				Logger.log("Invalid range of value / SliderSeekEvent");
			}
			_value = value;
		}
		
	}
}