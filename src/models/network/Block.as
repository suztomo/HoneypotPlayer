package models.network
{
	import flash.utils.ByteArray;
	
	public class Block
	{
		/*
			|  4   |  4   |  ... 
			| kind | size |  data...
			The size can be acquired by bytes.length;
		*/
		public var kind:uint;
		public var bytes:ByteArray;
		
		/*
			This class represents Block of honeypot virtual hosts.
		*/
		public function Block(k:uint, b:ByteArray)
		{
			kind = k;
			bytes = b;
		}
	}
}