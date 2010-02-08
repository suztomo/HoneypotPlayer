package models.graphs
{
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.primitives.Cube;

	public class ActivityCube extends Cube
	{
		public var hostName:String;
		public var node:Activity3DChartNode;
		public function ActivityCube(materials:MaterialsList, width:Number=500, depth:Number=500, height:Number=500, segmentsS:int=1, segmentsT:int=1, segmentsH:int=1, insideFaces:int=0, excludeFaces:int=0)
		{
			super(materials, width, depth, height, segmentsS, segmentsT, segmentsH, insideFaces, excludeFaces);
		}
	}
}