package ken39arg.logging
{
	/**
	 * ログの出力方法を定義するインターフェイス. 
	 * 
	 * Loggerクラスでの出力方法を定義します
	 * 
	 * @access    public
	 * @package   ken39arg.logging
	 * @author    K.Araga
	 * @varsion   $id : ILogging.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public interface ILogging
	{
		/**
		 * 出力 
		 * @param string
		 * @param int
		 */
		function put(string:String, level:int=0):void
	}
}