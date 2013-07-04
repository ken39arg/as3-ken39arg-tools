package ken39arg.event
{
	import flash.events.Event;

	public class SerialCommandEvent extends Event
	{
		public static const EXECUTE : String = "execute";
		
		public static const CANCEL : String = "cancel";
		
		public static const FINISH : String = "finish";
		
		public var newCommandName : String;
		
		public var oldCommandName : String;
		
		public function SerialCommandEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, newName:String = "", oldName:String = "")
		{
			super(type, bubbles, cancelable);
			
			this.newCommandName = newName;
			this.oldCommandName = oldName;
		}
		
	}
}