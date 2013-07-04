package ken39arg.commands.ext
{
	import ken39arg.commands.CommandBase;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	/**
	 * 戻り値としてtrueが帰ってくるまで定期的に登録した関数を呼び出す。
	 * trueが帰ってきたらEvent.COMPLETEを発行するコマンド
	 * 
	 * ロックの解除やアニメの終了等を見張る場合に使うとよい。
	 */
	public class CheckCommand extends CommandBase
	{
		protected var _thisObject:*
		protected var _function:Function
		protected var _params:Array
		protected var _duration:Number
		protected var _timer:Timer
		
		
		public function CheckCommand(thisObj:*, func:Function, params:Array=null, checkDuration:Number=100)
		{
			super();
			_thisObject = thisObj;
			_function = func; 
			_params = params;
		}
		
		
		override public function execute():void
		{
			_timer = new Timer(_duration, 0);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler, false, 0, true);
			_timer.start();
		}
		
		
		protected function timerHandler(e:TimerEvent):void
		{
			var rslt:Boolean = false;
			
			if(_params==null){
				rslt = _function.apply(_thisObject);
			}else{
				rslt = _function.apply(_thisObject, _params);
			}
			
			if(rslt==true){
				_timer.removeEventListener(TimerEvent.TIMER, timerHandler);
				_timer.stop();
				dispatchComplete();
			}
		}
	}
}