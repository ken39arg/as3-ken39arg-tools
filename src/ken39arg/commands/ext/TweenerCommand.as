package ken39arg.commands.ext
{
	import ken39arg.commands.CommandBase;
	import caurina.transitions.Tweener;

	/**
	 * Command implementation for Tweener addTween.
	 * 
	 * This command internally uses Tweener's onComplete and dispaches Event.COMPLETE after animation.
	 */
	public class TweenerCommand extends CommandBase
	{
		protected var _target : Object
		protected var _paramObj : Object
		
		/**
		 * @param target:Object target for tween, same as Tweener
		 * @param paramObj:Object parameters for tween, same as Tweener
		 */
		public function TweenerCommand(target:Object, paramObj:Object)
		{
			super();
			_target = target;
			_paramObj = paramObj;
			_paramObj.onComplete = _onCompleteCallback;
		}
		
		override public function execute():void
		{
			Tweener.addTween(_target, _paramObj);
		}
		
		protected function _onCompleteCallback():void
		{
			_target = null;
			_paramObj = null;
			
			dispatchComplete();
		}
	}
}