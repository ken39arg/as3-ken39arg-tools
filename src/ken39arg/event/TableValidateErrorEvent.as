package ken39arg.event
{
	import flash.events.Event;

	/**
	 * TABLEオブジェクトのバリデート時にエラーを返すイベント.  
	 * 
	 * ハンドルされていないError対策でErrorEventを継承していません
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : TableValidateErrorEvent.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class TableValidateErrorEvent extends Event
	{
		public static const VALIDATE_ERROR:String = "validateError"
		
		public var errors:Array;
		
		public function TableValidateErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, errors:Array = null)
		{
			//TODO: implement function
			super(type, bubbles, cancelable);
			this.errors = errors;
		}
		
	}
}