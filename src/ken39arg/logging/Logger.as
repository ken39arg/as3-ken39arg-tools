package ken39arg.logging
{
	import ken39arg.logging.ILogging;
	import ken39arg.logging.NullLogging;
	
	/**
	 * ログ出力を一元管理するためのクラスです. 
	 * 
	 * ILoggingをセットして使用します. 
	 * 例えばILoggingでtraceで出力したり、ファイル出力したり、サーバーに送信したりするクラスを作成することで
	 * エラーなどのログをプロジェクトのポリシーや開発時などで変更することが出来ます。
	 * 
	 * @access    public
	 * @package   ken39arg.logging
	 * @author    K.Araga
	 * @varsion   $id : Logger.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class Logger
	{
		
		// ｴﾗｰ出力レベル
		 
		
		/**
		 * エラーレベル：DEBUG. 
		 */
		public static const DEBUG:int   = 0;
		
		/**
		 * エラーレベル：INFO. 
		 */
		public static const INFO:int    = 1;
		/**
		 * エラーレベル：WARNING. 
		 */
		public static const WARNING:int = 2;
		/**
		 * エラーレベル：ERROR. 
		 */
		public static const ERROR:int   = 3;
		/**
		 * エラーレベル：FATAL. 
		 */
		public static const FATAL:int   = 4;
		
		/**
		 *　エラーレベル. 
		 * 
		 * エラーレベルは下記の順に重要度が変わります. 
		 * DEBUG < INFO < WARNING < ERROR < FATAL
		 * 
		 * @default 1 (Logger.INFO)
		 */
		public static var errorLevel : int = INFO;
		
		/**
		 * スタックトレース出力フラグ. 
		 * 
		 * trueにしておくとスタックトレースを出力します. 
		 * スタックトレースの出力はエラーレベルに関係なく出力されます.
		 * @default false
		 */
		public static var useStacTrace : Boolean = false;
		
		/**
		 * ダンプ出力フラグ. 
		 * 
		 * trueにしておくとダンプを出力します. 
		 * ダンプの出力はエラーレベルに関係なく出力されます. 
		 * ダンプの出力はデバッグ時に非常に有効ですが、リリース時には必ずfalseにするよう注意してください。
		 * @default false
		 */
		public static var useVerdump : Boolean = false;
		
		private static var _logging : ILogging = new NullLogging();
		
		/**
		 * ログ出力を行うオブジェクトをセットします. 
		 * 
		 * Loggingオブジェクトを柔軟に変更することでプロジェクトポリシーに従った柔軟なログ出力が可能となります. 
		 * またデフォルトはNullLoggingがセットされておりこのままではエラーレベルに関係なく何もしません 
		 * @param loggingObj
		 * 
		 */
		public static function setLogging(loggingObj:ILogging):void
		{
			_logging = loggingObj;
		}
		
		/**
		 * DEBUGレベルのログ出力を行う
		 * @param m
		 * 
		 */
		public static function debug(m:*):void
		{
			if (errorLevel <= DEBUG)
				put("[DEBUG] "+m, DEBUG);
		}

		/**
		 * INFOレベルのログ出力を行う
		 * @param m
		 * 
		 */
		public static function info(m:*):void
		{
			if (errorLevel <= INFO)
				put("[INFO] "+m, INFO);
		}

		/**
		 * warnレベルのログ出力を行う
		 * @param m
		 * 
		 */
		public static function warn(m:*):void
		{
			if (errorLevel <= WARNING)
				put("[WARNING] "+m, WARNING);
		}

		/**
		 * ERRORレベルのログ出力を行う
		 * @param m
		 * 
		 */
		public static function error(m:*):void
		{
			if (errorLevel <= ERROR)
				put("[ERROR] "+m, ERROR);
		}

		/**
		 * FATALレベルのログ出力を行う
		 * @param m
		 * 
		 */
		public static function fatal(m:*):void
		{
			if (errorLevel <= FATAL)
				put("[FATAL] "+m, FATAL);
		}
		
		/**
		 *　スタックトレースを出力する. 
		 * 
		 * エラーがどこで発生しているのか知りたいときにつかえるつもり
		 * @param m
		 * 
		 */
		public static function stactrace(m:*):void
		{
			if (!useStacTrace) {
				return;
			}
			var e:Error;
			if (m is Error) {
				e = m as Error;
			} else {
				e = new Error(m);
			}
			put("["+m+"]\n"+e.getStackTrace());
			
		}
		
		/**
		 * オブジェクトのダンプを出力します. 
		 * 
		 * @todo Object型以外をダンプしたい
		 * @param value
		 * @param name
		 * @param indent
		 * 
		 */
		public static function putVardump(value:*, name:String = "", indent:String = ""):void
		{
			if (!useVerdump) {
				return;
			}

			if (value == null) {
				value = String("NULL");
			}
			
			
			var type:String = typeof value;
			if (name == "") {
				put(indent + "(" + type + "):" + value.toString());
				
			} else {
				put( indent + "[" + name + "] => " + "(" + type + "):" + value.toString());
			}
			if (type == "object" || type == "xml") {
				indent += "    ";
				for (var key:String in value) {
					putVardump(value[key], key, indent);
				}
			}
		}
		
		public static function put(string:String, level:int=0):void
		{
			_logging.put(string, level);
		}

	}
}