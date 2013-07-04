package ken39arg.commands.ext
{
	import ken39arg.commands.CommandBase;

	/**
	 * 任意のタイミングで、対象のプロパティを変更するコマンド
	 * 
	 * 対象の指定方法
	 * target:Object	操作対象のオブジェクトの参照
	 * targetGetter:Function	対象オブジェクトを関数から取得したい場合
	 * targetScope:Object, targetProp:String 対象オブジェクトの指定スコープからハッシュキーで取得したい場合
	 * 
	 * プロパティの指定方法
	 * dataProp:String プロパティの名前
	 * 
	 * データの指定方法
	 * value:Object	値
	 */
	public class SetPropertyCommand extends CommandBase
	{
		protected var paramObj:Object
		
		public function SetPropertyCommand(paramObj:Object)
		{
			this.paramObj = paramObj;
		}
		
		override public function execute():void
		{
			var target:*;
			
			if(paramObj.targetScope && paramObj.targetProp)
				target = paramObj.targetScope[paramObj.targetProp];
			
			if(paramObj.targetGetter)
				target = paramObj.targetGetter();
			
			if(paramObj.target)
				target = paramObj.target;
			
			target[ paramObj.dataProp ] = paramObj.value;
			
			this.dispatchComplete();
		}
	}
}