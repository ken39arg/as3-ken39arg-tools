package ken39arg.logging
{
	public class PararelLogging implements ILogging
	{
		private var _loggers:Array;
		
		public function PararelLogging(loggers:Array)
		{
			_loggers = loggers;
		}

		public function put(string:String, level:int=0):void
		{
			for (var i:int=0; i<_loggers.length; i++) {
				var l:ILogging = _loggers[i] as ILogging;
				if (l) {
					l.put(string, level);
				}
			}
		}
		
	}
}