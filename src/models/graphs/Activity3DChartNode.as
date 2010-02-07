package models.graphs
{
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cube;
	
	public class Activity3DChartNode
	{
		public var hostName:String;
		public var activity:Number;
		function Activity3DChartNode(hostName:String, activity:Number) {
			this.hostName = hostName;
			this.activity = activity;
		}
	}
}
