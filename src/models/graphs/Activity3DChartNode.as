package models.graphs
{
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class Activity3DChartNode
	{
		public var hostName:String;
		public var activity:Number;
		public var view:DisplayObject3D;
		
		private static var highlightMaterial:MaterialObject3D;
		
		private static var changedNodes:Array = new Array;
		private var defaultMaterial:MaterialObject3D;
		
		function Activity3DChartNode(hostName:String, activity:Number) {
			this.hostName = hostName;
			this.activity = activity;
		}
		
		
		public static function setHighlightMaterial(color:uint = 0xFFFFFF):void
		{
			var colorMaterial:ColorMaterial = new ColorMaterial(color, 1);
			/*
			var wireMaterial:WireframeMaterial = new WireframeMaterial(0x000000);
			var compoMaterial:CompositeMaterial = new CompositeMaterial();
			compoMaterial.addMaterial(wireMaterial);
			compoMaterial.addMaterial(colorMaterial);
			compoMaterial.doubleSided = true;

            
			highlightMaterial = new MaterialsList();
			highlightMaterial.addMaterial(colorMaterial, "all");
			*/
			highlightMaterial = new ColorMaterial(color);
		}
		
		public function resetMaterial():void
		{
			view.material = defaultMaterial;	
		}
		
		public function highlightView():void
		{
			defaultMaterial = view.material;
			if (highlightMaterial)
				view.material = highlightMaterial;
			changedNodes.push(this);
		}
		
		public static function resetChangedNodes():void
		{
			var node:Activity3DChartNode;
			for each(node in changedNodes) {
				node.resetMaterial();
			}
			changedNodes.length = 0;
		}
	}
}
