package ken39arg.core
{
	import flash.utils.getDefinitionByName;
	
	/**
	 * String文字列のクラス名をクラスとしてロードします 
	 * @author araga
	 * 
	 */
	public class ClassLoader {

		/**
		 * クラスを取得する
		 * @param className
		 * @return Class
		 * 
		 */
		public static function getClass(className:String):Class {
			return getDefinitionByName(className) as Class;    
		}
	}
}