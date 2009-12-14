package tests
{
	import flexunit.framework.TestCase;
	import flexunit.framework.TestSuite;
	
	public class SampleTests extends TestCase
	{
		public function SampleTests(methodName:String=null)
		{
			super(methodName);
		}
		
		public static function suite():TestSuite
		{
			var theSuite:TestSuite = new TestSuite();
			theSuite.addTestSuite(SampleTests);
			return theSuite;
		}
		
		public function testAdditionDiffExponents():void
		{
			assertEquals("x^0",7.0,7.1);
			assertEquals("x^1",3.0,3.0 );
			assertEquals("x^2",9.0,9.0 );			
		}
		
		
	}
}