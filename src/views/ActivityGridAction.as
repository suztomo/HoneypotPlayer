// ActionScript file
import controllers.HoneypotEventDispatcher;

import flash.events.TimerEvent;
import flash.utils.Timer;


import mx.core.UIComponent;

import com.dncompute.graphics.GraphicsUtil;

import models.events.HoneypotEvent;
import models.events.HoneypotEventMessage;

import views.ActivityGridNode;
import views.TerminalPanelView;

public static var LINE_COLOR:uint = 0xFF3300;
public static var LINE_DELAY:Number = 2000; // milliseconds

private var _hosts:Object; // name => node
private var _nodeArray:Array;

private var _lineScreen:UIComponent;
private var _nodeScreen:UIComponent;
private var _nodeInfoScreen:UIComponent;

private var _nodeInterval:Number = 150;

private var _nextPositionX:Number = _nodeInterval;
private var _nextPositionY:Number = _nodeInterval;

private var _nodeScale:Number = 1.0;

private var _nodeXLimit:Number, _nodeYLimit:Number;

private var _autoAlignTimer:Timer;

/*
	Passing a reference to the component.
	e.g. <view:ActivityGrid terminalPanelCanvas="{terminalPanelCanvas}" /> ...
*/
public var terminalPanelCanvas:TerminalPanelView;


public function onCreationComplete():void
{
	_hosts = new Object();
	_nodeArray = new Array; 
	_lineScreen = new UIComponent;
	_nodeScreen = new UIComponent;
	_nodeInfoScreen = new UIComponent;
	canvas.addChild(_nodeScreen);
	canvas.addChild(_lineScreen);
	canvas.addChild(_nodeInfoScreen);
	_nodeXLimit = width;
	_nodeYLimit = height;
	
	if (terminalPanelCanvas == null) {
		throw new Error("terminalPanelCanvas is not specified");
	}
	_autoAlignTimer = new Timer(2000);
	_autoAlignTimer.addEventListener(TimerEvent.TIMER, function():void{
		alignNodes();
	});
	_autoAlignTimer.start();
	
}

public function setDispatcher(dispatcher:HoneypotEventDispatcher):void
{
	dispatcher.addEventListener(HoneypotEvent.TYPE, onHoneypotEvent);
}

public function onHoneypotEvent(e:HoneypotEvent):void
{
	switch(e.kind) {
		case HoneypotEvent.HOST_CREATED:
			addNode(e.message.hostname);
			break;
		case HoneypotEvent.NODE_INFO:
			var hostname:String = e.message.hostname;
			addNode(hostname, e.message.addr);
		case HoneypotEvent.ROOT_PRIV:
			processRootPrivMessage(e.message);
			break;
		case HoneypotEvent.SYSCALL:
			processSyscallMessage(e.message);
			break;
		case HoneypotEvent.CONNECT:
			var from_host:String = e.message.host1;
			var to_host:String = e.message.host2;
			drawLinesBetweenNodes(from_host, to_host);
		default:
			break;
	}
}


/*
	Aligns nodes
	If the nodeScreen is filled with nodes,
	re-calculates it again after changing the scale and interval.
*/
private function alignNodes():void
{
	_nextPositionX = _nodeInterval;
	_nextPositionY = _nodeInterval;
	var recalc:Boolean = false;
	var n:ActivityGridNode;
	for each (n in _nodeArray) {
		displayNode(n);
		if (n.y + n.height > _nodeYLimit) {
			recalc = true;
			break;
		}
	}
	if (recalc) {
		nodesFilled();
	}
}

private function addNode(nodeName:String, addr:String = "None"):void
{
	var node:ActivityGridNode = _hosts[nodeName];
	if (node) {
		node.addr = addr;
		return;
	}
	node = new ActivityGridNode(nodeName, addr, terminalPanelCanvas,
													 _nodeInfoScreen);
	_hosts[nodeName] = node;
	_nodeArray.push(node);
	displayNode(node);
	if (node.y + node.height> _nodeYLimit)
		nodesFilled();
}

private function displayNode(node:ActivityGridNode):void
{
	node.scaleX = _nodeScale;
	node.scaleY = _nodeScale;
	node.x = _nextPositionX;
	node.y = _nextPositionY;
	_nextPositionX += _nodeInterval;
	if (_nextPositionX + node.width > _nodeXLimit) {
		_nextPositionX = _nodeInterval;
		_nextPositionY += _nodeInterval;
	}
	_nodeScreen.addChild(node);
}

private function nodesFilled():void
{
	_nodeInterval /= 1.414;
	_nodeScale /= 1.414;
	alignNodes();
}

private function getNode(nodeName:String):ActivityGridNode
{
	var node:ActivityGridNode = _hosts[nodeName];
	if (node) {
		return node;
	}
	addNode(nodeName);
	return _hosts[nodeName];
}

private function drawLinesBetweenNodes(fromNodeName:String, toNodeName:String):void
{
	var fromNode:ActivityGridNode = getNode(fromNodeName);
	var toNode:ActivityGridNode = getNode(toNodeName);
	drawLine(fromNode.x, fromNode.y, toNode.x, toNode.y);
}

private function drawLine(fromX:Number, fromY:Number, toX:Number, toY:Number):void
{
	var l:UIComponent = new UIComponent;
	l.graphics.lineStyle(10, LINE_COLOR, 1, false, LineScaleMode.VERTICAL,
						 CapsStyle.NONE, JointStyle.MITER, 10);
	l.graphics.beginFill(LINE_COLOR);
	GraphicsUtil.drawArrow(l.graphics,
		new Point(fromX, fromY),new Point(toX, toY),
		{shaftThickness:2,headWidth:20,headLength:20,
		shaftPosition:.25,edgeControlPosition:.75}
	);
/*
	l.graphics.moveTo(fromX, fromY);
	l.graphics.lineTo(toX, toY);*/
	l.graphics.endFill();
	_lineScreen.addChild(l);
	var t:Timer = new Timer(LINE_DELAY, 1);
	t.addEventListener(TimerEvent.TIMER, function () :void{
		_lineScreen.removeChild(l);
	});
	t.start();
}


public function processRootPrivMessage(message:HoneypotEventMessage):void
{
	
}

public function processSyscallMessage(message:HoneypotEventMessage):void
{
	getNode(message.hostname).highLight()
}