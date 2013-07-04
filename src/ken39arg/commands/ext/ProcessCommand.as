package ken39arg.commands.ext
{
	import ken39arg.commands.CommandBase;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	/**
	 * 指定の関数が true を返すまで、定期的にコールするコマンド。
	 * スタックの消化や擬似スレッド等を行いたい場合に使う
	 */
	public class ProcessCommand extends CommandBase
	{
		protected var _timer:Timer
		protected var _wait:Number
		protected var _thisObject:Object;
		protected var _function:Function;
		protected var _params:Array
		
		
		public function ProcessCommand(thisObj:Object, func:Function, params:Array=null, wait:Number=100)
		{
			super();
			
			_wait = wait;
			_thisObject = thisObj;
			_function = func;
			_params = params;
		}
		
		override public function execute():void
		{
			_timer = new Timer(_wait,0);
			_timer.addEventListener(TimerEvent.TIMER, _timerHandler);
			_timer.start();
		}
		
		
		protected function _timerHandler(e:Event):void
		{
			_process();
		}
		
		
		protected function _process():void
		{
			_timer.stop();
			
			var rslt:Boolean = false;
			
			if(_params==null){
				rslt = _function.apply(_thisObject);
			}else{
				rslt = _function.apply(_thisObject, _params);
			}
			
			if(rslt==true){
				this.removeEventListener(TimerEvent.TIMER, _timerHandler);
				this.dispatchComplete();
			}else{
				_timer.reset();
				_timer.start();
			}
		}
	}
}