package ken39arg.logging
{
	public class TraceLogging implements ILogging
	{
		public function put(string:String, level:int=0):void
		{
			trace(string);
		}
		
	}
}