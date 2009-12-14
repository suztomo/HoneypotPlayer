// ActionScript file
// ActionScript file
import flash.events.Event;
import flash.utils.ByteArray;
import models.utils.Logger;

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
	player = new CanvasPlayer(canvas);
	// player.setServerDispatcher("127.0.0.1", 8080);
	player.setServerDispatcher("192.168.124.188", 8080);
	Logger.log("Hello, World!!!");	
	player.start();

}

public function exitingHandler(exitingEvent:Event):void {
	if (player) {
		player.shutdown();
	}
}
