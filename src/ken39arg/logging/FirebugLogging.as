package ken39arg.logging
{
	import flash.external.ExternalInterface;
	
	public class FirebugLogging implements ILogging
	{
		public function put(string:String, level:int=0):void
		{
			ExternalInterface.call('console.log', string);
		}
		
	}
}