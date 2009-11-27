package controllers
{
	import mx.core.UIComponent;
	
	public class CanvasManager
	{
		private const screen:UIComponent;
		
		/*
			Class for reach a canvas to draw on.
			Mainly used for view classes.
		*/
		public function CanvasManager(s:UIComponent)
		{
			screen = s;
		}
		
		static public function screen() :UIComponent
		{
			return screen;
		} 
	}
}