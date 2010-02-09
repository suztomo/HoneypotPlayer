package models.graphs
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;
	import mx.core.UITextField;
	
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.primitives.Cube;
	
	import views.Activity3DChart;

	public class ActivityCube extends Cube
	{
		public var node:Activity3DChartNode;
		public var time:Number;
		private var infoTimer:Timer = new Timer(2000, 0);
		private var infoSquare:UIComponent = new UIComponent;
		public function ActivityCube(node:Activity3DChartNode,
			time:Number, materials:MaterialsList, width:Number=500, depth:Number=500, height:Number=500, segmentsS:int=1,
			    segmentsT:int=1, segmentsH:int=1, insideFaces:int=0, excludeFaces:int=0)
		{
			super(materials, width, depth, height, segmentsS, segmentsT, segmentsH, insideFaces, excludeFaces);
			addEventListener(InteractiveScene3DEvent.OBJECT_CLICK,
            							  onClicked);
            addEventListener(InteractiveScene3DEvent.OBJECT_OVER,
            					  onOvered);
			infoTimer.addEventListener(TimerEvent.TIMER, hideInfo);
			this.node = node;
			this.time = time;
			prepareInfo();
		}
		
		public function onOvered(event:InteractiveScene3DEvent):void
		{
			showInfo();
		}
		
		public function onClicked(event:InteractiveScene3DEvent):void
		{
			node.showPanel(time);
		}
		
		public function prepareInfo():void
		{
			var u:UIComponent = infoSquare;
			u.graphics.beginFill(0xFFFFCC, 0.9);
			u.graphics.drawRect(0, 0, 140, 45);
			u.graphics.endFill();
			var t:UITextField = new UITextField;
			t.width = 150;
			t.text = node.hostName + "\n time:" + int(time / 1000);
			t.setStyle("fontSize", 16);
			t.setStyle("textColor", 0x111111); 
			u.addChild(t);
		}
		
		public function showInfo():void
		{
			Activity3DChart.infoLayer.addChild(infoSquare);
			infoSquare.x = Activity3DChart.infoLayer.mouseX;
			infoSquare.y = Activity3DChart.infoLayer.mouseY;
			infoTimer.reset();
			infoTimer.start();
		}
		
		public function hideInfo(event:TimerEvent):void
		{
			if (Activity3DChart.infoLayer == infoSquare.parent)
				Activity3DChart.infoLayer.removeChild(infoSquare);
		}
		
	}
}