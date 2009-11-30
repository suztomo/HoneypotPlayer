package views
{
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	
	/**
	 *  Host class that represents host in view
	 *  Host has several terminals that represents tty inside it. 
	 *  Host highlights itself if its controller (CanvasManager) orders to do so. 
	 */
	public class Host extends Sprite
	{
		public var term:Terminal;
		public var terms:Object;
		public var hostname:String;
		
		public function Host(name:String)
		{
			hostname = name;
			super();
			terms = new Object();
		}
		
		
		public function writeTTY(ttyname:String, data:ByteArray):void
		{
			var t:Terminal = findTerminal(ttyname);
			term.writeBytes(data);
		}
		
		private function addTerminal(name:String):void
		{
			var t:Terminal = new Terminal(name);
			terms[name] = t;
		}
		
		private function drawCircle():void
		{
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(0xFFCC00);
			circle.graphics.drawCircle(0, 0, 40);
			addChild(circle);
		}
		
		/*
			Finds terminal using its name.
			If the terminal is not exist, this function creates and 
			registers it to terms dictionary.
		*/
		private function findTerminal(name:String):Terminal
		{
			var t:Terminal = terms[name];
			if (t is null) {
				addTerminal(name);
				t = terms[name];
			}
			return t;
		}
		
		public function highlight():void
		{
			
		}
		
		public function cease():void
		{
			
		}
	}
}