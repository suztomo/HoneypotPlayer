package models.graphs
{
	public class NodeActivity
	{
		public var connect:Number = 0;
		public var syscall:Number = 0;
		public var name:String;
		function NodeActivity(name:String)
		{
			this.name = name;
		}
	}
}
