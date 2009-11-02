// ActionScript file
// ActionScript file
import flash.utils.ByteArray;

import mx.controls.Button;
import mx.core.UIComponent;

import net.suztomo.honeypotplayer.*;

import org.partty.*;

private var hpmaster:HoneypotPlayerMaster;
private var ttyserver:TTYServer;

private function init():void
{	
	trace("Ths is init()");
}

public function hello():void
{
	trace("this is hello");
}

public function start():void
{
	trace("This is start()");
	/*
		Good example of creating simple server is to use
		netcat (nc) command, such as:
		  [Mac]$ nc -l localhost 8080
		  [Ubuntu]$ nc -l -p 8080
	*/
//	ttyserver = new TTYServer("127.0.0.1", 8081);
//	ttyserver.connect();
	hpmaster = new HoneypotPlayerMaster();
	addChild(hpmaster);
	
	var uic:UIComponent = new UIComponent();
	canvas.addChild(uic);
	var btn:Button = new Button();
	btn.label = "Hello, Button";
//	canvas.addChild(btn);
	
/*
	var terminal:Terminal = new Terminal();
	uic.addChild(terminal);
	terminal.writeByte(0x41);
	terminal.writeByte(0x41);
	terminal.writeByte(0x41);
	terminal.writeByte(0x41);
	terminal.refresh();
	terminal.scaleY = 0.1;
	terminal.scaleX = 0.1;
*/		
}