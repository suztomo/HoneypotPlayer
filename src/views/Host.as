package views
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	/**
	 *  Host class that represents host in view
	 *  Host has several terminals that represents tty inside it. 
	 *  Host highlights itself if its controller (CanvasManager) orders to do so. 
	 */
	public class Host extends UIComponent
	{
		public var term:Terminal;
		public var terms:Object;
		public var hostname:String;
		
		public function Host(name:String)
		{
			hostname = name;
			super();
			terms = new Object();
			drawCircle();
			drawName();
		}
		
		
		public function writeTTY(ttyname:String, data:ByteArray):void
		{
			var t:Terminal = findTerminal(ttyname);
			t.writeBytes(data);
		}
		
		private function addTerminal(name:String):void
		{
			var t:Terminal = new Terminal(name);
			terms[name] = t;
			addChild(t);
			t.x = 20;
			t.y = 20;
			t.scaleX = 0.50;
			t.scaleY = 0.50;
		}
		
		private function drawCircle():void
		{
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(0xFFCC00);
			circle.graphics.drawCircle(0, 0, 40);
			addChild(circle);
		}
		
		private function drawName():void
		{
			var t:TextField = new TextField();
			t.text = hostname;	
			// set the contents before textformat
			var format:TextFormat = new TextFormat("Arial", 20, 0x0000000);
			t.setTextFormat(format);

			addChild(t);
		}
		
		/*
			Finds terminal using its name.
			If the terminal is not exist, this function creates and 
			registers it to terms dictionary.
		*/
		private function findTerminal(name:String):Terminal
		{
			var t:Terminal = terms[name];
			if (t == null) {
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