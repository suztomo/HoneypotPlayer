// ActionScript file
// ActionScript file
import flash.events.Event;

import mx.controls.Button;
import mx.core.UIComponent;


private function init():void
{	
	trace("Ths is init()");
}

public function hello():void
{
	trace("this is hello");
	
}

public function startCanvasPlayer():void
{
	trace("This is start()");

	player = new CanvasPlayer(canvas);
	player.setServerDispatcher("127.0.0.1", 8080);
	player.start();

}

public function exitingHandler(exitingEvent:Event):void {
	trace("Ending");
	if (player) {
		player.shutdown();
	}
}
